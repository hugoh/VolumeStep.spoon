# VolumeStep Spoon

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Hammerspoon Spoon](https://img.shields.io/badge/Hammerspoon-Spoon-FFA500.svg)](https://www.hammerspoon.org/docs/index.html)

A Hammerspoon Spoon that makes the volume keys change the volume in quarter steps (about 1.6% instead of macOS's 6.25%), keeping the native volume HUD.

**Repository**: [https://github.com/hugoh/VolumeStep.spoon](https://github.com/hugoh/VolumeStep.spoon)

## How it works

macOS already changes the volume in quarter steps when Shift+Option is held with a volume key. VolumeStep catches each volume key press and re-sends it with those modifiers held, so you get the finer steps without the chord.

## Installation

Ensure you have [Hammerspoon](https://www.hammerspoon.org) installed, then choose a method:

### Release zip (recommended)

1. Download `VolumeStep.spoon.zip` from the [latest release](https://github.com/hugoh/VolumeStep.spoon/releases/latest)
2. Unzip — this produces a `VolumeStep.spoon` folder
3. Move it to `~/.hammerspoon/Spoons/`
4. Reload Hammerspoon (menu bar icon → Reload Config, or run `hs.reload()` in the console)

### SpoonInstall (if you already use it)

```lua
spoon.SpoonInstall:installSpoonFromZip(
  "https://github.com/hugoh/VolumeStep.spoon/releases/latest/download/VolumeStep.spoon.zip"
)
```

### Clone from git (for development or latest changes)

```bash
cd ~/.hammerspoon/Spoons
git clone https://github.com/hugoh/VolumeStep.spoon.git
```

## Usage

```lua
hs.loadSpoon("VolumeStep"):start()
```

## API documentation

Full API reference is generated from the docstrings in `init.lua` (`mise run docs`).
