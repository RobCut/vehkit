function wb = wheelbase(vehicle)
%WHEELBASE Longitudinal distance between the first and last axles.
%   WB = WHEELBASE(VEHICLE) returns the distance between the first and last
%   axle, computed as x_first - x_last. For a single-axle vehicle the
%   wheelbase is zero.
%
%   VEHICLE must be a validated struct (see vehkit.validate).

arguments
    vehicle struct
end

wb = vehicle.axles{1}.x - vehicle.axles{end}.x;
end