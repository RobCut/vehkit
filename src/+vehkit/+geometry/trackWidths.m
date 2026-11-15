function tw = trackWidths(vehicle)
%TRACKWIDTHS Track width of each axle.
%   TW = TRACKWIDTHS(VEHICLE) returns a column vector with the track width
%   of each axle, computed as max(y) - min(y) among the wheels of the axle.
%   For a single-wheel axle the track width is zero.
%
%   VEHICLE must be a validated struct (see vehkit.validate).

arguments
    vehicle struct
end

n = numel(vehicle.axles);
tw = zeros(n, 1);
for k = 1:n
    ys = cellfun(@(w) w.y, vehicle.axles{k}.wheels);
    tw(k) = max(ys) - min(ys);
end
end