# Kingdoms of War V8 — Free Kingdoms (Prototype)

This is an expanded Godot 4.4.1 3D prototype intended for low-end Android devices. It generates the environment and simple 3D units from primitives (no large asset packs).

## Current prototype features
- Separate human and orc bases on opposite sides of a river and bridge
- Basic human and orc soldiers; tap a blue unit, then tap ground to move
- Automatic melee combat and basic enemy pursuit
- Wood, stone and gold resource markers
- Buttons to gather resources, build a farm/barracks, and train soldiers/workers
- Lightweight generated geometry and mobile-compatible GL Compatibility renderer

## Important limitations
This is still a prototype, not a finished commercial game. Gathering is currently represented by a button; workers do not yet automatically harvest resource nodes. Building placement is predefined, upgrades, save/load, animations, pathfinding, and balanced full gameplay remain future work. The Android export workflow has not yet been run or verified. This ZIP is a Godot project, not an APK.

## Build from Android phone
1. Extract the ZIP.
2. Create a GitHub repository.
3. Upload the contents, including `.github/workflows/build-android.yml`, to the repository root.
4. Open Actions and run **Build Android APK**.
5. Download the artifact only if the workflow succeeds.

If the build fails, share the last 30–40 lines of the Actions log so the workflow can be corrected.
