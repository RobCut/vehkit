classdef TestValidate < matlab.unittest.TestCase
    %TestValidate Tests for vehkit.validate.
    %   Covers the schema version contract and, in later stages, the
    %   remaining structural and physical validation rules.

    properties
        ValidVehicle
    end

    methods (TestClassSetup)
        function loadFixture(testCase)
            %loadFixture Load the canonical fixture once for all tests.
            here = fileparts(mfilename('fullpath'));
            fixture = fullfile(here, 'fixtures', 'minimal_valid.json');
            testCase.ValidVehicle = vehkit.load(fixture);
        end
    end

    methods (Test)
        function test_validate_schema_version_missing(testCase)
            %test_validate_schema_version_missing Verify that a missing
            %   schema_version produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v = rmfield(v, 'schema_version');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_schema_version_wrong_type(testCase)
            %test_validate_schema_version_wrong_type Verify that a
            %   non-string schema_version produces
            %   vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.schema_version = 1;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_schema_version_invalid_format(testCase)
            %test_validate_schema_version_invalid_format Verify that a
            %   malformed schema_version produces
            %   vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.schema_version = 'abc';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_schema_version_unsupported(testCase)
            %test_validate_schema_version_unsupported Verify that a
            %   well-formed schema_version produces
            %   vehkit:unsupportedSchemaVersion.
            v = testCase.ValidVehicle;
            v.schema_version = '0.2';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:unsupportedSchemaVersion');
        end

        function test_validate_schema_version_valid(testCase)
            %test_validate_schema_version_valid Verify that the canonical
            %   fixture passes validation without errors.
            v = testCase.ValidVehicle;
            testCase.verifyWarningFree(@() vehkit.validate(v));
        end

        function test_validate_geometry_missing(testCase)
            %test_validate_geometry_missing Verify that a missing geometry
            %   field produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v = rmfield(v, 'geometry');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_geometry_wrong_type(testCase)
            %test_validate_geometry_wrong_type Verify that a non-struct
            %   geometry field produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.geometry = 1;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_axles_missing(testCase)
            %test_validate_axles_missing Verify that a missing axles field
            %   produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v = rmfield(v, 'axles');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_load_configurations_missing(testCase)
            %test_validate_load_configurations_missing Verify that a
            %   missing load_configurations field produces
            %   vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v = rmfield(v, 'load_configurations');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_load_configurations_wrong_type(testCase)
            %test_validate_load_configurations_wrong_type Verify that a
            %   non-struct load_configurations field produces
            %   vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.load_configurations = 1;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end
    end
end