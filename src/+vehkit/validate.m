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
vehicle = validateGeometry(vehicle);
validateNullability(vehicle);
validatePositiveScalars(vehicle);
validateIdentifiers(vehicle);
validateOrdering(vehicle);
validateInertia(vehicle);
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

function vehicle = validateGeometry(vehicle)
%validateGeometry Validate geometry method and reconstruct axle positions.
%   For direct geometry, axle positions are assigned in the JSON.
%   For static_load_based geometry, axle positions are reconstructed in
%   memory from wheelbase and front_weight_distribution, and are never
%   serialized.
if ~isfield(vehicle.geometry, 'method')
    throwInvalidJSON('Missing required field: geometry.method');
end
if ~(ischar(vehicle.geometry.method) || isstring(vehicle.geometry.method))
    throwInvalidJSON('geometry.method must be a string');
end
method = string(vehicle.geometry.method);
switch method
    case "direct"
        if isfield(vehicle.geometry, 'wheelbase')
            throwConflictingGeometry( ...
                'geometry.wheelbase is not allowed with method "direct"');
        end
        if isfield(vehicle.geometry, 'front_weight_distribution')
            throwConflictingGeometry( ...
                'geometry.front_weight_distribution is not allowed with method "direct"');
        end
    case "static_load_based"
        if numel(vehicle.axles) ~= 2
            throwUnsupportedAxleCount(sprintf( ...
                'static_load_based geometry requires exactly 2 axles, found %d', ...
                numel(vehicle.axles)));
        end
        if ~isfield(vehicle.geometry, 'wheelbase')
            throwInvalidJSON('Missing required field: geometry.wheelbase');
        end
        if ~isfield(vehicle.geometry, 'front_weight_distribution')
            throwInvalidJSON('Missing required field: geometry.front_weight_distribution');
        end
        for k = 1:numel(vehicle.axles)
            if isfield(vehicle.axles{k}, 'x')
                throwConflictingGeometry( ...
                    'axles[].x is not allowed with method "static_load_based"');
            end
        end
        L = vehicle.geometry.wheelbase;
        lambda = vehicle.geometry.front_weight_distribution;
        if ~isnumeric(L) || ~isscalar(L) || L <= 0
            throwInvalidParameter('geometry.wheelbase must be a positive scalar');
        end
        if ~isnumeric(lambda) || ~isscalar(lambda) || lambda <= 0 || lambda >= 1
            throwInvalidParameter( ...
                'geometry.front_weight_distribution must be strictly between 0 and 1');
        end
        vehicle.axles{1}.x = (1 - lambda) * L;
        vehicle.axles{2}.x = -lambda * L;
    otherwise
        throwInvalidParameter(sprintf( ...
            'geometry.method "%s" is not supported', method));
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

function validateIdentifiers(vehicle)
%validateIdentifiers Validate identifiers format and global uniqueness.
pattern = '^[a-z]+(?:_[a-z]+)*_[1-9][0-9]*$';
axleIds = strings(0,1);
wheelIds = strings(0,1);
for k = 1:numel(vehicle.axles)
    axle = vehicle.axles{k};
    if ~isfield(axle, 'id')
        throwInvalidJSON(sprintf('Missing required field: axles{%d}.id', k));
    end
    if ~(ischar(axle.id) || isstring(axle.id))
        throwInvalidJSON(sprintf('axles{%d}.id must be a string', k));
    end
    id = string(axle.id);
    if isempty(regexp(id, pattern, 'once'))
        throwInvalidParameter(sprintf( ...
            'axles{%d}.id has invalid format: %s', k, id));
    end
    if ismember(id, axleIds)
        throwInvalidParameter(sprintf( ...
            'Duplicate axle id: %s', id));
    end
    axleIds(end+1) = id;
    for j = 1:numel(axle.wheels)
        wheel = axle.wheels{j};
        if ~isfield(wheel, 'id')
            throwInvalidJSON(sprintf( ...
                'Missing required field: axles{%d}.wheels{%d}.id', k, j));
        end
        if ~(ischar(wheel.id) || isstring(wheel.id))
            throwInvalidJSON(sprintf( ...
                'axles{%d}.wheels{%d}.id must be a string', k, j));
        end
        wid = string(wheel.id);
        if isempty(regexp(wid, pattern, 'once'))
            throwInvalidParameter(sprintf( ...
                'axles{%d}.wheels{%d}.id has invalid format: %s', k, j, wid));
        end
        if ismember(wid, wheelIds)
            throwInvalidParameter(sprintf( ...
                'Duplicate wheel id: %s', wid));
        end
        wheelIds(end+1) = wid;
    end
end
end

function validateInertia(vehicle)
%validateInertia Validate the inertia tensor.
if ~isfield(vehicle.load_configurations.reference, 'inertia')
    throwInvalidJSON('Missing required field: load_configurations.reference.inertia');
end
inertia = vehicle.load_configurations.reference.inertia;
if ~isstruct(inertia) || ~isscalar(inertia)
    throwInvalidJSON('load_configurations.reference.inertia must be a struct');
end
ixx = getInertiaComponent(inertia, 'ixx');
iyy = getInertiaComponent(inertia, 'iyy');
izz = getInertiaComponent(inertia, 'izz');
ixy = getInertiaComponent(inertia, 'ixy');
ixz = getInertiaComponent(inertia, 'ixz');
iyz = getInertiaComponent(inertia, 'iyz');
for pair = {'ixx', ixx; 'iyy', iyy; 'izz', izz}'
    name = pair{1};
    val = pair{2};
    if ~isnan(val) && val < 0
        throwInvalidInertia(sprintf('%s must be non-negative', name));
    end
end
if ~isnan(ixx) && ~isnan(iyy) && ~isnan(izz)
    atol = 1e-10;
    rtol = 1e-8;
    tol_triangle = atol + rtol * norm(diag([ixx iyy izz]), 2);
    if (ixx + iyy - izz) < -tol_triangle
        throwInvalidInertia('triangle inequality violated: ixx + iyy < izz');
    end
    if (ixx + izz - iyy) < -tol_triangle
        throwInvalidInertia('triangle inequality violated: ixx + izz < iyy');
    end
    if (iyy + izz - ixx) < -tol_triangle
        throwInvalidInertia('triangle inequality violated: iyy + izz < ixx');
    end
end
if ~isnan(ixx) && ~isnan(iyy) && ~isnan(izz) && ...
        ~isnan(ixy) && ~isnan(ixz) && ~isnan(iyz)
    I = [ixx ixy ixz;
        ixy iyy iyz;
        ixz iyz izz];
    atol = 1e-10;
    rtol = 1e-8;
    tol_PSD = atol + rtol * norm(I,2);
    lambda = eig(I);
    if min(lambda) < -tol_PSD
        throwInvalidInertia('inertia tensor is not positive semidefinite');
    end
end
end

function val = getInertiaComponent(inertia, name)
%getInertiaComponent Return the named component, or NaN if absent.
if isfield(inertia, name)
    val = inertia.(name);
else
    val = NaN;
end
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

function throwInvalidInertia(msg)
%throwInvalidInertia Throw a vehkit:invalidInertia exception.
throw(MException('vehkit:invalidInertia', '%s', msg));
end

function throwUnsupportedAxleCount(msg)
%throwUnsupportedAxleCount Throw a vehkit:unsupportedAxleCount exception.
throw(MException('vehkit:unsupportedAxleCount', '%s', msg));
end