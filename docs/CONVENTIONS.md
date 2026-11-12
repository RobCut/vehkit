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
Forces are positive in the direction of the corresponding axis. Moments follow the same right-hand rule as rotations.

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
| Mass moment of inertia | kg·m² |
| Density | kg/m³ |
| Angular velocity | rad/s |
| Angular acceleration | rad/s² |
| Stiffness | N/m |
| Damping | N·s/m |

## 3. Coordinate origin

Unless otherwise specified, the global reference-frame origin is located at the vehicle's center of gravity (CG), under static equilibrium.

The road surface is assumed to be flat, horizontal and common to all wheels in v0.1. Its position in the global reference frame is `z_road = -h_CG`, where `h_CG` is the vehicle CG height above the road surface.

When the loading condition changes, the global reference frame does not move. The alternative CG is expressed as a displacement from the reference CG in the global frame.

The reference loading condition, including the presence of the driver and the fuel load, must be explicitly documented for each vehicle.

The reference mass includes the driver and the fuel load. A vehicle without driver or fuel is represented as an alternative load configuration, not as a different vehicle.

The reference CG refers to the complete vehicle, including both sprung and unsprung masses. The CG of the sprung masses is a separate physical quantity and must be identified explicitly when used.

The global reference frame remains fixed to the reference CG. Changes in loading conditions may therefore result in a displacement of the actual vehicle CG relative to the global origin.

Local reference frames may be introduced when required by individual models. Their origins and orientations must always be explicitly documented.

The tire reference frame and its conventions will be documented separately in Project 3, which covers tire modeling using the Magic Formula 6.1 (MF61) and the TYDEX coordinate system.

**Interface with external software.** Adams, Ansys and SolidWorks can use a global frame with a different origin. When exporting to or importing from these tools, apply a rigid translation of `h_CG` along the global z-axis. The vertical axis (+z up) is consistent with Adams and Ansys; SolidWorks can be configured to Z-up or rotated on export.