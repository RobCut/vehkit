classdef TestCanonicalVehicles < matlab.unittest.TestCase
    %TestCanonicalVehicles Tests for the canonical vehicle definitions.
    %   Loads data/road_car.json and data/race_car.json, validates them,
    %   and checks a few distinctive derived values.

    properties
        RoadCar
        RaceCar
    end

    methods (TestClassSetup)
        function setup(testCase)
            %setup Load and validate the canonical vehicles.
            here = fileparts(mfilename('fullpath'));
            repoRoot = fileparts(here);
            dataFolder = fullfile(repoRoot, 'data');
            testCase.RoadCar = vehkit.validate( ...
                vehkit.load(fullfile(dataFolder, 'road_car.json')));
            testCase.RaceCar = vehkit.validate( ...
                vehkit.load(fullfile(dataFolder, 'race_car.json')));
        end
    end

    methods (Test)
        function test_road_car_schema_version(testCase)
            %test_road_car_schema_version Verify schema version.
            testCase.verifyEqual(testCase.RoadCar.schema_version, '0.1');
        end

        function test_road_car_wheelbase(testCase)
            %test_road_car_wheelbase Verify the road car wheelbase.
            wb = vehkit.geometry.wheelbase(testCase.RoadCar);
            testCase.verifyEqual(wb, 2.65, 'AbsTol', 1e-12);
        end

        function test_road_car_mass(testCase)
            %test_road_car_mass Verify the road car reference mass.
            testCase.verifyEqual( ...
                testCase.RoadCar.load_configurations.reference.mass, 1385.0, ...
                'AbsTol', 1e-12);
        end

        function test_race_car_schema_version(testCase)
            %test_race_car_schema_version Verify schema version.
            testCase.verifyEqual(testCase.RoadCar.schema_version, '0.1');
        end

        function test_race_car_wheelbase(testCase)
            %test_race_car_wheelbase Verify the race car wheelbase.
            wb = vehkit.geometry.wheelbase(testCase.RaceCar);
            testCase.verifyEqual(wb, 1.55, 'AbsTol', 1e-12);
        end

        function test_race_car_mass(testCase)
            %test_race_car_mass Verify the race car reference mass.
            testCase.verifyEqual( ...
                testCase.RaceCar.load_configurations.reference.mass, 280.0, ...
                'AbsTol', 1e-12);
        end

        function test_race_car_track_width(testCase)
            %test_race_car_track_width Verify front and rear track widths.
            tw = vehkit.geometry.trackWidths(testCase.RaceCar);
            testCase.verifyEqual(tw, [1.20; 1.18], 'AbsTol', 1e-12);
        end
    end
end

