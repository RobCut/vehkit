# Design Decisions

## 1. Development Scope

### 1.1. v0.1 — Initial Release

The initial release establishes a functional and testable foundation for vehicle data management in MATLAB.

Its scope is deliberately limited to vehicle-level properties, axle and wheel organization, load configurations, JSON data management, and validation.

The following features are included:

#### 1.1.1. Delivered in alpha

**Vehicle structure**

- General vehicle definition.
- Support for an arbitrary number of axles.
- Support for an arbitrary number of wheels per axle.
- Stable identification of axles and wheels, independent of their ordering.
- Axles ordered from front to rear.
- Axle ordering is verified from their assigned longitudinal positions in the global vehicle reference frame.
- Invalid axle ordering in the `direct` geometry method must produce the identifiable error `vehkit:axleOrderMismatch`.
- Wheels within each axle are ordered from left to right, according to non-increasing global lateral coordinate (`y`).
- Wheels with identical lateral coordinates are allowed, supporting configurations such as twin wheels.
- When two or more wheels within the same axle have identical lateral coordinates, their stable identifiers are used as a secondary deterministic ordering criterion.
- The canonical ordering rules for wheel identifiers are defined in `docs/SCHEMA.md`.
- Wheel ordering is verified from the assigned coordinates and identifiers within each axle. Invalid ordering must produce the identifiable error `vehkit:wheelOrderMismatch`.
- In the `static_load_based` geometry method, axle ordering is declared by the axle structure and cannot be geometrically verified because longitudinal axle positions are derived rather than assigned.

**Geometry**

- Two mutually exclusive geometry definition methods are supported, selected through the explicit field `geometry.method`:
  - `direct`
  - `static_load_based`

- **Direct geometry:** longitudinal axle positions are assigned directly. Wheelbase, track widths and CG-to-axle distances are derived.

- The following parameters are exclusive to the direct method:
  - Longitudinal axle positions.

- The following parameters are common to both methods:
  - Lateral wheel positions.
  - Reference vehicle CG height above the road surface.
  - Individual loaded radius for each wheel.

- The wheelbase (`wheelbase`) is defined as the longitudinal distance between the first and last axles:
  - `wheelbase = x_first_axle - x_last_axle`.
  - This definition applies to vehicles with any number of axles.

- In the direct method, longitudinal axle positions are assigned individually. Each wheel inherits its longitudinal coordinate (`x`) from its corresponding axle.

- Lateral wheel positions are assigned individually for each wheel.

- All assigned and derived positions are expressed as three-dimensional vectors in the global vehicle reference frame.

- The vehicle CG of the reference load configuration is located at the global origin.

- The road surface is assumed to be flat, horizontal and common to all wheels in v0.1.

- The loaded radius (`loaded_radius`) is defined individually for each wheel as the vertical distance between the wheel centre and the road surface under its static reference load.

- Loaded radius is distinct from unloaded geometric radius and dynamic rolling radius.

- Wheel-centre vertical positions are derived from the reference CG height and individual loaded radii:
  - `z_wheel = loaded_radius - h_CG`.

- Different loaded radii may therefore result in different wheel-centre heights.

- Derived geometric properties include wheel-centre positions, wheelbase, track widths and CG-to-axle distances.

- **Static-load-based geometry:** wheelbase and front weight distribution are assigned, and longitudinal axle positions are reconstructed using static equilibrium equations. This method is restricted to two-axle vehicles.

- The following parameters are exclusive to the static-load-based method:
  - Wheelbase.
  - Front weight distribution (`front_weight_distribution`).

- The presence of parameters exclusive to the geometry definition method not selected by `geometry.method` is not allowed and must produce the identifiable error `vehkit:conflictingGeometryDefinition`.

- The `static_load_based` method remains restricted to two-axle vehicles. A `static_load_based` geometry definition with a number of axles different from two must produce the identifiable error `vehkit:unsupportedAxleCount` during vehicle validation.

- The front weight distribution (`front_weight_distribution`) is defined as the dimensionless fraction of the total static vehicle weight supported by the front axle:
  - It is a fraction, not a percentage.
  - Its valid range is strictly between zero and one: `0 < front_weight_distribution < 1`.
  - It refers exclusively to the reference load configuration.

- Static-load-based geometry calculations use the reference load configuration.

- Functions that produce a partially defined result (for example a
  matrix whose valid components are known and whose unknown components
  depend on a nullable field) propagate `NaN` in the unknown components
  rather than raising `vehkit:missingData`. In v0.1, this applies to
  `vehkit.geometry.wheelCentres` when `geometry.cg_height` or
  `axles[].wheels[].loaded_radius` is unknown.

- Functions that cannot produce a meaningful result without specific
  data raise `vehkit:missingData` when the required data are absent or
  explicitly unknown. The error message distinguishes absent data from
  explicitly unknown data.

