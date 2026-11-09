# JSON Schema Specification

## 1. Scope and Conventions

### 1.1. Scope

This document defines the JSON data format used by vehkit to represent vehicle data.

It specifies:
- JSON structure and field names;
- data types and dimensions;
- mandatory and optional fields;
- nullability and unknown-value representation;
- validation constraints;
- collection normalization;
- identifier format and ordering;
- loading and serialization rules;
- error classification.

The JSON schema defines the external data contract. It is independent of the internal MATLAB representation.

Schema version `0.1` is considered complete only when the following vehicle data blocks are defined:
- mass and inertia;
- load configurations;
- aerodynamics;
- geometry, axles, wheels, and tyre parameters.

The schema and loader validation rules must not be considered frozen until all these blocks have been specified.

Unrecognized fields are rejected in all blocks whose structure is defined by this schema. Consequently, all fields required by the `0.1` completion criteria must be included before the loader is finalized.

### 1.2. Units and Coordinate Conventions

All physical quantities use SI units.

Units are documented for each field and are not included in field names.

Coordinate conventions and reference systems are defined in `CONVENTIONS.md`.

### 1.3. Unknown Values

Unknown numerical values are represented by JSON `null` and internally by MATLAB `NaN`.

A numerical field must explicitly specify whether unknown values are permitted.

Missing fields and unknown values are distinct:
- a missing field is not present in the JSON object;
- an unknown field value is represented by `null`;
- an explicit numerical zero is a known value.

The conversion and nullability rules are defined in Section 4.1.

### 1.4. Field Names

Field names outside the reserved tyre parameter block must use lowercase ASCII letters, digits, and underscores.

Every field name must satisfy:

`^[a-z][a-z0-9_]*$`

Field names are case-sensitive.

The reserved tyre parameter block follows the specific rules defined in Section 3.1.

### 1.5. Error Identifiers

The public error identifiers and their descriptions are defined in `DESIGN.md`, Section 1.5.

This document specifies which validation conditions produce each error identifier.

---

## 2. Root Structure

The JSON document root must be an object.

The root object must contain `schema_version`.

The `schema_version` field must be a string matching:

`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$`

The currently supported schema version is:

`"0.1"`

The optional vehicle-level `tyre` block is defined in Section 7.4.

Version handling follows these rules:

| Condition | Error identifier |
|---|---|
| Root is not a JSON object | `vehkit:invalidJSONStructure` |
| `schema_version` is missing | `vehkit:invalidJSONStructure` |
| `schema_version` is not a string | `vehkit:invalidJSONStructure` |
| `schema_version` does not match the required format | `vehkit:invalidJSONStructure` |
| Version is valid but unsupported | `vehkit:unsupportedSchemaVersion` |

The schema version is checked before complete field validation.

---

## 3. Loading and Validation Order

### 3.1. JSON Scanner

Before calling `jsondecode`, the input text must be processed by an internal scanner.

The scanner performs a single pass over the original JSON text.

It is responsible for:
- checking the first significant character;
- checking JSON string termination and escape sequences;
- checking bare literals;
- rejecting forbidden numerical tokens;
- identifying object keys;
- validating key names;
- detecting duplicate keys recursively;
- tracking the complete JSON property path;
- applying the specific key and value restrictions of the reserved tyre parameter block.

The first significant character, ignoring JSON whitespace and a UTF-8 BOM if present, must be `{`.

If this condition is not met, loading stops immediately with `vehkit:invalidJSONStructure`.

#### String handling

The scanner distinguishes strings from the structural JSON syntax.

A quotation mark opens or closes a string. A backslash activates an escape flag, causing the next character to be skipped for structural interpretation.

An unterminated string produces `vehkit:invalidJSONStructure`.

A string followed, after optional whitespace, by `:` is identified as an object key.

Strings used as values are not subject to key-name validation.

#### Bare literals

Outside strings, the only permitted bare literals are:
- `true`;
- `false`;
- `null`.

Other bare words and non-standard numerical tokens are rejected.

Examples of forbidden tokens include:
- `NaN`;
- `nan`;
- `Infinity`;
- `-Infinity`;
- `inf`;
- `+Infinity`.

