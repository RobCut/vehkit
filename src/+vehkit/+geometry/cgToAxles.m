function ca = cgToAxles(vehicle)
%CGTOAXLES Signed longitudinal distance from CG to each axle.
%   CA = CGTOAXLES(VEHICLE) returns a column vector with the signed
%   longitudinal position of each axle in the global frame. Positive values
%   indicate axles ahead of the CG; negative values indicate axles behind
%   it. The CG is at the origin by convention.
%
%   VEHICLE must be a validated struct (see vehkit.validate).

arguments
    vehicle struct
end

n = numel(vehicle.axles);
ca = zeros(n, 1);
for k = 1:n
    ca(k) = vehicle.axles{k}.x;
end
end