**Mass and inertia**

- Vehicle-level total mass.
- Vehicle-level inertia tensor.
- Explicit distinction between assigned and derived properties.
- Support for partially specified inertia tensors.
- Inertia components are expressed in the global reference orientation and referred to the CG of the corresponding load configuration.
- Inertia validation is performed according to the available data:
  - Individual components must be finite numerical values.
  - When the complete diagonal is available:
    - Diagonal inertia components must be non-negative.
    - The triangle inequalities on the diagonal components must be satisfied within the defined numerical tolerance:
      - `Ixx + Iyy - Izz >= -tol_triangle`.
      - `Ixx + Izz - Iyy >= -tol_triangle`.
      - `Iyy + Izz - Ixx >= -tol_triangle`.
  - When the complete inertia tensor is available:
    - Positive semidefiniteness is checked using an explicitly defined numerical tolerance on its eigenvalues.
    - The minimum eigenvalue must satisfy `lambda_min >= -tol_PSD`.
  - Missing components are not assumed to be zero.
- Physically inconsistent inertia properties must produce the identifiable error `vehkit:invalidInertia`.

**Load configurations**

- Separation between vehicle definition and load configurations.
- One reference load configuration (`reference`).

- Axle and wheel positions remain unchanged between load configurations.

**Tyres**

- Optional tyre representation at vehicle level.
- In v0.1, the vehicle supports a single tyre model identifier and one uninterpreted parameter block shared by all wheels.
- Model-specific parameter validation is outside the scope of v0.1 and belongs to the corresponding tyre-model project.

**Data management**

- JSON-based data loading and saving.
- Persistent storage of assigned values only.
- Derived properties are calculated in MATLAB and are not saved as independent source data.
- Schema version identification through `schema_version`.
- Structural and physical validation.
- Explicit distinction between absent, unknown and zero-valued data.
- JSON loading and saving must preserve assigned data through a complete round-trip.
- Round-trip tests must verify that absent, unknown and zero-valued data remain distinct.
- The JSON representation of explicitly unknown values is defined in `docs/SCHEMA.md`.
- Floating-point comparisons in round-trip tests must use an explicitly defined numerical tolerance.

**MATLAB functionality**

- Dedicated functions for loading, saving, validating and calculating vehicle properties.
- Each calculation function performs a clearly defined operation.
- Explicit error reporting when required data are absent or explicitly unknown.
- Identifiable error identifiers for invalid or unsupported configurations.
- Automated tests for implemented functionality.

#### 1.1.2. Delivered before the v0.1 release

**Static equilibrium calculations**

- Static equilibrium calculations are supported only for vehicles with exactly two axles. Any static equilibrium calculation requested for a vehicle with a different number of axles must produce the identifiable error `vehkit:unsupportedAxleCount`.

- Static equilibrium calculations use the standard gravitational acceleration:
  - `g = 9.80665 m/s^2`.

- Static axle loads may be derived when the required mass and CG data are available. Individual wheel loads are not derived in v0.1.

- The distribution of vertical loads between wheels belonging to the same axle is outside the scope of v0.1 because it requires additional assumptions or physical information.

**Load configurations**

- One alternative load configuration (`alternative`).
- The alternative configuration must explicitly specify:
  - Total mass.
  - CG displacement (`cg_offset`).
  - Inertia tensor.

- The CG displacement is defined as the alternative CG position minus the reference CG position, expressed in the global vehicle reference frame.

- The alternative inertia tensor is referred to its own CG, with axes parallel to the global reference axes.

- The alternative CG height is derived from its vertical displacement relative to the reference configuration.

- Static axle loads are derived from the mass and CG position of the corresponding configuration whenever the required data are available and the static equilibrium calculation is supported.

- Individual wheel loads are not calculated in v0.1.

- Loaded radii remain those specified for the reference configuration in v0.1. This is an approximation that neglects changes in tyre deformation due to variations in static wheel loads.

- Consequently, variations in body height and suspension position between load configurations are not modelled in v0.1.

- Automatic CG displacement calculation from individual component masses or load distributions is outside the scope of v0.1.

**Optional subsystems**

- General mechanism for optional vehicle subsystem blocks.
- Support for absent, partially specified and fully specified blocks.
- One minimal subsystem implementation as a test case: constant-coefficient aerodynamics.
- Aerodynamic calculations must require only the data needed by each individual function.
- The aerodynamic block stores the following independent parameters:
  - Drag coefficient (`Cd`).
  - Lift coefficient (`Cl`).
  - Reference area (`reference_area`).

- The lift coefficient (`Cl`) follows the global vertical axis convention:
  - Positive `Cl` produces an aerodynamic force in the positive global vertical direction (`+z`).
  - Negative `Cl` produces an aerodynamic force in the negative global vertical direction (`-z`), corresponding to downforce.