Numerical syntax is validated by `jsondecode`.

The scanner must recognize exponent notation: an `e` or `E` immediately following a digit or decimal point belongs to the numerical token.

#### Object keys and duplicate detection

The scanner maintains:
- a stack of open containers;
- a separate set of previously encountered keys for each object;
- the complete property path associated with each open container.

This allows duplicate keys to be detected independently within each object, including nested objects.

The same key may occur in different objects.

Outside the reserved tyre parameter block, every original key must satisfy:

`^[a-z][a-z0-9_]*$`

Validation is performed on the raw JSON key, before any transformation by MATLAB.

Consequently:
- empty keys are rejected;
- uppercase characters are rejected;
- spaces and hyphens are rejected;
- escape sequences are not permitted in keys;
- keys that MATLAB could transform through `makeValidName` are rejected;
- duplicate keys are rejected.

The scanner must detect duplicate keys using their original textual representation. Since escape sequences are forbidden in keys outside the reserved tyre parameter block, escaped and unescaped representations cannot be used to disguise duplicate names.

#### Reserved tyre parameter block

The reserved tyre parameter block is located exclusively at the following root-level JSON path:

`tyre.parameters`

The scanner must track the complete JSON property path to identify this object.

The special tyre parameter rules apply only when:
- `tyre` is a direct property of the root object;
- `parameters` is a direct property of that `tyre` object.

The same property name at another path must not activate the tyre-specific rules.

For example, the following object is not a tyre parameter block:

`{"geometry":{"parameters":{"Cd":1}}}`

The `tyre.parameters` block is a vehicle-level block and is defined in Section 7.4.

Its keys follow different rules because tyre model parameter names may contain uppercase characters.

Every key inside `tyre.parameters`, including keys in nested objects, must:
- match `^[A-Za-z][A-Za-z0-9_]*$`;
- not exceed MATLAB's `namelengthmax`;
- not be a MATLAB keyword, as determined by `iskeyword`.

The scanner must reject duplicate keys recursively within this block.

JSON `null` values are not permitted anywhere inside `tyre.parameters`, including nested objects and arrays.

The scanner does not apply the general lowercase key pattern to this block.

The tyre parameter block is preserved as the value decoded by MATLAB `jsondecode`, subject to these restrictions. It is not preserved as identical source text.

Arrays containing a single element are permitted. If MATLAB `jsondecode` converts a single-element array into a scalar, the decoded scalar is the value preserved by vehkit.

All numerical values inside `tyre.parameters`, including values nested within objects or arrays, must be finite.

`NaN`, `Inf`, and `-Inf` are invalid and produce `vehkit:invalidParameter`.

This numerical validation is performed after JSON decoding.

The same restriction is checked before serialization.

The scanner must not apply the tyre-specific key rules to other parts of the JSON document.

All scanner violations produce `vehkit:invalidJSONStructure`.

#### Scanner test cases

The following cases must be covered by scanner and loading tests:

| Input | Expected result |
|---|---|
| `{"a":1,"a":2}` | Rejected: duplicate key |
| `{"a":{"b":1,"b":2}}` | Rejected: nested duplicate key |
| `{"a":{"b":1},"c":{"b":2}}` | Accepted: same key in different objects |
| `{"x ":5}` | Rejected: invalid key name |
| `{"loaded-radius":1}` | Rejected: invalid key name |
| `{"":1}` | Rejected: empty key |
| `{"\u0061":1,"a":2}` | Rejected: escaped key |
| `{"Cd":1}` | Rejected: invalid key name |
| `{"note":"loaded-radius"}` | Accepted: string value |
| `{"a":"x:"}` | Accepted: colon inside string value |
| `{"tyre":{"parameters":{"PCX1":1.5}}}` | Accepted: tyre parameter key |
| `{"geometry":{"parameters":{"Cd":1}}}` | Rejected: invalid key name |
| `{"tyre":{"parameters":{"A":{"A":1,"A":2}}}}` | Rejected: nested duplicate key |
| `{"tyre":{"parameters":{"end":1}}}` | Rejected: MATLAB keyword |
| `{"tyre":{"parameters":{"x":1e999}}}` | Rejected: non-finite numerical value |

