# Mystic Grove

Mystic Grove is a cozy idle village prototype built in Godot. The current loop lets players collect Mana, upgrade the Flower Grove, assign fairies, restore the Sacred Koi Pond, craft and sell Mana Potions, and claim starter quests.

## Requirements

- Godot 4.6 is the project version recorded in `project.godot`.
- Godot 4.7 can open the project, but it may update `config/features` from `4.6` to `4.7`. Avoid committing that version-only change unless the team intentionally upgrades.
- On macOS, the test runner looks for Godot in `PATH`, `/Applications/Godot.app`, or `~/Downloads/Godot.app`.

## Launch

Open `project.godot` from the repository root. The main scene is `res://scenes/MainMenu.tscn`.

For the local playtest workflow:

```bash
./tools/run_playtest.sh launch
```

## Test

Run the Godot behavior suite from the repository root:

```bash
./tests/run_all.sh
```

To use a specific Godot binary:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tests/run_all.sh
```

The runner fails if Godot exits with a non-zero status or if output contains script load, parse, compile, or assertion failures.

The playtest helper also supports:

```bash
./tools/run_playtest.sh test
./tools/run_playtest.sh export-macos
```

## Project Map

- `project.godot`: main Godot project configuration.
- `scenes/`: main menu, village, and onboarding scenes.
- `ui/`: building and feature panels.
- `scripts/game_state.gd`: central save data, resources, progression, quests, and feature state.
- `scripts/main_village.gd`: main village screen, navigation, tutorial, HUD, and home-map interactions.
- `assets/`: sprites, music, SFX, and shaders.
- `data/`: demo notes, playtest checklist, playtest instructions, bug report template, and asset credits.
- `tests/`: Godot behavior tests plus legacy PowerShell verification scripts.
- `tools/`: scene generation helpers for editable building panels.

## Export

`export_presets.cfg` defines Windows playtest/demo exports and a macOS playtest export at `builds/macos_playtest/MysticGrove_Playtest_01.zip`.

macOS exports require Godot export templates. If the export command fails with a missing-template error, install the matching Godot export templates from the editor, then rerun:

```bash
./tools/run_playtest.sh export-macos
```

## Team Notes

Team name: Byte Me

Members: Jilden, Kimberly, Turbo, Cole, and Cody

Plan: Make an idle app about fairies and koi fish. Fairies collect mana online and offline, and mana is the main currency in the game.
