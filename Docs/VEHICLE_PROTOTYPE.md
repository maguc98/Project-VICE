# Vehicle prototype

## Current implementation

The first drivable vehicle is a lightweight arcade sedan blockout. It is deliberately not a Chaos Vehicles implementation yet: movement uses swept kinematic movement of a box collision body. This avoids requiring a final skeletal vehicle asset and suspension setup before the first driving loop can be tested.

### Player flow

- The character searches for the nearest `AVICEVehiclePawn` within 850 cm when the player presses the interact action.
- Entering hides and disables the character, then transfers the local PlayerController to the vehicle pawn.
- Exiting restores the character just beside the vehicle, re-enables collision and walking movement, and returns controller possession.
- The mobile HUD stays attached to the character and routes contextual actions to the occupied vehicle.

### Controls

| Input | On foot | In vehicle |
|---|---|---|
| Left virtual joystick | Move | Throttle / reverse and steer |
| Right virtual joystick | Look | Look around |
| Camera button | First-/third-person | Vehicle cockpit-/chase camera |
| Jump button | Jump | No action |
| Sprint button | Sprint | No action |
| Brake button | No action | Brake |
| Enter/exit button | Enter nearby vehicle | Exit vehicle |

Touch HUD action buttons are arranged in a compact top-right cluster, while the speed readout is placed top-left to avoid the default virtual-joystick areas.\n\nKeyboard fallbacks:
- WASD: move / throttle and steer
- Mouse: camera look
- E: enter / exit
- Space: jump / brake
- V: camera perspective

### Vehicle behavior

- Forward speed cap: 3,600 cm/s (129.6 km/h).
- Reverse speed cap: 1,200 cm/s (43.2 km/h).
- Acceleration and steering scale with frame delta.
- Swept collision stops the car when its collision body hits blocking geometry.
- Wheel meshes rotate and front wheels visually steer.
- HUD speed readout displays km/h while the player occupies the vehicle.

## Known limitations

This is a graybox proof of the gameplay flow, not production vehicle physics or a final car model. Wheels do not have suspension or independent tire contact; traction, gear shifts, handbrake drift, damage, traffic rules, vehicle audio, and interior detail are not implemented. Real device testing is required to tune steering and touch response on iPhone 12 mini.
