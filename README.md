# Omarchy Custom Menu Icon

An Omarchy shell plugin that replaces the stock `omarchy.menu` bar button with
a customizable icon. It keeps the normal Omarchy menu, while allowing the
button to display:

- the original Omarchy glyph;
- arbitrary text or an emoji; or
- an image downloaded from an HTTPS URL, downscaled, cached, and shown in the
  bar.

## Mouse controls

- **Left click** — open the Omarchy menu
- **Middle click** — open a terminal
- **Right click** — open the icon preset panel

The panel offers the current built-in Omarchy glyph, the example icons,
and a **Custom** option. Custom text, emoji, and direct HTTPS image URLs can be
entered in its text field and saved. The normal Omarchy emoji picker remains a
separate action: keep the custom field focused and use its shortcut
(`Super+Ctrl+E` by default).

Selecting the built-in Omarchy glyph restores whatever icon the installed
Omarchy menu currently provides.

## Image URLs

Image values must begin with `https://` and point directly to an image, such as
a favicon. Images are downloaded only when the configured value changes and are
cached below:

```text
~/.cache/omarchy-custom-menu-icon/
```

The helper requires `curl` and ImageMagick (`magick`). Invalid or unavailable
images fall back to the Omarchy glyph.

## Install

```bash
omarchy plugin add https://github.com/ericvrp/omarchy-custom-menu-icon.git --enable
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
omarchy plugin update ericvrp.custom-menu-icon
```

## Examples

These are screenshots from the running bar widget:

![Default Omarchy icon](screenshots/omarchy-default.png)

![Heart emoji](screenshots/heart.png)

![Speech bubble emoji](screenshots/speech-bubble.png)

![Rainbow Apple logo](screenshots/apple-rainbow.png)

![Modern Apple logo image](screenshots/apple-modern.png)

![White Apple logo image](screenshots/apple-white.png)

![Blue Windows logo image](screenshots/windows.png)

![Dark Windows logo image](screenshots/windows-dark.png)

![White Windows logo image](screenshots/windows-white.png)

The image examples use these direct HTTPS sources:

- Rainbow Apple logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Apple%20Computer%20Logo%20rainbow.svg`
- Modern Apple logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Apple_logo_black.svg`
- White Apple logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Apple_logo_white.svg`
- Windows blue logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Windows_logo_-_2012.svg`
- Windows dark logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Windows_logo_2012-Black.svg`
- Windows white logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Windows_logo_-_2021_%28White%29.svg`

The chooser uses bundled, transparent high-resolution PNG previews for these
preset images. Custom HTTPS image URLs continue to be downloaded and cached
locally.
