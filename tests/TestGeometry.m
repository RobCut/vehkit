classdef TestGeometry < matlab.unittest.TestCase
    %TestGeometry Tests for vehkit.geometry.*.
    %   Covers wheelbase, trackWidths, cgToAxles, and wheelCentres on the
    %   canonical fixtures, plus NaN propagation.

    properties
        MultiAxleVehicle
        SingleAxleVehicle
        StaticLoadVehicle
    end

    methods (TestClassSetup)
        function setup(testCase)
            %setup Load and validate the canonical fixtures.
            here = fileparts(mfilename('fullpath'));
            multiFixture = fullfile(here, 'fixtures', 'minimal_valid.json');
            testCase.MultiAxleVehicle = vehkit.validate(vehkit.load(multiFixture));
            singleFixture = fullfile(here, 'fixtures', 'minimal_single_axle.json');
            testCase.SingleAxleVehicle = vehkit.validate(vehkit.load(singleFixture));
            staticFixture = fullfile(here, 'fixtures', 'minimal_static_load.json');
            testCase.StaticLoadVehicle = vehkit.validate(vehkit.load(staticFixture));
        end
    end

    methods (Test)
        function test_wheelbase_multi_axle(testCase)
            %test_wheelbase_multi_axle Verify the wheelbase of the two-axle
            %   fixture.
            wb = vehkit.geometry.wheelbase(testCase.MultiAxleVehicle);
            testCase.verifyEqual(wb, 2.6, 'AbsTol', 1e-12);
        end

        function test_wheelbase_single_axle(testCase)
            %test_wheelbase_single_axle Verify that a single-axle vehicle
            %   has zero wheelbase.
            wb = vehkit.geometry.wheelbase(testCase.SingleAxleVehicle);
            testCase.verifyEqual(wb, 0, 'AbsTol', 1e-12);
        end

        function test_track_widths_multi_axle(testCase)
            %test_track_widths_multi_axle Verify the track widths of the
            %   two-axle fixtures.
            tw = vehkit.geometry.trackWidths(testCase.MultiAxleVehicle);
            testCase.verifyEqual(tw, [1.5; 1.5], 'AbsTol', 1e-12);
        end

        function test_track_widths_single_axle(testCase)
            %test_track_widths_single_axle Verify a zero track width for a
            %   single-wheel axle.
            tw = vehkit.geometry.trackWidths(testCase.SingleAxleVehicle);
            testCase.verifyEqual(tw, 0, 'AbsTol', 1e-12);
        end

        function test_cg_to_axles_signed(testCase)
            %test_cg_to_axles_signed Verify that CG-to-axle distances are
            %   signed (positive forward, negative rear).
            ca = vehkit.geometry.cgToAxles(testCase.MultiAxleVehicle);
            testCase.verifyEqual(ca, [1.3; -1.3], 'AbsTol', 1e-12);
        end

        function test_wheel_centres_dimensions(testCase)
            %test_wheel_centres_dimensions Verify the wheel centre matrix
            %   shape.
            wc = vehkit.geometry.wheelCentres(testCase.MultiAxleVehicle);
            testCase.verifyEqual(size(wc), [4 3]);
        end

        function test_wheel_centres_values(testCase)
            %test_wheel_centres_values Verify the wheel centre coordinates
            %   on the two-axle fixtures.
            wc = vehkit.geometry.wheelCentres(testCase.MultiAxleVehicle);
            expected = [1.3, 0.75, -0.05;
                1.3, -0.75, -0.05;
                -1.3, 0.75, -0.05;
                -1.3, -0.75, -0.05];
            testCase.verifyEqual(wc, expected, 'AbsTol', 1e-12);
        end

        function test_wheel_centres_nan_from_cg_height(testCase)
            %test_wheel_centres_nan_from_cg_height Verify that NaN in
            %   cg_height propagates to the z column.
            v = testCase.MultiAxleVehicle;
            v.geometry.cg_height = NaN;
            v = vehkit.validate(v);
            wc = vehkit.geometry.wheelCentres(v);
            testCase.verifyTrue(all(isnan(wc(:,3))));
        end

        function test_wheel_centres_nan_from_loaded_radius(testCase)
            %test_wheel_centres_nan_from_loaded_radius Verify that NaN in
            %   one loaded:radius propagates only to that wheel's z.
            v = testCase.MultiAxleVehicle;
            v.axles{1}.wheels{1}.loaded_radius = NaN;
            v = vehkit.validate(v);
            wc = vehkit.geometry.wheelCentres(v);
            testCase.verifyTrue(isnan(wc(1,3)));
            testCase.verifyFalse(isnan(wc(2,3)));
        end

        function test_wheelbase_static_load(testCase)
            %test_wheelbase_static_load Verify the wheelbase of the
            %   static_load_based fixture.
            wb = vehkit.geometry.wheelbase(testCase.StaticLoadVehicle);
            testCase.verifyEqual(wb, 2.6, 'AbsTol', 1e-12);
        end

        function test_cg_to_axles_static_load(testCase)
            %test_cg_to_axles_static_load Verify that the reconstructed 
            %   axle positions match the expected values.
            ca = vehkit.geometry.cgToAxles(testCase.StaticLoadVehicle);
            testCase.verifyEqual(ca, [1.3; -1.3], 'AbsTol', 1e-12);
        end

        function test_wheel_centres_strict_cg_height_nan(testCase)
            %test_wheel_centres_strict_cg_height_nan Verify that 
            %   wheelCentresStrict raises vehkit:missingData when 
            %   cg_height is explicitly unknown.
            v = testCase.MultiAxleVehicle;
            v.geometry.cg_height = NaN;
            v = vehkit.validate(v);
            testCase.verifyError(@() vehkit.geometry.wheelCentresStrict(v), 'vehkit:missingData');
        end

        function test_wheel_centres_strict_loaded_radius_nan(testCase)
            %test_wheel_centres_strict_loaded_radius_nan Verify that
            %   wheelCentresStrict raises vehkit:missingData when a 
            %   loaded_radius is explicitly unknown.
            v = testCase.MultiAxleVehicle;
            v.axles{1}.wheels{1}.loaded_radius = NaN;
            v = vehkit.validate(v);
            testCase.verifyError(@() vehkit.geometry.wheelCentresStrict(v), 'vehkit:missingData');
        end
    end
end