- The product of drag coefficient and reference area (`CdA`) is a derived quantity and is not stored as an independent parameter.

- Aerodynamic drag requires `Cd` and `reference_area`.

- Downforce requires `Cl` and `reference_area`.

- Air density and relative airspeed are operational inputs supplied to the aerodynamic calculation functions, not vehicle properties.

- Missing data required by a specific calculation must produce an identifiable missing-data error, without preventing calculations that have sufficient input data.

### 1.2. v0.2 and Future Releases — Deferred Features

The following features are intentionally deferred to subsequent development stages:

- Recursive component and assembly hierarchy.
- Component-level and assembly-level mass and inertia properties.
- Construction reference frames and hierarchical local reference frames.
- General rigid-body transformations and quaternion-based orientation management.
- Hardpoint management and component associations.
- Generic characteristic data structures for constants, curves, maps and experimental data.
- Advanced aerodynamic models and distributed aerodynamic loads.
- Detailed tyre model management and constitutive model validation.
- Static wheel-load distribution and individual wheel-load calculations.
- Detailed suspension and tyre stiffness modelling for static load distribution.
- Road profile and surface representation, including longitudinal profiles, three-dimensional road surfaces and individual wheel-track profiles.
- Import and export modules for Adams, Modelica, ANSYS, Simulink and other engineering software.
- CAD and experimental data integration.

Future road representations should allow the road height to be defined as a function of longitudinal and lateral coordinates, enabling the representation of uneven surfaces, bumps, potholes, banking and different profiles beneath individual wheels.

Future static wheel-load calculations may use additional physical information, such as suspension stiffness, anti-roll bar stiffness, tyre vertical stiffness and suspension preload, to determine the distribution of vertical loads between individual wheels.

### 1.3. Non-Goals of v0.1

The initial release is not intended to:

- Provide a general-purpose vehicle simulation environment.
- Implement vehicle dynamics solvers.
- Implement detailed suspension or steering kinematics.
- Implement tyre constitutive models or validate their model-specific parameters.
- Provide detailed aerodynamic modelling or CFD integration.
- Manage arbitrary component hierarchies.
- Implement road profiles or non-planar road surfaces.
- Calculate static vertical loads at individual wheels.
- Import native CAD models or engineering simulation files.
- Provide direct interoperability with external engineering software.
- Implement every possible vehicle subsystem.

These limitations apply to the initial release and do not necessarily restrict future development.

### 1.4. Design Principles

The initial data structure must remain extensible without requiring the implementation of future features in v0.1.

The JSON schema and MATLAB implementation should include only the fields and functionality required by the initial release, while avoiding design choices that would unnecessarily prevent future extensions.

The JSON file is the persistent data contract. It stores assigned values, while derived properties are calculated by dedicated MATLAB functions and are not written back as independent source data.

Each function should perform a clearly defined calculation and report missing required data through explicit, identifiable errors.

The implementation must distinguish between missing information, explicitly unknown values and physically meaningful zero values.

Geometry definition methods must be explicitly declared and validated. Parameters belonging exclusively to incompatible methods must not coexist.

Static equilibrium calculations must respect the limitations of the available physical information. In v0.1, static axle loads may be calculated for two-axle vehicles, but individual wheel loads are not derived.

### 1.5. Error Identifiers

The following identifiable error identifiers are defined for v0.1:

| Error identifier | Condition |
|---|---|
| `vehkit:missingData` | Required data are absent or explicitly unknown for a requested calculation. The error message must distinguish between absent and explicitly unknown data. |
| `vehkit:invalidJSONStructure` | The JSON document contains syntax or structural errors, duplicate or invalid property names, missing required fields, incompatible data types, or unrecognized fields. It also includes a missing or malformed `schema_version`. |
| `vehkit:unsupportedSchemaVersion` | The JSON file contains a formally valid but unsupported schema version. |
| `vehkit:conflictingGeometryDefinition` | Parameters exclusive to the geometry definition method not selected by `geometry.method` are present. |
| `vehkit:unsupportedAxleCount` | A `static_load_based` geometry definition or static equilibrium calculation is requested for a vehicle with a number of axles different from two. |
| `vehkit:wheelOrderMismatch` | Wheels within an axle are not ordered according to non-increasing global lateral coordinate, including the required secondary ordering criterion for identical coordinates. |
| `vehkit:invalidInertia` | The specified inertia tensor violates the applicable mathematical or physical validity conditions. |
| `vehkit:invalidParameter` | A parameter contains an invalid value, including non-finite values, values outside its permitted range, unknown values not permitted by the schema, invalid or duplicate identifiers, empty strings where prohibited, invalid enumeration values, or null values not permitted by the corresponding field definition. |
| `vehkit:axleOrderMismatch` | Axles are not ordered from front to rear according to their assigned longitudinal positions. |

