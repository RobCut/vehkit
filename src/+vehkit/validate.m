function vehicle = validate(vehicle)
%VALIDATE Check that a vehicle struct complies with the vehkit schema.
%   VALIDATE(VEHICLE) verifies that VEHICLE satisfies the structural and
%   physical constraints of the vehkit schema, normalizes its collections
%   to canonical form, and returns the normalized vehicle. It throws a
%   vehkit:* exception on failure.
%
%   The validation rules are applied in the order defined in
%   docs/SCHEMA.md, Section 3.5.
%
%   See also vehkit.load, vehkit.save.

arguments
    vehicle struct
end

validateSchemaVersion(vehicle);
validateRootFields(vehicle);
vehicle = normalizeCollections(vehicle);
validateNullability(vehicle);
validatePositiveScalars(vehicle);
validateGeometry(vehicle);
validateOrdering(vehicle);
end

function validateSchemaVersion(vehicle)
%validateSchemaVersion Validate the schema_version field.
if ~isfield(vehicle, 'schema_version')
    throwInvalidJSON('Missing required field: schema_version');
end
sv = vehicle.schema_version;
if ~(ischar(sv) || isstring(sv))
    throwInvalidJSON('schema_version must be a string');
end
sv = string(sv);
if ~isscalar(sv)
    throwInvalidJSON('schema_version must be a scalar string');
end
pattern = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$';
if isempty(regexp(sv, pattern, 'once'))
    throwInvalidJSON(sprintf('schema_version has invalid format: %s', sv));
end
if sv ~= "0.1"
    throwUnsupportedSchemaVersion(sv);
end
end

function validateRootFields(vehicle)
%validateRootFields Validate presence and type of required root fields.
if ~isfield(vehicle, 'geometry')
    throwInvalidJSON('Missing required field: geometry');
end
if ~isstruct(vehicle.geometry)
    throwInvalidJSON('geometry must be a struct');
end
if ~isfield(vehicle, 'axles')
    throwInvalidJSON('Missing required field: axles');
end
if ~isfield(vehicle, 'load_configurations')
    throwInvalidJSON('Missing required field: load_configurations');
end
if ~isstruct(vehicle.load_configurations)
    throwInvalidJSON('load_configurations must be a struct');
end
end

function vehicle = normalizeCollections(vehicle)
%normalizeCollections Normalize vehicle collections to canonical form.
%   After this function, vehicle.axles is a column cell array of scalar
%   structs, and each axle.wheels is a column cell array of scalar structs.
vehicle.axles = normalizeCollection(vehicle.axles);
if isempty(vehicle.axles)
    throwInvalidJSON('axles must contain at least one axle');
end
for k = 1:numel(vehicle.axles)
    axle = vehicle.axles{k};
    if ~isstruct(axle) || ~isscalar(axle)
        throwInvalidJSON('Each axle must be a scalar struct');
    end
    if ~isfield(axle, 'wheels')
        throwInvalidJSON('Missing required field: wheels');
    end
    axle.wheels = normalizeCollection(axle.wheels);
    if isempty(axle.wheels)
        throwInvalidJSON('Each axle must contain at least one wheel');
    end
    for j = 1:numel(axle.wheels)
        wheel = axle.wheels{j};
        if ~isstruct(wheel) || ~isscalar(wheel)
            throwInvalidJSON('Each wheel must be a scalar struct');
        end
    end
    vehicle.axles{k} = axle;
end
end

function c = normalizeCollection(x)
%normalizeCollection Convert a collection to a column cell array.
if iscell(x)
    c = x(:);
elseif isstruct(x)
    if isscalar(x)
        c = {x};
    else
        c = num2cell(x);
        c = c(:);
    end
else
    throwInvalidJSON('Collection must be a cell array or a struct');
end
end

function validateNullability(vehicle)
%validateNullability Verify that NaN appears only in nullable fields.
if isnan(vehicle.load_configurations.reference.mass)
    throwInvalidParameter('mass must not be NaN');
end
for k = 1:numel(vehicle.axles)
    axle = vehicle.axles{k};
    if isnan(axle.x)
        throwInvalidParameter(sprintf('axles{%d}.x must not be NaN', k));
    end
    for j = 1:numel(axle.wheels)
        wheel = axle.wheels{j};
        if isnan(wheel.y)
            throwInvalidParameter(sprintf( ...
                'axles{%d}.wheels{%d}.y must not be NaN', k, j));
        end
    end
end
end

function validatePositiveScalars(vehicle)
%validatePositiveScalars Verify that strictly positive scalars are
%   positive.
if vehicle.load_configurations.reference.mass <= 0
    throwInvalidParameter('mass must be positive');
