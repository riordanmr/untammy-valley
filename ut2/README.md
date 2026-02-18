# ut2 (iOS, 2D SpriteKit Adventure)

`ut2` is a 2D adventure game prototype for iOS built with SwiftUI + SpriteKit.

The app now uses **landscape-only** orientation and a two-tab UI:

- **Map tab**: a scrollable world map scene with the player, rooms, and interactable objects.
- **Stats tab**: separate game-progress and mission stats.
- The **Map/Stats selectors** are shown as custom controls at the **bottom-left** of the screen.

## Story loop implemented

- You play a high school girl exploring the world map locations:
   - Family bar (kitchen/front yard/parking lot jobs)
   - High school (track, volleyball, drill team)
   - Frozen Atlantic route
   - China lab
- Jobs earn coins.
- Coins fund construction of a huge snowmobile.
- You cross the frozen Atlantic by managing fuel and refueling.
- In China, you build atomic tube sections to complete the final world-saving mission.

## Gameplay actions

Use the **Map** tab to move around the world and tap objects/actions.
Use the **Stats** tab to track all progress values.
Use the bottom-left **Map** / **Stats** selector buttons to switch views.

### Family bar
- Make potato chips
- Dig septic systems in the front yard
- Chase goats off cars in the parking lot

### High school
- Track team practice
- Volleyball drills
- Drill team routine

### Expedition
- Ride east (progress + fuel cost)
- Refuel at stations (coin cost)

### China lab
- Assemble atomic tube sections (coin cost)

## Project files

- `UT2/UT2App.swift`
- `UT2/ContentView.swift`
- `UT2/GameScene.swift`
- `UT2/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `project.yml` (for XcodeGen)

## App icon setup

1. Open `UT2/Assets.xcassets/AppIcon.appiconset` in Xcode.
2. Drag icon PNG files into each slot (or drag a 1024x1024 source and let Xcode generate sizes).
3. Regenerate project if needed (`xcodegen generate`) and build.

### Fix yellow resolution warnings (recommended)

If AppIcon slots show yellow triangles, generate exact-size icon files from one 1024 source:

```bash
bash scripts/generate_app_icons.sh /absolute/path/to/your-1024-icon.png
```

Then reopen the asset catalog in Xcode and the warnings should clear.

## Build and run

### Option A: Generate Xcode project with XcodeGen

1. Install XcodeGen (if needed):
   - `brew install xcodegen`
2. Generate project:
   - `xcodegen generate`
3. Open the generated project in Xcode:
   - `open ut2.xcodeproj`
4. Pick an iOS simulator and run.

### Option B: Manual Xcode app

1. Create a new **iOS App** in Xcode named `ut2`.
2. Replace generated Swift files with the files from `UT2/`.
3. Run on simulator/device.

## Notes

- This is an MVP gameplay prototype focused on progression and interactions.
- Visuals are simple 2D shape-based graphics for quick iteration.
