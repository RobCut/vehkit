classdef TestValidate < matlab.unittest.TestCase
    %TestValidate Tests for vehkit.validate.
    %   Covers the schema version contract and, in later stages, the
    %   remaining structural and physical validation rules.

    properties
        ValidVehicle
        SingleAxleVehicle
        StaticLoadVehicle
    end

    methods (TestClassSetup)
        function loadFixture(testCase)
            %loadFixture Load the canonical fixture once for all tests.
            here = fileparts(mfilename('fullpath'));
            fixture = fullfile(here, 'fixtures', 'minimal_valid.json');
            testCase.ValidVehicle = vehkit.validate(vehkit.load(fixture));
            fixture = fullfile(here, 'fixtures', 'minimal_single_axle.json');
            testCase.SingleAxleVehicle = vehkit.load(fixture);
            fixture = fullfile(here, 'fixtures', 'minimal_static_load.json');
            testCase.StaticLoadVehicle = vehkit.load(fixture);
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

        function test_validate_normalizes_single_axle(testCase)
            %test_validate_normalizes_single_axle Verify that a vehicle
            %   with a single axle is normalized to a 1x1 cell array of
            %   structs.
            v = testCase.SingleAxleVehicle;
            v = vehkit.validate(v);
            testCase.verifyTrue(iscell(v.axles));
            testCase.verifyEqual(numel(v.axles), 1);
            testCase.verifyTrue(isstruct(v.axles{1}));
            testCase.verifyTrue(isscalar(v.axles{1}));
        end

        function test_validate_nullable_cg_height_nan(testCase)
            %test_validate_nullable_cg_height_nan Verify that NaN in
            %   cg_height (nullable) is accepted.
            v = testCase.ValidVehicle;
            v.geometry.cg_height = NaN;
            testCase.verifyWarningFree(@() vehkit.validate(v));
        end

        function test_validate_nullable_loaded_radius_nan(testCase)
            %test_validate_nullable_loaded_radius_nan Verify that NaN in a
            %   wheel's loaded_radius (nullable) is accepted.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.loaded_radius = NaN;
            testCase.verifyWarningFree(@() vehkit.validate(v));
        end

        function test_validate_nullable_inertia_nan(testCase)
            %test_validate_nullable_inertia_nan Verify that NaN in an
            %   inertia component (nullable) is accepted.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.inertia.ixx = NaN;
            testCase.verifyWarningFree(@() vehkit.validate(v));
        end

        function test_validate_non_nullable_mass_nan(testCase)
            %test_validate_non_nullable_mass_nan Verify that NaN in mass
            %   (non-nullable) produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.mass = NaN;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_non_nullable_axle_x_nan(testCase)
            %test_validate_non_nullable_axle_x_nan Verify that NaN in an
            %   axle's x (non-nullable) produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.axles{1}.x = NaN;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_non_nullable_wheel_y_nan(testCase)
            %test_validate_non_nullable_wheel_y_nan Verify that NaN in a
            %   wheel's y (non-nullable) produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.y = NaN;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_mass_negative(testCase)
            %test_validate_mass_negative Verify that a negative mass
            %   produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.mass = -100;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_mass_zero(testCase)
            %test_validate_mass_zero Verify that zero mass produces
            %   vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.mass = 0;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_loaded_radius_zero(testCase)
            %test_validate_loaded_radius_zero Verify that a zero
            %   loaded_radius (known value) produces
            %   vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.loaded_radius = 0;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_geometry_method_unknown(testCase)
            %test_validate_geometry_method_unknown Verify that an unknown
            %   geometry method produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.geometry.method = 'foo';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_geometry_wheelbase_conflict(testCase)
            %test_validate_geometry_wheelbase_conflict Verify that a
            %   wheelbase field with direct geometry produces
            %   vehkit:conflictingGeometryDefinition.
            v = testCase.ValidVehicle;
            v.geometry.wheelbase = 2.6;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:conflictingGeometryDefinition');
        end

        function test_validate_geometry_front_weight_distribution_conflict(testCase)
            %test_validate_geometry_front_weight_distribution_conflict Verify
            %   that a front_weight_distribution field with direct geometry
            %   produces vehkit:conflictingGeometryDefinition.
            v = testCase.ValidVehicle;
            v.geometry.front_weight_distribution = 0.5;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:conflictingGeometryDefinition');
        end

        function test_validate_axle_order_mismatch(testCase)
            %test_validate_axle_order_mismatch Verify that axles not
            %   ordered from front to rear produce
            %   vehkit:axleOrderMismatch.
            v = testCase.ValidVehicle;
            v.axles = v.axles([2 1]);
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:axleOrderMismatch');
        end

        function test_validate_wheel_order_mismatch(testCase)
            %test_validate_wheel_order_mismatch Verify that wheels not
            %   ordered from left to right produce vehkit:wheelOrderMismatch.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels = v.axles{1}.wheels([2 1]);
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:wheelOrderMismatch');
        end

        function test_validate_wheel_same_y_wrong_canonical(testCase)
            %test_validate_wheel_same_y_wrong_canonical Verify that two
            %   wheels with the same y must be ordered by canonical id.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.y = 0.75;
            v.axles{1}.wheels{2}.y = 0.75;
            v.axles{1}.wheels = v.axles{1}.wheels([2 1]);
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:wheelOrderMismatch');
        end

        function test_validate_wheel_same_y_correct_canonical(testCase)
            %test_validate_wheel_same_y_correct_canonical Verify that two
            %   wheels with the same y and canonical id order are accepted.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.y = 0.75;
            v.axles{1}.wheels{2}.y = 0.75;
            testCase.verifyWarningFree(@() vehkit.validate(v));
        end

        function test_validate_axle_id_invalid_format(testCase)
            %test_validate_axle_id_invalid_format Verify that an axle id
            %   that does not match the canonical pattern produces
            %   vehkit:invalidParameter
            v = testCase.ValidVehicle;
            v.axles{1}.id = 'Axle_1';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_wheel_id_invalid_format(testCase)
            %test_validate_wheel_id_invalid_format Verify that a wheel id
            %   that does not match the canonical pattern produces
            %   vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.id = 'wheel_0';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_axle_id_duplicate(testCase)
            %test_validate_axle_id_duplicate Verify that duplicate axle
            %   ids produce vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.axles{2}.id = v.axles{1}.id;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_wheel_id_duplicate(testCase)
            %test_validate_wheel_id_duplicate Verify that duplicate wheel
            %   ids produce vehkit:invalidParameter, even across axles.
            v = testCase.ValidVehicle;
            v.axles{2}.wheels{1}.id = v.axles{1}.wheels{1}.id;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_inertia_diagonal_negative(testCase)
            %test_validate_inertia_diagonal_negative Verify that a negative
            %   diagonal inertia component produces vehkit:invalidInertia.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.inertia.ixx = -1;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidInertia');
        end

        function test_validate_inertia_triangle_violation(testCase)
            %test_validate_inertia_triangle_violation Verify that a
            %   complete diagonal that violates the triangle inequalities
            %   produces vehkit:invalidInertia.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.inertia.ixx = 1;
            v.load_configurations.reference.inertia.iyy = 1;
            v.load_configurations.reference.inertia.izz = 100;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidInertia');
        end

        function test_validate_inertia_psd_violation(testCase)
            %test_validate_inertia_psd_violation Verify that a complete
            %   inertia tensor that is not positive semidefinite produces
            %   vehkit:invalidInertia.
            v = testCase.ValidVehicle;
            inertia = v.load_configurations.reference.inertia;
            inertia.ixx = 1;
            inertia.iyy = 1;
            inertia.izz = 1;
            inertia.ixy = 100;
            inertia.ixz = 0;
            inertia.iyz = 0;
            v.load_configurations.reference.inertia = inertia;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidInertia');
        end

        function test_validate_inertia_full_tensor_valid(testCase)
            %test_validate_inertia_full_tensor_valid Verify that a
            %   complete, physically valid inertia tensor is accepted.
            v = testCase.ValidVehicle;
            inertia = v.load_configurations.reference.inertia;
            inertia.ixx = 500;
            inertia.iyy = 1500;
            inertia.izz = 1800;
            inertia.ixy = 10;
            inertia.ixz = 5;
            inertia.iyz = 0;
            v.load_configurations.reference.inertia = inertia;
            testCase.verifyWarningFree(@() vehkit.validate(v));
        end

        function test_validate_static_load_based_valid(testCase)
            %test_validate_static_load_based_valid Verify that a
            %   well-formed static_load_based_vehicle is accepted.
            v = testCase.StaticLoadVehicle;
            v = vehkit.validate(v);
            testCase.verifyEqual(v.axles{1}.x, 1.3, 'AbsTol', 1e-12);
            testCase.verifyEqual(v.axles{2}.x, -1.3, 'AbsTol', 1e-12);
        end

        function test_validate_static_load_based_axle_x_forbidden(testCase)
            %test_validate_static_load_based_axle_x_forbidden Verify that
            %   axles[].x is forbidden with static_load_based geometry.
            v = testCase.ValidVehicle;
            v.geometry.method = 'static_load_based';
            v.geometry.wheelbase = 2.6;
            v.geometry.front_weight_distribution = 0.5;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:conflictingGeometryDefinition');
        end

        function test_validate_static_load_based_wheelbase_missing(testCase)
            %test_validate_static_load_based_wheelbase_missing Verify that
            %   a missing wheelbase produces vehkit:invalidJSONStructure.
            v = testCase.StaticLoadVehicle;
            v.geometry = rmfield(v.geometry, 'wheelbase');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_static_load_based_fwd_missing(testCase)
            %test_validate_static_load_based_fwd_missing Verify that a
            %   missing front_weight_distribution produces
            %   vehkit:invalidJSONStructure.
            v = testCase.StaticLoadVehicle;
            v.geometry = rmfield(v.geometry, 'front_weight_distribution');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_static_load_based_three_axles(testCase)
            %test_validate_static_load_based_three_axles Verify that a
            %   static_load_based vehicle with 3 axles produces
            %   vehkit:unsupportedAxleCount.
            v = testCase.ValidVehicle;
            v.axles{end+1} = v.axles{end};
            v.axles{end}.id = 'axle_3';
            v.geometry.method = 'static_load_based';
            v.geometry.wheelbase = 2.6;
            v.geometry.front_weight_distribution = 0.5;
            for k = 1:numel(v.axles)
                v.axles{k} = rmfield(v.axles{k}, 'x');
            end
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:unsupportedAxleCount');
        end

        function test_validate_static_load_based_fwd_out_of_range(testCase)
            %test_validate_static_load_based_fwd_out_of_range Verify that a
            %   front_weight_distribution outside (0,1) produces
            %   vehkit:invalidParameter
            v = testCase.StaticLoadVehicle;
            v.geometry.front_weight_distribution = 0;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_presence_cg_height_missing(testCase)
            %test_validate_presence_cg_height_missing Verify that a missing
            %   cg_height produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.geometry = rmfield(v.geometry, 'cg_height');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_presence_wheel_y_missing(testCase)
            %test_validate_presence_wheel_y_missing Verify that a missing
            %   wheel y produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1} = rmfield(v.axles{1}.wheels{1}, 'y');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_presence_loaded_radius_missing(testCase)
            %test_validate_presence_loaded_radius_missing Verify that a
            %   missing loaded_radius produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1} = rmfield(v.axles{1}.wheels{1}, 'loaded_radius');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_presence_mass_missing(testCase)
            %test_validate_presence_mass_missing Verify that a missing
            %   reference mass produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.load_configurations.reference = rmfield(v.load_configurations.reference, 'mass');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_mass_inf(testCase)
            %test_validate_mass_inf Verify that an infinite mass produces
            %   vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.mass = Inf;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_mass_neg_inf(testCase)
            %test_validate_mass_neg_inf Verify that a negative infinite mass
            %   produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.mass = -Inf;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_axle_x_inf(testCase)
            %test_validate_axle_x_inf Verify that an infinite axle x produces
            %   vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.axles{1}.x = Inf;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_wheel_y_inf(testCase)
            %test_validate_wheel_y_inf Verify that an infinite wheel y produces
            %   vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.y = Inf;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_loaded_radius_inf(testCase)
            %test_validate_loaded_radius_inf Verify that an infinite loaded_radius
            %   produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.loaded_radius = Inf;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_cg_height_inf(testCase)
            %test_validate_cg_height_inf Verify that an infinite cg_height
            %   produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.geometry.cg_height = Inf;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_mass_wrong_type(testCase)
            %test_validate_mass_wrong_type Verify that a non-numeric mass produces
            %   vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.mass = 'abc';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_axle_x_wrong_type(testCase)
            %test_validate_axle_x_wrong_type Verify that a non-numeric axle x
            %   produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.axles{1}.x = 'abc';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_wheel_y_wrong_type(testCase)
            %test_validate_wheel_y_wrong_type Verify that a non-numeric wheel y
            %   produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.y = 'abc';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_loaded_radius_wrong_type(testCase)
            %test_validate_loaded_radius_wrong_type Verify that a non-numeric
            %   loaded_radius produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.loaded_radius = 'abc';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_cg_height_wrong_type(testCase)
            %test_validate_cg_height_wrong_type Verify that a non-numeric cg_height
            %   produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.geometry.cg_height = 'abc';
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_alternative_valid(testCase)
            %test_validate_alternative_valid Verify that a well-formed alternative
            %   load configuration is accepted.
            v = testCase.ValidVehicle;
            v.load_configurations.alternative = struct( ...
                'mass', 1300.0, ...
                'cg_offset', [0.05; 0.0; -0.02], ...
                'inertia', struct('ixx', 480, 'iyy', 1450, 'izz', 1750));
            testCase.verifyWarningFree(@() vehkit.validate(v));
        end

        function test_validate_alternative_mass_missing(testCase)
            %test_validate_alternative_mass_missing Verify that a missing
            %   alternative mass produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.load_configurations.alternative = struct( ...
                'cg_offset', [0.05; 0.0; -0.02], ...
                'inertia', struct('ixx', 480, 'iyy', 1450, 'izz', 1750));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_alternative_mass_negative(testCase)
            %test_validate_alternative_mass_negative Verify that a negative
            %   alternative mass produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.load_configurations.alternative = struct( ...
                'mass', -100.0, ...
                'cg_offset', [0.05; 0.0; -0.02], ...
                'inertia', struct('ixx', 480, 'iyy', 1450, 'izz', 1750));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_alternative_cg_offset_missing(testCase)
            %test_validate_alternative_cg_offset_missing Verify that a missing
            %   cg_offset produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.load_configurations.alternative = struct( ...
                'mass', 1300.0, ...
                'inertia', struct('ixx', 480, 'iyy', 1450, 'izz', 1750));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_alternative_cg_offset_wrong_length(testCase)
            %test_validate_alternative_cg_offset_wrong_length Verify that a
            %   cg_offset with the wrong number of components produces
            %   vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.load_configurations.alternative = struct( ...
                'mass', 1300.0, ...
                'cg_offset', [0.05; 0.0], ...
                'inertia', struct('ixx', 480, 'iyy', 1450, 'izz', 1750));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_alternative_cg_offset_nan(testCase)
            %test_validate_alternative_cg_offset_nan Verify that a cg_offset with
            %   an unknown component produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.load_configurations.alternative = struct( ...
                'mass', 1300.0, ...
                'cg_offset', [0.05; NaN; -0.02], ...
                'inertia', struct('ixx', 480, 'iyy', 1450, 'izz', 1750));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_alternative_inertia_missing(testCase)
            %test_validate_alternative_inertia_missing Verify that a missing
            %   alternative inertia produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.load_configurations.alternative = struct( ...
                'mass', 1300.0, ...
                'cg_offset', [0.05; 0.0; -0.02]);
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_alternative_inertia_not_psd(testCase)
            %test_validate_alternative_inertia_not_psd Verify that an alternative
            %   inertia tensor that is not positive semidefinite produces
            %   vehkit:invalidInertia.
            v = testCase.ValidVehicle;
            v.load_configurations.alternative = struct( ...
                'mass', 1300.0, ...
                'cg_offset', [0.05; 0.0; -0.02], ...
                'inertia', struct('ixx', 1, 'iyy', 1, 'izz', 1, ...
                'ixy', 100, 'ixz', 0, 'iyz', 0));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidInertia');
        end

        function test_missing_data_distinction(testCase)
            %test_missing_data_distinction Verify the distinction between absent
            %   and explicitly unknown data: absent produces
            %   vehkit:invalidJSONStructure, explicitly unknown produces
            %   vehkit:missingData when a calculation requires it.
            v = testCase.ValidVehicle;
            vAbsent = v;
            vAbsent.geometry = rmfield(vAbsent.geometry, 'cg_height');
            testCase.verifyError(@() vehkit.validate(vAbsent), 'vehkit:invalidJSONStructure');
            vUnknown = v;
            vUnknown.geometry.cg_height = NaN;
            vUnknown = vehkit.validate(vUnknown);
            testCase.verifyError( ...
                @() vehkit.geometry.wheelCentresStrict(vUnknown), ...
                'vehkit:missingData');
        end

        function test_validate_tyre_valid(testCase)
            %test_validate_tyre_valid Verify that a well-formed tyre block is
            %   accepted.
            v = testCase.ValidVehicle;
            v.tyre = struct( ...
                'model', 'MF61', ...
                'parameters', struct('PCX1', 1.5, 'PDY1', 1.2));
            testCase.verifyWarningFree(@() vehkit.validate(v));
        end

        function test_validate_tyre_model_missing(testCase)
            %test_validate_tyre_model_missing Verify that a missing tyre.model
            %   produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.tyre = struct('parameters', struct('PCX1', 1.5));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_tyre_model_empty(testCase)
            %test_validate_tyre_model_empty Verify that an empty tyre.model
            %   produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.tyre = struct('model', '', 'parameters', struct('PCX1', 1.5));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_tyre_parameters_missing(testCase)
            %test_validate_tyre_parameters_missing Verify that a missing
            %   tyre.parameters produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.tyre = struct('model', 'MF61');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_tyre_parameters_nan(testCase)
            %test_validate_tyre_parameters_nan Verify that a NaN value inside
            %   tyre.parameters produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.tyre = struct('model', 'MF61', ...
                'parameters', struct('PCX1', NaN));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_tyre_parameters_inf(testCase)
            %test_validate_tyre_parameters_inf Verify that an Inf value inside
            %   tyre.parameters produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.tyre = struct('model', 'MF61', ...
                'parameters', struct('PCX1', Inf));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_direct_axle_x_missing(testCase)
            %test_validate_direct_axle_x_missing Verify that a direct geometry
            %   vehicle with a missing axles[].x produces
            %   vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.axles{1} = rmfield(v.axles{1}, 'x');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_cg_height_negative(testCase)
            %test_validate_cg_height_negative Verify that a negative cg_height
            %   produces vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.geometry.cg_height = -0.3;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_cg_height_zero(testCase)
            %test_validate_cg_height_zero Verify that a zero cg_height produces
            %   vehkit:invalidParameter.
            v = testCase.ValidVehicle;
            v.geometry.cg_height = 0;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_static_load_wheelbase_nan(testCase)
            %test_validate_static_load_wheelbase_nan Verify that a NaN wheelbase
            %   with static_load_based geometry produces vehkit:invalidParameter.
            v = testCase.StaticLoadVehicle;
            v.geometry.wheelbase = NaN;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_static_load_fwd_nan(testCase)
            %test_validate_static_load_fwd_nan Verify that a NaN
            %   front_weight_distribution with static_load_based geometry produces
            %   vehkit:invalidParameter.
            v = testCase.StaticLoadVehicle;
            v.geometry.front_weight_distribution = NaN;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidParameter');
        end

        function test_validate_static_load_based_three_axles_with_x(testCase)
            %test_validate_static_load_based_three_axles_with_x Verify that a
            %   static_load_based vehicle with 3 axles AND axles[].x present
            %   produces vehkit:conflictingGeometryDefinition (conflict checked
            %   before axle count, per SCHEMA §6.3.4).
            v = testCase.ValidVehicle;
            v.axles{end+1} = v.axles{end};
            v.axles{end}.id = 'axle_3';
            v.geometry.method = 'static_load_based';
            v.geometry.wheelbase = 2.6;
            v.geometry.front_weight_distribution = 0.5;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:conflictingGeometryDefinition');
        end

        function test_validate_mass_logical(testCase)
            %test_validate_mass_logical Verify that a logical mass produces
            %   vehkit:invalidJSONStructure (logicals are not numeric).
            v = testCase.ValidVehicle;
            v.load_configurations.reference.mass = true;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_tyre_null_in_parameters(testCase)
            %test_validate_tyre_null_in_parameters Verify that a null value
            %   inside tyre.parameters produces vehkit:invalidJSONStructure
            %   (SCHEMA §7), not invalidParameter.
            here = fileparts(mfilename('fullpath'));
            fixture = fullfile(here, 'fixtures', 'invalid_tyre_null.json');
            v = vehkit.load(fixture);
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_tyre_model_null(testCase)
            %test_validate_tyre_model_null Verify that a null tyre.model produces
            %   vehkit:invalidJSONStructure (SCHEMA §4.2: null supplied for a
            %   string field is a structural error).
            v = testCase.ValidVehicle;
            v.tyre = struct('model', [], 'parameters', struct('PCX1', 1.5));
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_unknown_field_geometry(testCase)
            %test_validate_unknown_field_geometry Verify that an unrecognized field
            %   in the geometry block produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.geometry.unknown_field = 1;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_unknown_field_inertia(testCase)
            %test_validate_unknown_field_inertia Verify that an unrecognized field
            %   in the inertia block (e.g. ixxx instead of ixx) produces
            %   vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.inertia.ixxx = 1;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_unknown_field_reference(testCase)
            %test_validate_unknown_field_reference Verify that an unrecognized
            %   field in the reference configuration produces
            %   vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.load_configurations.reference.unknown = 1;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_unknown_field_tyre(testCase)
            %test_validate_unknown_field_tyre Verify that an unrecognized field
            %   in the tyre block produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.tyre = struct('model', 'MF61', 'parameters', struct('PCX1', 1.5), 'unknown', 1);
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_unknown_field_axle(testCase)
            %test_validate_unknown_field_axle Verify that an unrecognized field
            %   in an axle produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.axles{1}.unknown = 1;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_unknown_field_wheel(testCase)
            %test_validate_unknown_field_wheel Verify that an unrecognized field
            %   in a wheel produces vehkit:invalidJSONStructure.
            v = testCase.ValidVehicle;
            v.axles{1}.wheels{1}.unknown = 1;
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end

        function test_validate_reference_inertia_missing(testCase)
            %test_validate_reference_inertia_missing Verify that a missing
            %   reference.inertia produces vehkit:invalidJSONStructure (not a
            %   native MATLAB error).
            v = testCase.ValidVehicle;
            v.load_configurations.reference = rmfield(v.load_configurations.reference, 'inertia');
            testCase.verifyError(@() vehkit.validate(v), 'vehkit:invalidJSONStructure');
        end
    end
end