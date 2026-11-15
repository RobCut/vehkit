# Data Sources and Notes

This file documents the origin of the vehicle parameters used in the
canonical JSON files under `data/`. It distinguishes between values
anchored to public sources, values estimated from standard engineering
references, and values constructed within plausible ranges.

No proprietary or confidential data from Formula SAE, TTC, university
projects, or team material is used. All values are either public,
published, or constructed from scratch.

## data/road_car.json

A generic segment C passenger car (Golf/Focus class, front-wheel drive).

| Parameter | Value | Origin |
|---|---|---|
| Wheelbase | 2.65 m | Typical segment C value, cross-checked against CommonRoad BMW 320i (2.81 m) and similar vehicles |
| Front track | 1.53 m | Typical segment C value |
| Rear track | 1.51 m | Typical segment C value |
| CG height | 0.56 m | Typical for a passenger car; Previati et al. 2024 (World Electric Vehicle Journal 15, 266) provide empirical estimates for electric vehicles |
| Reference mass | 1385 kg | Approximate kerb weight 1300 kg + 75 kg driver + 10 kg fuel |
| Inertia Ixx | 470 kg·m² | Estimated from typical roll inertia of a 1.4-tonne passenger car |
| Inertia Iyy | 1900 kg·m² | Estimated from typical pitch inertia |
| Inertia Izz | 2200 kg·m² | Estimated from typical yaw inertia |
| Loaded radius | 0.31 m | Typical for a 205/55 R16 tyre under static load |

Inertia values satisfy the triangle inequalities and are positive
definite. They are estimated, not measured.

## data/race_car.json

A Formula SAE-style single-seater (rear-wheel drive, 13-inch wheels).

| Parameter | Value | Origin |
|---|---|---|
| Wheelbase | 1.55 m | Typical FSAE wheelbase (1.5-1.6 m range in published designs) |
| Front track | 1.20 m | Typical FSAE front track |
| Rear track | 1.18 m | Typical FSAE rear track |
| CG height | 0.32 m | Typical FSAE CG height (0.28-0.35 m range in published designs) |
| Reference mass | 280 kg | Approximate car weight 205 kg + 75 kg driver |
| Inertia Ixx | 80 kg·m² | Estimated from typical FSAE roll inertia |
| Inertia Iyy | 120 kg·m² | Estimated from typical FSAE pitch inertia |
| Inertia Izz | 150 kg·m² | Estimated from typical FSAE yaw inertia |
| Loaded radius | 0.20 m | Typical for 10-inch FSAE slick under static load |

Inertia values satisfy the triangle inequalities and are positive
definite. They are estimated within plausible ranges, not measured.

## General notes

- **Coordinate system**: see `docs/CONVENTIONS.md`. Origin at the CG of
  the reference load configuration, x forward, y left, z up.
- **Reference load configuration**: includes driver and fuel. A vehicle
  without driver or fuel would be represented as an alternative load
  configuration (deferred to the release scope).
- **Loaded radius**: vertical distance from wheel centre to road surface
  under static reference load. Not the unloaded geometric radius.
- **Geometry method**: both files use `direct` geometry (axle positions
  assigned directly). `static_load_based` geometry is deferred.
- **Inertia convention**: off-diagonal elements are the matrix elements
  directly, without sign change (see `docs/SCHEMA.md` §8.7).

## References

- CommonRoad Vehicle Models:
  https://pypi.org/project/commonroad-vehicle-models/
  Used as a cross-check for segment C dimensions. BSD license (per
  package index metadata).
- Previati, G., et al. (2024). "Empirical estimation of center of gravity
  height and moments of inertia for electric vehicles." World Electric
  Vehicle Journal 15(6), 266. CC BY.
  Used as a reference for realistic CG height and inertia ranges.
- General FSAE design literature (publicly available team reports and
  SAE papers) used as a sanity check for FSAE dimensions.

No data from proprietary sources is used.
