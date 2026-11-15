function wc = wheelCentres(vehicle)
%WHEELCENTRES Wheel centre coordinates in the global frame.
%   WC = WHEELCENTRES(VEHICLE) returns a N-by-3 matrix, where N is the
%   total number of wheels. Each row is [x y z], the position of the wheel
%   centre in the global reference frame. Rows are ordered by axle (front
%   to rear) and, within each axle, by wheel (left to right). The z
%   coordinate is computed as loaded_radius - cg_height; if either quantity
%   is unknown (NaN), the corresponding z is NaN.
%
%   VEHICLE must be a validated struct (see vehkit.validate).

arguments
    vehicle struct
end

hCG = vehicle.geometry.cg_height;
total = 0;
for k = 1:numel(vehicle.axles)
    total = total + numel(vehicle.axles{k}.wheels);
end
wc = zeros(total, 3);
row = 1;
for k = 1:numel(vehicle.axles)
    axle = vehicle.axles{k};
    for j = 1:numel(axle.wheels)
        wheel = axle.wheels{j};
        wc(row, 1) = axle.x;
        wc(row, 2) = wheel.y;
        wc(row, 3) = wheel.loaded_radius - hCG;
        row = row + 1;
    end
end
end