function save(vehicle, filename)
%SAVE Write a vehicle definition to a JSON file.
%   SAVE(VEHICLE, FILENAME) validates VEHICLE and writes it to FILENAME in
%   JSON format, using UTF-8 without BOM and pretty-printing. The vehicle
%   is validated before any file is written, so an invalid vehicle produces
%   an error and no file on disk.
%
%   See also vehkit.load, vehkit.validate.

arguments
    vehicle struct
    filename {mustBeTextScalar}
end

filename = string(filename);
vehicle = stripDerivedAxlePositions(vehicle);
vehicle = vehkit.validate(vehicle);
vehicle = stripDerivedAxlePositions(vehicle);
text = jsonencode(vehicle, 'PrettyPrint', true);
if ~endsWith(text, newline)
    text = [text newline];
end
fid = fopen(filename, 'w', 'n', 'UTF-8');
if fid == -1
    throw(MException('vehkit:save:writeFailed', ...
        'Cannot open file for writing: %s', filename));
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fwrite(fid, text, 'char');
end

function vehicle = stripDerivedAxlePositions(vehicle)
%stripDerivedAxlePositions Remove axles[].x for static_load_based geometry.
%   Called before validation (to accept an already-validated struct whose
%   x has been reconstructed in memory) and after validation (to avoid
%   writing derived positions into the JSON).
if ~isfield(vehicle.geometry, 'method')
    return;
end
if string(vehicle.geometry.method) ~= "static_load_based"
    return;
end
for k = 1:numel(vehicle.axles)
    if isfield(vehicle.axles{k}, 'x')
        vehicle.axles{k} = rmfield(vehicle.axles{k}, 'x');
    end
end
end