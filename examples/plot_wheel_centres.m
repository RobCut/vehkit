%PLOT_WHEEL_CENTRES Plot wheel centre positions from a canonical vehicle.
%   Loads data/road_car.json, validates it, computes wheel centres, and
%   produces a top-down view saved to results/vehicle_plan.png. The figure
%   uses equal axis scaling, a body outline (indicative, not from the
%   schema) and a rotated view with the nose pointing up and positive y
%   towards the left of the vehicle.

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
repoRoot = fileparts(here);
vehicle = vehkit.validate( ...
    vehkit.load(fullfile(repoRoot, 'data', 'road_car.json')));
wc = vehkit.geometry.wheelCentres(vehicle);
wb = vehkit.geometry.wheelbase(vehicle);
tw = vehkit.geometry.trackWidths(vehicle);

fig = figure('Color', 'w', 'Position', [100 100 600 700]);
hold on;
grid on;

% Vehicle body (indicative outline, not part of the schema)
bodyY_min = min(wc(:,2)) - 0.15;
bodyY_max = max(wc(:,2)) + 0.15;
bodyX_min = vehicle.axles{end}.x - 0.85;
bodyX_max = vehicle.axles{1}.x + 0.60;
patch([bodyY_min bodyY_max bodyY_max bodyY_min], ...
    [bodyX_min bodyX_min bodyX_max bodyX_max], ...
    [0.5 0.7 1.0], 'FaceAlpha', 0.15, ...
    'EdgeColor', [0.3 0.3 0.3], 'LineStyle', '--', 'LineWidth', 1.0);

% Wheels (plot y on horizontal, x on vertical: forward points up)
plot(wc(:,2), wc(:,1), 'o', 'MarkerSize', 16, ...
    'MarkerFaceColor', [0.2 0.5 0.8], 'MarkerEdgeColor', 'k');

% Axle lines
plot([bodyY_min bodyY_max], [vehicle.axles{1}.x vehicle.axles{1}.x], ...
    'k--', 'LineWidth', 0.8);
plot([bodyY_min bodyY_max], [vehicle.axles{end}.x vehicle.axles{end}.x], ...
    'k--', 'LineWidth', 0.8);

% CG marker
plot(0, 0, 'x', 'MarkerSize', 14, 'LineWidth', 2, 'Color', 'r');

% Labels: offset towards the vehicle center (y -> 0)
for i = 1:size(wc, 1)
    dxLabel = -sign(wc(i,2)) * 0.22;
    text(wc(i,2)+dxLabel, wc(i,1)+0.12, ...
        vehicle.axles{ceil(i/2)}.wheels{mod(i-1,2)+1}.id, 'FontSize', 9, ...
        'HorizontalAlignment', 'center');
end
text(0.05, 0.15, 'CG', 'Color', 'r', 'FontSize', 10, 'FontWeight', 'bold');

axis equal;
set(gca, 'XDir', 'reverse');  % +y (left of vehicle) appears on the left of the screen
xlim([bodyY_min-0.1, bodyY_max+0.1]);
ylim([bodyX_min-0.3, bodyX_max+0.3]);
xlabel('y [m]');
ylabel('x [m]');
title({'Road car — wheel centres', ...
    sprintf('wheelbase %.2f m, front track %.2f m, rear track %.2f m', wb, tw(1), tw(2))});

outDir = fullfile(repoRoot, 'results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
exportgraphics(fig, fullfile(outDir, 'vehicle_plan.png'), 'Resolution', 150);
close(fig);
fprintf('Saved %s\n', fullfile(outDir, 'vehicle_plan.png'));