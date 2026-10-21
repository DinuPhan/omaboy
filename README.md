# OmaBoy (`dinuphan.omaboy`)

**A Game Boy-like way to control your Omarchy.**

**OmaBoy** is a native [Omarchy Quattro](https://plugins.omarchy.org/) status bar widget, interactive controller HUD, and live Key-Caster OSD overlay for the **8BitDo Micro** and **8BitDo Zero 2** pocket controllers, powered by [`8bitdo-micro-focus-switch`](https://github.com/DinuPhan/8bitdo-micro-focus-switch).

![OmaBoy HUD and Live Key-Caster OSD](preview.png)

---

## Features

- **Live Status Bar Indicator (`󰊴`)**: Highlights when your 8BitDo Micro or Zero 2 is connected over Bluetooth (`uinput` mode) and dims when idle or asleep.
- **Interactive Visual 8BitDo Controller HUD**:
  - **Full Controller Diagram**: Renders the 8BitDo Micro silhouette with semantic color-coded leader polylines, glowing button pins, and hover tooltips.
  - **Click-to-Rebind Modal**: Click any button card, pin, or multi-button combo chip to rebind it on the fly—either by pressing a physical keyboard shortcut (`Press to Capture Key`), selecting a quick-pick preset chip, or typing a custom key/chord or `exec:...` command + description.
  - **App Keymap View**: Automatically tracks your focused Hyprland window (`agy`, `youtube`, `anki`, `browser`, `media`) and displays what every button (`D-Pad`, `X/Y/A/B`, `L/R/L2/R2`, `Select/Start/Star/Home`) does in the active app.
  - **Global System Chords Layer**: View and customize your global multi-button chords that sit on top of every app profile to control Omarchy system-wide (e.g., launching or focusing YouTube/Terminal/Google Photos, toggling fullscreen, switching windows, or triggering Whisper voice dictation).
  - **Adaptive Light & Dark Theme Contrast**: Automatically detects your active Omarchy theme luminance and switches between Catppuccin Mocha pastels on dark themes and high-contrast ink tones on bright/light themes.
- **Live Key-Caster OSD Overlay (Onboarding & Demo Mode)**:
  - Displays a non-intrusive, click-through overlay in the bottom-right corner whenever a controller button or combo is pressed, lighting up the exact physical pin(s) on a mini controller diagram alongside the mapped shortcut and human-readable action description.
  - Toggleable anytime from the HUD header (`󰍹 Key OSD: ON / OFF`), keyboard shortcut (`O`), or CLI (`omarchy-shell dinuphan.omaboy toggleOsd`).
- **One-Click Daemon Controls**:
  - **Reload Config (`R`)**: Sends a zero-downtime `SIGHUP` to `8bitdo-micro-focus-switch.service`.
  - **Edit Config (`E`)**: Opens `~/.config/8bitdo-micro/profiles.toml` in your configured Omarchy editor without overwriting user configuration without explicit consent.

---

## Prerequisites & External Dependencies

OmaBoy reads controller status and profile mappings from the companion [`8bitdo-micro-focus-switch`](https://github.com/DinuPhan/8bitdo-micro-focus-switch) user daemon (`MIT` license):

```bash
git clone https://github.com/DinuPhan/8bitdo-micro-focus-switch.git
cd 8bitdo-micro-focus-switch
git checkout 56ef4528c45d3736e65f7a6ac316d7fee03b5744
uv pip install -e .
8bitdo-micro-focus-switch setup
```

---

## Installation

Install via the Omarchy plugin CLI:

```bash
omarchy plugin add https://github.com/DinuPhan/omaboy.git --enable
```

Or validate and install from a local checkout:

```bash
omarchy plugin validate /path/to/omaboy
cp -r /path/to/omaboy ~/.config/omarchy/plugins/dinuphan.omaboy
omarchy-shell shell rescanPlugins
omarchy plugin enable dinuphan.omaboy --section right
```

---

## Removal

Disable or remove the plugin cleanly using the Omarchy plugin CLI:

```bash
omarchy plugin disable dinuphan.omaboy
omarchy plugin remove dinuphan.omaboy
```

Removing the plugin only deletes `~/.config/omarchy/plugins/dinuphan.omaboy` and leaves your `~/.config/8bitdo-micro/profiles.toml` configuration untouched.

---

## Keyboard & Mouse Shortcuts

- **Bar Icon Left-Click** (or `omarchy-shell shell toggle dinuphan.omaboy`): Open / close OmaBoy HUD panel
- **Bar Icon Middle-Click**: Cycle previewed app profile
- **Bar Icon Right-Click**: Reload `profiles.toml` (`SIGHUP`)
- **Inside Panel**:
  - `Left` / `Right`: Switch between app profiles (`AGY`, `YOUTUBE`, `ANKI`, `BROWSER`, `MEDIA`)
  - `Tab` or `L`: Toggle between **App Keymap** and **Omarchy Global Layer**
  - `O`: Toggle the on-screen **Key-Caster OSD Overlay** (`ON` / `OFF`)
  - `R` or `Enter`: Reload `profiles.toml`
  - `E`: Open `profiles.toml` in Omarchy editor
  - `Esc`: Close panel

---

## License

[MIT](LICENSE) © Nguyen Dinh Phan