### 3.2. JSON Decoding

After successful scanning, the JSON text is passed to MATLAB `jsondecode`.

Any decoding exception is rethrown as:

`vehkit:invalidJSONStructure`

The original MATLAB exception must be preserved as the cause of the public exception.

### 3.3. Root Validation

After decoding, the root must be a scalar MATLAB struct.

The root must contain `schema_version`.

Failure produces `vehkit:invalidJSONStructure`.

### 3.4. Schema Version Validation

The schema version is validated before the remaining fields.

A syntactically valid but unsupported version produces:

`vehkit:unsupportedSchemaVersion`

### 3.5. Structural and Value Normalization

After schema version validation, loading proceeds in the following order:

1. Recursively normalize the shape of all defined collections.
2. Validate field presence, JSON-derived MATLAB types, and dimensions. An empty numerical scalar (`[]`) must be accepted at this stage as a possible representation of JSON `null`.
3. Convert empty numerical scalar values (`[]`) to `NaN`.
4. Validate nullability for all numerical scalar fields.
5. Validate numerical constraints, including finiteness of known values.
6. Complete semantic and cross-field validation in the following order:
   - validate mandatory and mutually exclusive fields;
   - validate conditional field requirements;
   - validate the number of axles;
   - validate axle and wheel ordering;
   - complete the remaining semantic checks.

The detailed rules for numerical normalization are defined in Section 4.1.

Collection normalization is defined in Section 4.3.

The order of these operations is significant.

In particular, for `static_load_based` geometry, field presence and method conflicts are checked before axle count. Axle count is checked before axle ordering.

---

## 4. Data Representation

### 4.1. Numerical Values

Numerical fields are represented using JSON numbers.

Unknown numerical scalar values are represented using JSON `null`.

MATLAB `jsondecode` converts JSON `null` into an empty numerical array (`[]`).

For every numerical scalar field, an empty value is converted to `NaN`, regardless of the field's nullability.

This conversion takes place before nullability validation.

Consequently:
- `null` in a nullable numerical scalar field becomes `NaN` and is accepted;
- `null` in a non-nullable numerical scalar field becomes `NaN` and produces `vehkit:invalidParameter`;
- an explicit zero remains zero;
- an absent field remains absent.

For numerical vectors, JSON `null` elements are decoded as `NaN` by MATLAB.

The nullability of a vector is defined per component. Each component must comply with the nullability rule specified for that field.

All known numerical values in defined fields must be finite.

`Inf` and `-Inf` are invalid, including values resulting from numerical overflow during JSON decoding.

`NaN` is accepted only where unknown values are explicitly permitted.

The additional finiteness restrictions for `tyre.parameters` are defined in Section 3.1.

### 4.2. Strings

String fields are represented using JSON strings.

An empty string is distinct from:
- an absent field;
- a JSON `null` value.

An empty string is accepted only when explicitly permitted by the field definition.

Otherwise, it produces `vehkit:invalidParameter`.

A JSON `null` supplied for a string field is decoded by MATLAB as an empty numerical array. Since this is incompatible with the declared string type, it produces `vehkit:invalidJSONStructure`.

### 4.3. Arrays and Collections

JSON arrays are used for ordered collections and numerical vectors.

Empty arrays are not permitted for vectors or collections.

A single object representing an axle or wheel is accepted as a collection containing one element.

The following MATLAB representations are accepted as collection inputs:
- cell arrays;
- N-by-1 struct arrays;
- scalar structs.

Collections are normalized recursively into N-by-1 cell arrays containing scalar structs.

An element that is not a scalar struct produces `vehkit:invalidJSONStructure`.

The order of collection elements is significant.

### 4.4. Vector Dimensions

Vectors with three components must be represented internally as 3-by-1 column vectors.

A vector with an incorrect number of components produces `vehkit:invalidJSONStructure`.

Nullability is specified independently for each component.

---

## 5. Identifier Format and Ordering

