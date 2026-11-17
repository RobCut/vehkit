classdef TestStaticLoads < matlab.unittest.TestCase
    %TestStaticLoads Tests for vehkit.staticLoads.axles.
    %   Covers the static axle load calculation for two-axle vehicles,
    %   the mass conservation check, and the axle count restriction.

    properties
        RoadCar
        RaceCar
        StaticLoadVehicle
        ThreeAxleVehicle
    end

    methods (TestClassSetup)
        function setup(testCase)
            %setup Load and validate the canonical fixtures.
            here = fileparts(mfilename('fullpath'));
            repoRoot = fileparts(here);
            dataFolder = fullfile(repoRoot, 'data');

            testCase.RoadCar = vehkit.validate( ...
                vehkit.load(fullfile(dataFolder, 'road_car.json')));
            testCase.RaceCar = vehkit.validate( ...
                vehkit.load(fullfile(dataFolder, 'race_car.json')));

            staticFixture = fullfile(here, 'fixtures', 'minimal_static_load.json');
            testCase.StaticLoadVehicle = vehkit.validate(vehkit.load(staticFixture));

            validFixture = fullfile(here, 'fixtures', 'minimal_valid.json');
            v = vehkit.validate(vehkit.load(validFixture));
            v.axles{end+1} = v.axles{end};
            v.axles{end}.id = 'axle_3';
            v.axles{end}.x = -2.0;
            testCase.ThreeAxleVehicle = v;
        end
    end

    methods (Test)
        function test_static_loads_road_car(testCase)
            %test_static_loads_road_car Verify the static axle loads of
            %   the road car.
            F = vehkit.staticLoads.axles(testCase.RoadCar);
            g = 9.80665;
            testCase.verifyEqual(F(1), 1385 * g * 1.59 / 2.65, 'RelTol', 1e-10);
            testCase.verifyEqual(F(2), 1385 * g * 1.06 / 2.65, 'RelTol', 1e-10);
        end

        function test_static_loads_race_car(testCase)
            %test_static_loads_race_car Verify the static axle loads of
            %   the race car.
            F = vehkit.staticLoads.axles(testCase.RaceCar);
            g = 9.80665;
            testCase.verifyEqual(F(1), 280 * g * 0.70 / 1.55, 'RelTol', 1e-10);
            testCase.verifyEqual(F(2), 280 * g * 0.85 / 1.55, 'RelTol', 1e-10);
        end

        function test_static_loads_static_load_based(testCase)
            %test_static_loads_static_load_based Verify that a
            %   static_load_based vehicle produces balanced axle loads
            %   with lambda = 0.5.
            F = vehkit.staticLoads.axles(testCase.StaticLoadVehicle);
            g = 9.80665;
            expected = 1000 * g * 0.5;
            testCase.verifyEqual(F(1), expected, 'RelTol', 1e-10);
            testCase.verifyEqual(F(2), expected, 'RelTol', 1e-10);
        end

        function test_static_loads_mass_conservation(testCase)
            %test_static_loads_mass_conservation Verify that the sum of
            %   axle loads equals total weight.
            F = vehkit.staticLoads.axles(testCase.RoadCar);
            g = 9.80665;
            W = testCase.RoadCar.load_configurations.reference.mass * g;
            testCase.verifyEqual(sum(F), W, 'RelTol', 1e-10);
        end

        function test_static_loads_three_axles(testCase)
            %test_static_loads_three_axles Verify that a three-axle
            %   vehicle produces vehkit:unsupportedAxleCount.
            testCase.verifyError( ...
                @() vehkit.staticLoads.axles(testCase.ThreeAxleVehicle), ...
                'vehkit:unsupportedAxleCount');
        end
    end
end