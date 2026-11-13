function validate(vehicle)
%VALIDATE Check that a vehicle struct complies with the vehkit schema.
%   VALIDATE(VEHICLE) verifies that VEHICLE satisfies the structural and
%   physical constraints of the vehkit schema. It returns nothing on
%   success, and throws a vehkit:* exception on failure.
%
%   The validation rules are applied in the order defined in
%   docs/SCHEMA.md, Section 3.5.
%
%   See also vehkit.load, vehkit.save.

arguments
    vehicle struct
end

validateSchemaVersion(vehicle);
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

function throwInvalidJSON(msg)
%throwInvalidJSON Throw a vehkit:invalidJSONStructure exception.
throw(MException('vehkit:invalidJSONStructure', '%s', msg));
end

function throwUnsupportedSchemaVersion(sv)
%throwUnsupportedSchemaVersion Throw a vehkit:unsupportedSchemaVersion
%   exception
throw(MException('vehkit:unsupportedSchemaVersion', ...
    'Unsupported schema version: %s', sv));
end