# Project Conventions

## 1. Reference frame

All vehicle models use a right-handed Cartesian reference frame:

- **x-axis:** longitudinal, positive towards the front of the vehicle.
- **y-axis:** lateral, positive towards the left side of the vehicle.
- **z-axis:** vertical, positive upwards.

Positive rotations follow the right-hand rule:

- **Roll (+x):** positive rotation causes the right side of the vehicle to move downwards.
- **Pitch (+y):** positive rotation corresponds to a nose-down rotation.
- **Yaw (+z):** positive rotation corresponds to a left turn.

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

Unless otherwise specified, the global reference-frame origin is located at the vehicle's center of gravity (CG), under static equilibrium.

The reference loading condition, including the presence of the driver and the fuel load, must be explicitly documented for each vehicle.

The reference CG refers to the complete vehicle, including both sprung and unsprung masses. The CG of the sprung masses is a separate physical quantity and must be identified explicitly when used.

The global reference frame remains fixed to the reference CG. Changes in loading conditions may therefore result in a displacement of the actual vehicle CG relative to the global origin.

Local reference frames may be introduced when required by individual models. Their origins and orientations must always be explicitly documented.

The tire reference frame and its conventions will be documented separately in Project 3, which covers tire modeling using the Magic Formula 6.1 (MF61) and the TYDEX coordinate system.