### 5.1. Identifier Format

Identifiers must match:

`^[a-z]+(?:_[a-z]+)*_[1-9][0-9]*$`

Identifiers consist of:
- one or more lowercase alphabetic components;
- components separated by underscores;
- a final positive integer suffix.

Examples:

| Identifier | Valid |
|---|---|
| `wheel_1` | Yes |
| `front_wheel_2` | Yes |
| `wheel_10` | Yes |
| `wheel_0` | No |
| `wheel_01` | No |
| `wheel_a` | No |
| `Wheel_1` | No |
| `wheel__1` | No |

Invalid identifiers produce `vehkit:invalidParameter`.

### 5.2. Uniqueness

Axle identifiers must be unique throughout the vehicle.

Wheel identifiers must also be unique throughout the vehicle, independently of their parent axle.

Axle and wheel identifiers belong to separate namespaces.

Duplicate identifiers produce `vehkit:invalidParameter`.

### 5.3. Canonical Identifier Ordering

Canonical identifier ordering is defined by:
1. the textual prefix before the final underscore;
2. the numerical value of the final suffix.

Prefixes are compared using ordinal ASCII ordering, independently of locale.

If one prefix is the beginning of another, the shorter prefix comes first.

The final numerical suffix is compared as an integer, not as text.

Examples:

| Input | Canonical order |
|---|---|
| `wheel_2`, `wheel_10` | `wheel_2`, `wheel_10` |
| `front_wheel_1`, `wheel_1` | `front_wheel_1`, `wheel_1` |
| `a_b_1`, `ab_1` | `a_b_1`, `ab_1` |
| `wheel_1`, `wheel_a_1` | `wheel_1`, `wheel_a_1` |

Canonical identifier ordering is used only to verify wheel ordering when two or more wheels have the same lateral coordinate `y`.

The loader does not reorder identifiers or collection elements.

The order in the JSON file must already comply with the canonical ordering rules.

---

## 6. Validation Rules

### 6.1. General Rules

- Mandatory fields must be present.
- Optional fields may be absent.
- Absent fields remain absent.
- Unknown numerical values are permitted only for nullable fields.
- Known numerical values must satisfy the specified constraints.
- Empty strings are permitted only when explicitly specified.
- Empty vectors and collections are invalid.
- Unrecognized fields are rejected in all blocks whose structure is defined by this schema.
- The reserved tyre parameter block may contain unrecognized parameters, subject to Section 3.1.
- All cross-field constraints must be validated.

### 6.2. Axles and Wheels

The `axles` collection is mandatory.

At least one axle must be defined.

Each axle must contain at least one wheel.

The `wheels` collection is mandatory for each axle.

Axles must be ordered from front to rear.

Wheels within each axle must be ordered from left to right, according to non-increasing lateral coordinate `y`.

When multiple wheels have the same `y` coordinate, their canonical identifier ordering is used.

The loader does not reorder axles or wheels. It verifies that the order in the JSON file already complies with the required ordering.

Ordering violations produce:
- `vehkit:axleOrderMismatch` for axles;
- `vehkit:wheelOrderMismatch` for wheels.

The definitions of these errors are provided in `DESIGN.md`, Section 1.5.

### 6.3. Geometry

The geometry block defines the method used to establish the vehicle's longitudinal geometry.

The `geometry.method` field is mandatory and accepts the following values:
- `direct`;
- `static_load_based`.

An incompatible JSON type produces `vehkit:invalidJSONStructure`.

A string outside the supported enumeration produces `vehkit:invalidParameter`.

#### 6.3.1. Direct Method

When `geometry.method` is `direct`:
- each axle must provide its longitudinal coordinate through `axles[].x`;
- the coordinate is mandatory and cannot be unknown;
- axles must be ordered from front to rear;
- the ordering is verified using their longitudinal coordinates;
- `geometry.wheelbase` must not be present;
- `geometry.front_weight_distribution` must not be present.

The wheelbase can be derived from the longitudinal coordinates of the first and last axles:

$$
L=x_{\mathrm{front}}-x_{\mathrm{rear}}
$$