Additional identifiers may be introduced when required by specific validation functions.

### 1.6. v0.1 Completion Criteria

The initial release is considered complete when both sets of criteria below are satisfied.

#### 1.6.1. Alpha exit criteria

1. Two reference JSON files (`road_car.json`, `race_car.json`) are stored in the repository and are the canonical examples referenced by the test suite.

2. The two reference vehicle definitions can be loaded successfully.

3. Both reference vehicle definitions pass structural validation and the physical validation checks available in alpha: mass and inertia, geometry (both `direct` and `static_load_based`), axle ordering and wheel ordering.

4. Invalid vehicle definitions are rejected with identifiable error messages, using only the error identifiers defined in §1.5 that are reachable in alpha.

5. Conflicting geometry parameters produce `vehkit:conflictingGeometryDefinition` (in `direct`, `geometry.wheelbase` or `geometry.front_weight_distribution` present; in `static_load_based`, `axles[].x` present).

6. Direct geometry supports vehicles with more than two axles.

7. Wheel ordering within each axle is verified, and invalid ordering produces `vehkit:wheelOrderMismatch`.

8. Wheel longitudinal positions are correctly inherited from their corresponding axle.

9. Derived geometric properties (wheelbase, track widths, CG-to-axle distances, wheel-centre positions) agree with independently calculated reference values.

10. Axle ordering is verified for the `direct` geometry method, and invalid ordering produces `vehkit:axleOrderMismatch`.

11. Inertia validation behaves correctly for complete and partially specified tensors.

12. Triangle inequalities on the diagonal components are verified whenever the complete diagonal is available, using `tol_triangle`.

13. Positive semidefiniteness is verified for complete inertia tensors using `tol_PSD`.

14. Invalid inertia properties produce `vehkit:invalidInertia`.

15. Invalid parameter values and out-of-range values produce `vehkit:invalidParameter`.

16. At least one test verifies the handling of missing required data, distinguishing absent from explicitly unknown data.

17. JSON loading, saving and reloading preserve all assigned data within the tolerances of §1.7.

18. Round-trip tests verify that absent, explicitly unknown and zero-valued data remain distinct after reload.

19. Schema version validation is tested: supported versions are loaded successfully; formally valid but unsupported versions produce `vehkit:unsupportedSchemaVersion`; missing or malformed versions produce `vehkit:invalidJSONStructure`.

20. Calculations requiring explicitly unknown data produce `vehkit:missingData`, with a message distinguishing unknown data from absent data.

21. The optional `tyre` block is loaded and preserved as-is, including in the round-trip.

22. `DATA.md` documents the sources and references used for both reference vehicles.

23. `README.md` provides an introduction to the project and includes an image illustrating the results.

24. The project build tool (`buildtool`) executes successfully.

25. The automated test suite passes successfully.

26. `static_load_based` geometry with an axle count different from two produces `vehkit:unsupportedAxleCount`.

27. A two-axle reference vehicle can be defined using both geometry methods with consistent input data.

28. The derived axle positions and geometric properties obtained through `direct` and `static_load_based` agree within the tolerances of §1.7.

29. Axle ordering in the `static_load_based` geometry method is accepted as declared by the axle structure.

30. `geometry.wheelbase` and `geometry.front_weight_distribution` are required when `geometry.method` is `static_load_based`; their absence produces `vehkit:invalidJSONStructure`.

31. `front_weight_distribution` outside the interval `(0, 1)` produces `vehkit:invalidParameter`.

#### 1.6.2. v0.1 release criteria (additional to alpha)

1. Alternative load configurations preserve the assigned CG displacement and inertia reference.

2. Static axle loads are correctly calculated for supported two-axle configurations, using `g = 9.80665 m/s^2`.

3. No function provided in v0.1 derives individual wheel loads.

4. Optional subsystem handling is tested for absent, partially specified and fully specified blocks.

5. Aerodynamic calculations are independently tested for drag and downforce, including cases with insufficient data for one calculation but sufficient data for another.

6. The minimal constant-coefficient aerodynamic implementation passes its tests.

7. Aerodynamic force direction is verified for both positive and negative lift coefficients.

### 1.7. Numerical Tolerances

The following numerical tolerances are used throughout the MATLAB implementation and automated tests.

- Absolute tolerance: `atol = 1e-10`.
- Relative tolerance: `rtol = 1e-8`.
- General comparison criterion:

  `abs(a - b) <= atol + rtol * max(abs(a), abs(b))`.

- Positive semidefiniteness tolerance:

  `tol_PSD = atol + rtol * norm(I, 2)`,

  where `I` is the complete inertia tensor and `norm(I, 2)` is its spectral norm.

- Diagonal-component triangle inequality tolerance:

  `tol_triangle = atol + rtol * norm(diag(Ixx, Iyy, Izz), 2)`,

  where the diagonal components are available.