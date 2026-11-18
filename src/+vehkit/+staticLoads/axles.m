function F = axles(vehicle)
%AXLES Static vertical loads on each axle.
%   F = AXLES(VEHICLE) returns a 2-by-1 column vector with the static
%   vertical loads on each axle, in newton, ordered from front to rear.
%   The calculation assumes static equilibrium on a flat horizontal
%   road, with the vehicle centre of gravity at the global origin of
%   the reference frame.
%
%   The function is restricted to two-axle vehicles, because the
%   distribution of vertical loads across more than two axles requires
%   additional physical information (suspension stiffness, anti-roll
%   bars) that is outside the scope of v0.1.
%
%   VEHICLE must be a validated struct (see vehkit.validate).

arguments
    vehicle struct
end

if numel(vehicle.axles) ~= 2
    throw(MException('vehkit:unsupportedAxleCount', ...
        'static axle load calculation requires exactly 2 axles, found %d', ...
        numel(vehicle.axles)));
end

g = 9.80665;
mass = vehicle.load_configurations.reference.mass;
xFront = vehicle.axles{1}.x;
xRear = vehicle.axles{2}.x;
L = xFront - xRear;

W = mass * g;
FFront = W * (-xRear) / L;
FRear = W * xFront / L;

F = [FFront; FRear];
end