The derived value may be used internally but must never be serialized.

The direct method supports vehicles with one or more axles.

For a vehicle with a single axle, the derived wheelbase is zero. This is an accepted case and does not produce a validation error.

#### 6.3.2. Static Load-Based Method

When `geometry.method` is `static_load_based`:
- the vehicle must have exactly two axles;
- the axle array must be ordered from front to rear;
- `geometry.wheelbase` is mandatory and non-nullable;
- `geometry.front_weight_distribution` is mandatory and non-nullable;
- `axles[].x` must not be present.

The front weight distribution is defined as the fraction of the total static vehicle weight supported by the front axle, exclusively for the `reference` configuration.

It is a dimensionless fraction, not a percentage.

$$
\lambda =
\frac{F_{\mathrm{front,static}}}
{F_{\mathrm{total,static}}}
$$

Its constraint is:

$$
0<\lambda<1
$$

The rear axle supports the remaining fraction:

$$
\lambda_{\mathrm{rear}}=1-\lambda
$$

The longitudinal origin is located at the centre of gravity of the reference configuration.

The axle coordinates are reconstructed as:

$$
x_{\mathrm{front}}=(1-\lambda)L
$$

$$
x_{\mathrm{rear}}=-\lambda L
$$

where \(L\) is the wheelbase.

#### 6.3.3. Common Geometry Parameters

`geometry.cg_height` is common to both methods.

It represents the height of the vehicle centre of gravity above the road surface.

The field is mandatory but nullable.

When known, its value must be positive.

#### 6.3.4. Method Exclusivity and Validation Precedence

The two geometry methods define mutually exclusive representations.

The following fields are forbidden depending on the selected method:

| Selected method | Forbidden field |
|---|---|
| `direct` | `geometry.wheelbase` |
| `direct` | `geometry.front_weight_distribution` |
| `static_load_based` | `axles[].x` |

The presence of a forbidden field produces `vehkit:conflictingGeometryDefinition`, regardless of its value.

Geometry validation follows this precedence:

1. Validate the presence of mandatory and conditional fields and check method-exclusive fields.
2. Validate the number of axles required by the selected method.
3. Validate axle ordering.
4. Complete the remaining geometry value and consistency checks.

This precedence ensures that a vehicle using `static_load_based` geometry with three axles and an `axles[].x` field is rejected first for the conflicting geometry definition.

The missing-field, nullability, axle-count, and ordering errors are classified in Section 7.

### 6.4. Tyre Parameters

The tyre block is optional and is defined at vehicle level.

Its structure is:

| Field | Type | Required | Nullable | Constraints |
|---|---|---|---|---|
| `tyre` | object | No | No | Must follow this section |
| `tyre.model` | string | Yes, if `tyre` is present | No | Non-empty model identifier |
| `tyre.parameters` | object | Yes, if `tyre` is present | No | Model-specific parameter object |

An empty `tyre.model` string is not permitted and produces `vehkit:invalidParameter`.

Schema version `0.1` supports a single tyre model and parameter set at vehicle level.

The same tyre model and parameter set therefore apply to all wheels.

Per-axle or per-wheel tyre model overrides are not supported.

Supporting different front and rear tyre models requires a future schema extension.

The initial implementation does not perform model-specific validation of tyre parameters.

Model-specific interpretation and validation are deferred to the tyre-model project.

The `tyre.parameters` object may contain unrecognized fields.

Its keys must comply with the MATLAB identifier restrictions defined in Section 3.1.

Duplicate keys and `null` values are prohibited.

All numerical values inside `tyre.parameters` must be finite. Non-finite values produce `vehkit:invalidParameter`.

The parameter block is preserved as decoded by `jsondecode`. It is not guaranteed to retain the original JSON textual representation.

In particular, a single-element JSON array may be decoded as a scalar and subsequently serialized as a scalar.

No unit conversion or model-specific numerical interpretation is performed by vehkit v0.1.

---

## 7. Error Classification

The following table summarizes the error conditions defined by the schema.

