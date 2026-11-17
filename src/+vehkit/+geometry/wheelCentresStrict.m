function wc = wheelCentresStrict(vehicle)
%WHEELCENTRESSTRICT Wheel centre coordinates, raising on unknown fields.
%   WC = WHEELCENTRESSTRICT(VEHICLE) returns the same N-by-3 matrix as
%   WHEELCENTRES, but raises vehkit:missingData if geometry.cg_height or
%   any wheel loaded_radius is explicitly unknown. This is useful for
%   callers that require a complete z coordinate and prefer a fail-fast
%   behavior over NaN propagation.
%
%   VEHICLE must be a validated struct (see vehkit.validate).

arguments
    vehicle struct
end

if isnan(vehicle.geometry.cg_height)
    throw(MException('vehkit:missingData', ...
        'geometry.cg_height is explicitly unknown'));
end

for k = 1:numel(vehicle.axles)
    for j = 1:numel(vehicle.axles{k}.wheels)
        if isnan(vehicle.axles{k}.wheels{j}.loaded_radius)
            throw(MException('vehkit:missingData', ...
                sprintf('axles{%d}.wheels{%d}.loaded_radius is explicitly unknown', k, j)));
        end
    end
end

wc = vehkit.geometry.wheelCentres(vehicle);
end