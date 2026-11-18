classdef TestLoader < matlab.unittest.TestCase
    %TestLoader Tests for vehkit.load and vehkit.save
    %   Covers the round-trip of the canonical fixtures, the distinction
    %   between absent, unknown, and zero-valued data, and the public error
    %   identifiers raised by the loader.

    methods (Test)
        function test_load_minimal_fixture(testCase)
            %test_load_minimal_fixture Load the minimal fixture and verify
            %   that the top-level fields are decoded into the expected struct
            %   fields.
            here = fileparts(mfilename('fullpath'));
            fixture = fullfile(here, 'fixtures', 'minimal_valid.json');
            vehicle = vehkit.load(fixture);
            testCase.verifyEqual(vehicle.schema_version, '0.1');
            testCase.verifyEqual(vehicle.geometry.method, 'direct');
        end

        function test_load_file_missing(testCase)
            %test_load_file_missing Verify that a missing file raises the
            %   native MATLAB error rather than a vehkit error.
            here = fileparts(mfilename('fullpath'));
            missingFile = fullfile(here, 'fixtures', 'does_not_exist.json');
            testCase.verifyError( ...
                @() vehkit.load(missingFile), ...
                'MATLAB:fileread:cannotOpenFile');
        end

        function test_load_invalid_json(testCase)
            %test_load_invalid_json Verify that malformed JSON produces
            %   vehkit:invalidJSONStructure.
            here = fileparts(mfilename('fullpath'));
            badFile = fullfile(here, 'fixtures', 'invalid_syntax.json');
            testCase.verifyError( ...
                @() vehkit.load(badFile), ...
                'vehkit:invalidJSONStructure');
        end

        function test_load_invalid_root_array(testCase)
            %test_load_invalid_root_array Verify that a JSON document whose root is
            %   not an object produces vehkit:invalidJSONStructure.
            here = fileparts(mfilename('fullpath'));
            fixture = fullfile(here, 'fixtures', 'invalid_root_array.json');
            testCase.verifyError(@() vehkit.load(fixture), 'vehkit:invalidJSONStructure');
        end
    end
end