| Condition | Error identifier |
|---|---|
| Invalid JSON syntax | `vehkit:invalidJSONStructure` |
| Forbidden bare token in JSON text | `vehkit:invalidJSONStructure` |
| Unterminated JSON string | `vehkit:invalidJSONStructure` |
| Duplicate object key | `vehkit:invalidJSONStructure` |
| Invalid key name | `vehkit:invalidJSONStructure` |
| Invalid tyre parameter key | `vehkit:invalidJSONStructure` |
| Duplicate tyre parameter key | `vehkit:invalidJSONStructure` |
| Null value inside tyre parameters | `vehkit:invalidJSONStructure` |
| Root is not an object | `vehkit:invalidJSONStructure` |
| Missing `schema_version` | `vehkit:invalidJSONStructure` |
| Invalid `schema_version` type or format | `vehkit:invalidJSONStructure` |
| Unsupported schema version | `vehkit:unsupportedSchemaVersion` |
| Missing mandatory field | `vehkit:invalidJSONStructure` |
| Missing conditional mandatory field | `vehkit:invalidJSONStructure` |
| Incompatible JSON type | `vehkit:invalidJSONStructure` |
| Invalid vector dimension | `vehkit:invalidJSONStructure` |
| Invalid collection structure | `vehkit:invalidJSONStructure` |
| Empty vector or collection | `vehkit:invalidJSONStructure` |
| Unrecognized field in a defined block | `vehkit:invalidJSONStructure` |
| Invalid numerical value | `vehkit:invalidParameter` |
| Unknown value in a non-nullable numerical field | `vehkit:invalidParameter` |
| Infinite numerical value in a defined field | `vehkit:invalidParameter` |
| Non-finite numerical value inside tyre parameters | `vehkit:invalidParameter` |
| Invalid identifier format | `vehkit:invalidParameter` |
| Duplicate identifier | `vehkit:invalidParameter` |
| Invalid enumeration value | `vehkit:invalidParameter` |
| Empty string where not permitted | `vehkit:invalidParameter` |
| Null value in a non-nullable numerical scalar field | `vehkit:invalidParameter` |
| Conflicting geometry definitions | `vehkit:conflictingGeometryDefinition` |
| Unsupported axle count for `static_load_based` | `vehkit:unsupportedAxleCount` |
| Axle ordering violation | `vehkit:axleOrderMismatch` |
| Wheel ordering violation | `vehkit:wheelOrderMismatch` |
| Required calculation data absent or unknown | `vehkit:missingData` |

### 7.1. Structural Errors and Missing Calculation Data

A distinction must be maintained between schema validation and calculation requirements.

A mandatory field missing from the JSON document is a structural error and produces `vehkit:invalidJSONStructure`.

A field that is present but contains an unknown value may be valid according to the schema if it is nullable.

If a calculation requires that value, the calculation produces `vehkit:missingData`.

The library must distinguish absent data from unknown data.

---

## 8. Field Reference

Each field definition specifies:
- JSON path;
- data type;
- dimensions, where applicable;
- mandatory or optional status;
- nullability;
- physical unit, where applicable;
- numerical or textual constraints;
- conditional requirements;
- applicable validation rules.

### 8.1. Root Fields

| Field | Type | Required | Nullable | Constraints |
|---|---|---|---|---|
| `schema_version` | string | Yes | No | Must match the version format defined in Section 2 |

### 8.2. Geometry Fields

| Field | Type | Required | Nullable | Unit | Constraints |
|---|---|---|---|---|---|
| `geometry` | object | Yes | No | — | Must follow Section 6.3 |
| `geometry.method` | string | Yes | No | — | `direct` or `static_load_based` |
| `geometry.cg_height` | scalar numeric | Yes | Yes | m | Positive if known |
| `geometry.wheelbase` | scalar numeric | Conditional | No | m | Required for `static_load_based`; positive |
| `geometry.front_weight_distribution` | scalar numeric | Conditional | No | — | Required for `static_load_based`; fraction satisfying `0 < λ < 1` |

### 8.3. Axle Fields

