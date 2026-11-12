function vehicle = load(filename)
%LOAD Load a vehicle definition from a JSON file.
%   VEHICLE = LOAD(FILENAME) reads the JSON file at FILENAME and returns a
%   MATLAB struct representing the vehicle data. JSON null values are
%   converted to MATLAB NaN according to the vehkit schema. Syntax or
%   structural errors in the JSON text produce
%   vehkit:invalidJSONStructure.
%
%   See also vehkit.save, vehkit.validate.

arguments
    filename {mustBeTextScalar}
end

filename = string(filename);

text = fileread(filename);

try
    vehicle = jsondecode(text);
catch cause
    baseException = MException( ...
        "vehkit:invalidJSONStructure", ...
        "Invalid JSON in file %s: %s", filename, cause.message);
    baseException = addCause(baseException, cause);
    throw(baseException);
end

vehicle = vehkit.internal.replaceEmptyWithNaN(vehicle);
end