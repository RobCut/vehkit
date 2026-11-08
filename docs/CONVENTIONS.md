# Project Conventions

## 1. Reference frame

All vehicle models use a right-handed Cartesian reference frame:

- **x-axis:** longitudinal, positive towards the front of the vehicle.
- **y-axis:** lateral, positive towards the left side of the vehicle.
- **z-axis:** vertical, positive upwards.

Positive rotations follow the right-hand rule. In particular, positive pitch corresponds to a nose-down rotation about the positive y-axis.

Consequently, downwards vertical displacements are negative.

## 2. Units

All physical quantities are expressed exclusively in the International System of Units (SI).

| Quantity | Unit |
|---|---|
| Length | m |
| Mass | kg |
| Time | s |
| Force | N |
| Moment | N·m |
| Velocity | m/s |
| Acceleration | m/s² |
| Angle | rad |

## 3. Coordinate origin

Unless otherwise specified, the global reference-frame origin is located at the vehicle's center of gravity (CG), under static conditions.

Local reference frames may be introduced when required by individual models. Their origins and orientations must always be explicitly documented.