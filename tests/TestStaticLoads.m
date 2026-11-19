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

        function test_static_load_equivalent_to_direct(testCase)
            %test_static_load_equivalent_to_direct Verify that the static_load_based
            %   representation of the road car reconstructs the same axle positions
            %   as the direct representation.
            v = testCase.RoadCar;
            d = vehkit.geometry.cgToAxles(v);

            for k = 1:2
                v.axles{k} = rmfield(v.axles{k}, 'x');
            end
            v.geometry.method = 'static_load_based';
            v.geometry.wheelbase = 2.65;
            v.geometry.front_weight_distribution = 1.59 / 2.65;
            v = vehkit.validate(v);

            s = vehkit.geometry.cgToAxles(v);
            testCase.verifyEqual(s, d, 'AbsTol', 1e-10);

            wcDirect = vehkit.geometry.wheelCentres(testCase.RoadCar);
            wcStatic = vehkit.geometry.wheelCentres(v);
            testCase.verifyEqual(wcStatic, wcDirect, 'AbsTol', 1e-10);

            FDirect = vehkit.staticLoads.axles(testCase.RoadCar);
            FStatic = vehkit.staticLoads.axles(v);
            testCase.verifyEqual(FStatic, FDirect, 'AbsTol', 1e-8);
        end

        function test_static_loads_moment_equilibrium_road_car(testCase)
            %test_static_loads_moment_equilibrium_road_car Verify that the axle
            %   loads satisfy moment equilibrium about the CG.
            F = vehkit.staticLoads.axles(testCase.RoadCar);
            x = vehkit.geometry.cgToAxles(testCase.RoadCar);
            testCase.verifyEqual(F(1)*x(1) + F(2)*x(2), 0, 'AbsTol', 1e-8);
        end

        function test_static_loads_moment_equilibrium_race_car(testCase)
            %test_static_loads_moment_equilibrium_race_car Verify moment equilibrium
            %   for the race car.
            F = vehkit.staticLoads.axles(testCase.RaceCar);
            x = vehkit.geometry.cgToAxles(testCase.RaceCar);
            testCase.verifyEqual(F(1)*x(1) + F(2)*x(2), 0, 'AbsTol', 1e-8);
        end

        function test_static_loads_weight_sum_race_car(testCase)
            %test_static_loads_weight_sum_race_car Verify that the axle loads sum
            %   to the total weight for the race car.
            F = vehkit.staticLoads.axles(testCase.RaceCar);
            W = testCase.RaceCar.load_configurations.reference.mass * 9.80665;
            testCase.verifyEqual(sum(F), W, 'RelTol', 1e-10);
        end
    end
end