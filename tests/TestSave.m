classdef TestSave < matlab.unittest.TestCase
    %TestSave Tests for vehkit.save.
    %   Covers round-trip preservation, serialization rules, and
    %   validation-before-write behavior.

    properties
        ValidVehicle
        TempFolder
    end

    methods (TestClassSetup)
        function setup(testCase)
            %setup Load the canonical fixture and create a temporary
            %   folder.
            here = fileparts(mfilename('fullpath'));
            fixture = fullfile(here, 'fixtures', 'minimal_valid.json');
            testCase.ValidVehicle = vehkit.validate(vehkit.load(fixture));
            testCase.TempFolder = testCase.createTemporaryFolder();
        end
    end

    methods (Test)
        function test_save_round_trip(testCase)
            %test_save_round_trip Verify that load, save, load preserves
            %   assigned data.
            filePath = fullfile(testCase.TempFolder, 'out.json');
            v = testCase.ValidVehicle;
            vehkit.save(v, filePath);
            v2 = vehkit.validate(vehkit.load(filePath));
            testCase.verifyEqual(v2.schema_version, '0.1');
            testCase.verifyEqual(v2.geometry.method, 'direct');
            testCase.verifyEqual(v2.geometry.cg_height, 0.35);
            testCase.verifyEqual(v2.load_configurations.reference.mass, 1000.0);
            testCase.verifyEqual(v2.load_configurations.reference.inertia.ixx, 500.0);
            testCase.verifyEqual(v2.axles{1}.id, 'axle_1');
            testCase.verifyEqual(v2.axles{1}.wheels{1}.id, 'wheel_1');
            testCase.verifyEqual(v2.axles{2}.x, -1.3);
        end

        function test_save_serialization(testCase)
            %test_save_serialization Verify that the serialized JSON
            %   respects the schema: no derived values, no NaN/Inf
            %   literals, required fields present.
            filePath = fullfile(testCase.TempFolder, 'out.json');
            v = testCase.ValidVehicle;
            vehkit.save(v, filePath);
            text = string(fileread(filePath));
            testCase.verifyTrue(contains(text, '"schema_version"'));
            testCase.verifyTrue(contains(text, '"geometry"'));
            testCase.verifyTrue(contains(text, '"axles"'));
            testCase.verifyTrue(contains(text, '"load_configurations"'));
            testCase.verifyFalse(contains(text, '"wheelbase"'));
            testCase.verifyFalse(contains(text, '"NaN"'));
            testCase.verifyFalse(contains(text, '"Inf"'));
        end

        function test_save_invalid_vehicle(testCase)
            %test_save_invalid_vehicle Verify that save validates before
            %   writing and leaves no file on disk when validation fails.
            filePath = fullfile(testCase.TempFolder, 'bad.json');
            v = testCase.ValidVehicle;
            v.load_configurations.reference.mass = -1;
            testCase.verifyError(@() vehkit.save(v, filePath), 'vehkit:invalidParameter');
            testCase.verifyFalse(isfile(filePath));
        end

        function test_save_static_load_based_round_trip(testCase)
            %test_save_static_load_based_round_trip Verify that a static_load_based
            %   vehicle survives load-validate-save-load-validate without axles[].x
            %   appearing in the JSON.
            here = fileparts(mfilename('fullpath'));
            fixture = fullfile(here, 'fixtures', 'minimal_static_load.json');
            v = vehkit.validate(vehkit.load(fixture));
            filePath = fullfile(testCase.TempFolder, 'static_load.json');
            vehkit.save(v, filePath);
            text = string(fileread(filePath));
            testCase.verifyFalse(contains(text, '"x"'));
            testCase.verifyTrue(contains(text, '"wheelbase"'));
            testCase.verifyTrue(contains(text, '"front_weight_distribution"'));
            v2 = vehkit.validate(vehkit.load(filePath));
            testCase.verifyEqual(v2.axles{1}.x, 1.3, 'AbsTol', 1e-12);
            testCase.verifyEqual(v2.axles{2}.x, -1.3, 'AbsTol', 1e-12);
        end

        function test_save_tyre_round_trip(testCase)
            %test_save_tyre_round_trip Verify that the tyre block is preserved
            %   through load-validate-save-load-validate.
            here = fileparts(mfilename('fullpath'));
            repoRoot = fileparts(here);
            baseFixture = fullfile(repoRoot, 'tests', 'fixtures', 'minimal_valid.json');
            v = vehkit.validate(vehkit.load(baseFixture));
            v.tyre = struct('model', 'MF61', ...
                'parameters', struct('PCX1', 1.5, 'PDY1', 1.2));
            filePath = fullfile(testCase.TempFolder, 'tyre.json');
            vehkit.save(v, filePath);
            v2 = vehkit.validate(vehkit.load(filePath));
            testCase.verifyEqual(v2.tyre.model, 'MF61');
            testCase.verifyEqual(v2.tyre.parameters.PCX1, 1.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(v2.tyre.parameters.PDY1, 1.2, 'AbsTol', 1e-12);
        end

        function test_save_round_trip_absent_null_zero(testCase)
            %test_save_round_trip_absent_null_zero Verify that absent, null (NaN),
            %   and zero-valued data remain distinct through the round-trip.
            filePath = fullfile(testCase.TempFolder, 'roundtrip.json');
            v = testCase.ValidVehicle;
            % Set up: absent (ixz and iyz not in fixture), null (cg_height = NaN),
            % zero (ixy = 0)
            testCase.assertFalse(isfield(v.load_configurations.reference.inertia, 'ixz'));
            testCase.assertFalse(isfield(v.load_configurations.reference.inertia, 'iyz'));
            v.geometry.cg_height = NaN;
            v.load_configurations.reference.inertia.ixy = 0;
            vehkit.save(v, filePath);
            text = fileread(filePath);
            testCase.verifyTrue(contains(text, '"cg_height": null'));
            testCase.verifyTrue(contains(text, '"ixy": 0'));
            v2 = vehkit.load(filePath);
            % null preserved
            testCase.verifyTrue(isnan(v2.geometry.cg_height));
            % zero preserved
            testCase.verifyEqual(v2.load_configurations.reference.inertia.ixy, 0);
            testCase.verifyFalse(isnan(v2.load_configurations.reference.inertia.ixy));
            % absent preserved
            testCase.verifyFalse(isfield(v2.load_configurations.reference.inertia, 'ixz'));
            testCase.verifyFalse(isfield(v2.load_configurations.reference.inertia, 'iyz'));
        end
    end
end