| Field | Type | Required | Nullable | Unit | Constraints |
|---|---|---|---|---|---|
| `axles` | collection of objects | Yes | No | — | At least one axle; ordered front-to-rear |
| `axles[].id` | string | Yes | No | — | Valid identifier; unique throughout the vehicle |
| `axles[].x` | scalar numeric | Conditional | No | m | Required for `direct`; finite |

`axles[].x` must be absent when the selected geometry method is `static_load_based`.

### 8.4. Wheel Fields

| Field | Type | Required | Nullable | Unit | Constraints |
|---|---|---|---|---|---|
| `axles[].wheels` | collection of objects | Yes | No | — | At least one wheel per axle |
| `axles[].wheels[].id` | string | Yes | No | — | Valid identifier; unique throughout the vehicle |
| `axles[].wheels[].y` | scalar numeric | Yes | No | m | Finite; used to verify left-to-right ordering |
| `axles[].wheels[].loaded_radius` | scalar numeric | Yes | Yes | m | Positive if known |

Wheels must be ordered by non-increasing `y`.

When two or more wheels have the same `y`, their canonical identifier ordering must be respected.

### 8.5. Tyre Fields

| Field | Type | Required | Nullable | Constraints |
|---|---|---|---|---|
| `tyre` | object | No | No | Vehicle-level optional block |
| `tyre.model` | string | Yes, if `tyre` is present | No | Non-empty model identifier |
| `tyre.parameters` | object | Yes, if `tyre` is present | No | Uninterpreted model-specific parameters |

The key and value restrictions for `tyre.parameters` are defined in Section 3.1.

---

## 9. Serialization

### 9.1. Validation Before Serialization

The internal vehicle data must be validated before calling `jsonencode`.

Serialization must not be used as a substitute for validation.

All fields must comply with their declared types, dimensions, nullability, and constraints before encoding.

### 9.2. Unknown Numerical Values

`NaN` is permitted only in numerical fields declared nullable.

During JSON serialization, `NaN` is encoded as JSON `null`.

A `NaN` value in a non-nullable field must be rejected before calling `jsonencode` and produces `vehkit:invalidParameter`.

`Inf` and `-Inf` are always rejected before serialization because MATLAB `jsonencode` encodes non-finite values as `null`.

Non-finite numerical values inside `tyre.parameters` are also rejected before serialization and produce `vehkit:invalidParameter`.

### 9.3. Missing Fields

Fields absent from the internal vehicle structure remain absent in the serialized JSON document.

Missing fields must not be inserted as JSON `null`.

### 9.4. Collection Serialization

Collections must always be serialized as JSON arrays.

This rule also applies to collections containing a single element.

A single axle or wheel must therefore be written as a one-element JSON array, not as a standalone JSON object.

### 9.5. Derived Values

Derived values must never be serialized.

Only explicitly stored vehicle data is written to the JSON document.

For example, the wheelbase derived from axle coordinates when using `direct` geometry is not serialized.

### 9.6. Tyre Parameter Serialization

The tyre parameter block is serialized from the value decoded and preserved internally.

Its serialization is not guaranteed to reproduce the original JSON text identically.

In particular, MATLAB may serialize a value decoded from a single-element array as a scalar.

The restrictions defined in Section 3.1, including the prohibition of null and non-finite numerical values, apply before serialization.

### 9.7. JSON File Encoding and Formatting

JSON files must be written using:
- UTF-8 encoding;
- no UTF-8 BOM;
- `PrettyPrint` enabled;
- a final newline character.

Pretty printing is required to keep version-controlled JSON files readable and suitable for reviewing changes.

Numerical round-trip comparisons use the following tolerances:

`rtol = 1e-8`

The absolute tolerance is defined in `DESIGN.md`.

---

## 10. JSON Examples

Valid and invalid JSON examples will be added after completion of the field reference.

Examples must illustrate:
- a minimal valid vehicle;
- a vehicle using `direct` geometry;
- a vehicle using `static_load_based` geometry;
- nullable numerical values;
- multiple axles and wheels;
- the reserved tyre parameter block;
- invalid structures and values;
- serialization of single-element collections;
- non-finite tyre parameter rejection;
- the distinction between missing and unknown values.