end
for k = 1:numel(vehicle.axles)
    axle = vehicle.axles{k};
    for j = 1:numel(axle.wheels)
        lr = axle.wheels{j}.loaded_radius;
        if ~isnan(lr) && lr <= 0
            throwInvalidParameter(sprintf( ...
                'axles{%d}.wheels{%d}.loaded_radius must be positive', k, j));
        end
    end
end
end

function validateGeometry(vehicle)
%validateGeometry Validate geometry.method and method-exclusive fields.
if ~isfield(vehicle.geometry, 'method')
    throwInvalidJSON('Missing required field: geometry.method');
end
method = vehicle.geometry.method;
if ~(ischar(method) || isstring(method))
    throwInvalidJSON('geometry.method must be a string');
end
method = string(method);
if method ~= "direct"
    throwInvalidParameter(sprintf( ...
        'geometry.method "%s" is not supported in alpha', method));
end
if isfield(vehicle.geometry, 'wheelbase')
    throwConflictingGeometry( ...
        'geometry.wheelbase is not allowed with method "direct"');
end
if isfield(vehicle.geometry, 'front_weight_distribution')
    throwConflictingGeometry( ...
        'geometry.front_weight_distribution is not allowed with method "direct"');
end
end

function validateOrdering(vehicle)
%validateOrdering Validate axle and wheel ordering.
for k = 2:numel(vehicle.axles)
    if vehicle.axles{k-1}.x <= vehicle.axles{k}.x
        throwAxleOrderMismatch(sprintf( ...
            'axles must be ordered from front to rear: axles{%d}.x (%g) <= axles{%d}.x (%g)', ...
            k-1, vehicle.axles{k-1}.x, k, vehicle.axles{k}.x));
    end
end
for k = 1:numel(vehicle.axles)
    wheels = vehicle.axles{k}.wheels;
    for j = 2:numel(wheels)
        if wheels{j-1}.y < wheels{j}.y
            throwWheelOrderMismatch(sprintf( ...
                'wheels in axles{%d} must be ordered left to right: wheels{%d}.y (%g) < wheels{%d}.y (%g)', ...
                k, j-1, wheels{j-1}.y, j, wheels{j}.y));
        elseif wheels{j-1}.y == wheels{j}.y
            if compareCanonicalIds(wheels{j-1}.id, wheels{j}.id) > 0
                throwWheelOrderMismatch(sprintf( ...
                    'wheels in axles{%d} with identical y must be in canonical id order: %s before %s', ...
                    k, wheels{j}.id, wheels{j-1}.id));
            end
        end
    end
end
end

function cmp = compareCanonicalIds(a, b)
%compareCanonicalIds Compare two identifiers by canonical ordering.
%   Returns -1 if A precedes B, 0 if equal, 1 if A follows B.
%   Canonical ordering compares the prefix before the last underscore using
%   ordinal ASCII, and the numeric suffix as an integer.
[pa, na] = splitCanonicalId(a);
[pb, nb] = splitCanonicalId(b);
if pa < pb
    cmp = -1;
elseif pa > pb
    cmp = 1;
elseif na < nb
    cmp = -1;
elseif na > nb
    cmp = 1;
else
    cmp = 0;
end
end

function [prefix, num] = splitCanonicalId(s)
%splitCanonicalId Split an identifier into textual prefix and numeric
%   suffix.
s = string(s);
parts = split(s, '_');
num = str2double(parts(end));
prefix = strjoin(parts(1:end-1), '_');
end

function throwInvalidJSON(msg)
%throwInvalidJSON Throw a vehkit:invalidJSONStructure exception.
throw(MException('vehkit:invalidJSONStructure', '%s', msg));
end

function throwUnsupportedSchemaVersion(sv)
%throwUnsupportedSchemaVersion Throw a vehkit:unsupportedSchemaVersion
%   exception.
throw(MException('vehkit:unsupportedSchemaVersion', ...
    'Unsupported schema version: %s', sv));
end

function throwInvalidParameter(msg)
%throwInvalidParameter Throw a vehkit:invalidParameter exception.
throw(MException('vehkit:invalidParameter', '%s', msg));
end

function throwConflictingGeometry(msg)
%throwConflictingGeometry Throw a vehkit:conflictingGeometryDefinition
%   exception.
throw(MException('vehkit:conflictingGeometryDefinition', '%s', msg));
end

function throwAxleOrderMismatch(msg)
%throwAxleOrderMismatch Throw a vehkit:axleOrderMismatch exception.
throw(MException('vehkit:axleOrderMismatch', '%s', msg));
end

function throwWheelOrderMismatch(msg)
%throwWheelOrderMismatch Throw a vehkit:wheelOrderMismatch exception.
throw(MException('vehkit:wheelOrderMismatch', '%s', msg));
end