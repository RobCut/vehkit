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
vehicle = vehkit.validate(vehicle);
text = jsonencode(vehicle, 'PrettyPrint', true);
if ~endsWith(text, newline)
    text = [text newline];
end
fid = fopen(filename, 'w', 'n', 'UTF-8');
if fid == -1
    throw(MException('vehkit:save:writeFailed', ...
        'Cannot open file for writing: %s', filename));
end
fwrite(fid, text, 'char');
fclose(fid);
end