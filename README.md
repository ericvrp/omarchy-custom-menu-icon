# Omarchy Menu Icon

An Omarchy shell plugin that replaces the stock `omarchy.menu` bar button with
a customizable menu icon. It keeps the normal Omarchy menu, while allowing the
button to display:

- the original Omarchy glyph;
- arbitrary text or an emoji; or
- an image downloaded from an HTTPS URL, downscaled, cached, and shown in the
  bar.

## Mouse controls

- **Left click** — open the Omarchy menu
- **Middle click** — open a terminal
- **Right click** — open the icon text editor

The editor does not open the emoji picker. Keep its text field focused and use
the normal Omarchy emoji-picker shortcut (`Super+Ctrl+E` by default). The stock
picker copies the selected emoji and attempts to paste it into the focused
field. The editor also accepts normal pasted text and direct HTTPS image URLs.

Leaving the field empty and choosing **Reset** restores the original Omarchy
glyph.

## Image URLs

Image values must begin with `https://` and point directly to an image, such as
a favicon. Images are downloaded only when the configured value changes and are
cached below:

```text
~/.cache/omarchy-menu-icon/
```

The helper requires `curl` and ImageMagick (`magick`). Invalid or unavailable
images fall back to the Omarchy glyph.

## Install

```bash
omarchy plugin add https://github.com/ericvrp/omarchy-menu-icon.git --enable
```

This plugin declares itself as a fork of `omarchy.menu`. Enabling it replaces
the stock menu button and routes the existing `omarchy.menu` shell commands to
the copied menu implementation.

## Development

The plugin is a small public fork of Omarchy's first-party menu plugin. The
menu files are copied into this repository so the plugin can be installed as a
normal Git checkout. QML files reload after saving under
`~/.config/omarchy/plugins/`.

```bash
omarchy-shell shell rescanPlugins
omarchy plugin update ericvrp.menu-icon
```

## Examples

These are screenshots from the running bar widget:

![Green apple emoji](screenshots/green-apple.png)

![Smiley emoji](screenshots/smiley.png)

![Rainbow Apple logo](screenshots/apple-rainbow.png)

![Modern Apple logo image](screenshots/apple-modern.png)

The image examples use these direct HTTPS sources:

- Rainbow Apple logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Apple%20Computer%20Logo%20rainbow.svg`
- Modern Apple logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Apple_logo_black.svg`
