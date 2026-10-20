# OmaBoy (`dinuphan.omaboy`)

**Control Omarchy like a Game Boy.**

**OmaBoy** is a native [Omarchy Quattro](https://plugins.omarchy.org/) status bar widget and interactive controller HUD for the **8BitDo Micro** and **8BitDo Zero 2** pocket controllers, powered by [`8bitdo-micro-focus-switch`](https://github.com/DinuPhan/8bitdo-micro-focus-switch).

---

## Features

- **Live Status Bar Indicator (`󰊴`)**: Highlights when your 8BitDo Micro or Zero 2 is connected over Bluetooth (`uinput` mode) and dims when idle/asleep.
- **Interactive Visual 8BitDo Controller HUD**:
  - **Full Controller Diagram**: Renders the 8BitDo Micro silhouette with semantic color-coded leader polylines, glowing button pins, and hover tooltips.
  - **Click-to-Rebind Modal**: Click any button card, pin, or `L2 + ...` chord to rebind it on the fly—either by pressing a physical keyboard shortcut (`Press Physical Key`), selecting a quick-pick preset chip, or typing a custom key/chord or `exec:...` command + description.
  - **App Keymap View**: Automatically tracks your focused Hyprland window (`agy`, `youtube`, `anki`, `browser`, `media`) and displays what every button (`D-Pad`, `X/Y/A/B`, `L/R/L2/R2`, `Select/Start/Star/Home`) does in the active app.
  - **Omarchy Layer (`Hold L2`)**: Displays and edits your global `L2 + ...` Omarchy system chords (e.g., `L2+Y` to focus/launch YouTube, `L2+A` for Terminal, `L2+X` for Google Photos, `L2+D-Pad` for fullscreen & window focus, `L2+R` for Whisper voice dictation).
  - **Adaptive Light & Dark Theme Contrast**: Automatically detects your active Omarchy theme luminance and switches between Catppuccin Mocha pastels on dark themes and high-contrast ink tones on bright/light themes.
- **One-Click Daemon Controls**:
  - **Reload Config (`R`)**: Sends a zero-downtime `SIGHUP` to `8bitdo-micro-focus-switch.service`.
  - **Edit Config (`E`)**: Opens `~/.config/8bitdo-micro/profiles.toml` in your Omarchy editor.
  - **Start / Restart Daemon**: Manages the background `systemd --user` service directly from the panel.
- **Instant Controller Summon (`L2 + START`)**:
  - Toggle the OmaBoy HUD from anywhere using `omarchy-shell shell toggle dinuphan.omaboy`.

---

## Prerequisites

Install and enable the [`8bitdo-micro-focus-switch`](https://github.com/DinuPhan/8bitdo-micro-focus-switch) background daemon:

```bash
git clone https://github.com/DinuPhan/8bitdo-micro-focus-switch.git
cd 8bitdo-micro-focus-switch
uv pip install -e .
8bitdo-micro-focus-switch install-udev
8bitdo-micro-focus-switch install-service
systemctl --user daemon-reload
systemctl --user enable --now 8bitdo-micro-focus-switch.service
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

## Keyboard & Mouse Shortcuts

- **Bar Icon Left-Click** (or `omarchy-shell shell toggle dinuphan.omaboy`): Open / close OmaBoy HUD panel
- **Bar Icon Middle-Click**: Cycle previewed app profile
- **Bar Icon Right-Click**: Reload `profiles.toml` (`SIGHUP`)
- **Inside Panel**:
  - `Left` / `Right`: Switch between app profiles (`AGY`, `YOUTUBE`, `ANKI`, `BROWSER`, `MEDIA`)
  - `Tab` or `L`: Toggle between **App Keymap** and **Omarchy Layer (`Hold L2`)**
  - `R` or `Enter`: Reload `profiles.toml`
  - `E`: Open `profiles.toml` in Omarchy editor
  - `Esc`: Close panel

---

## License

[MIT](LICENSE) © Nguyen Dinh Phan
