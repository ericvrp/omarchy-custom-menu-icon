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

On first enable, the plugin shows a persistent onboarding notification. It
explains that the leftmost Omarchy topbar icon can be right-clicked to
customize the icon; click the notification to dismiss it.

## Remove

Disable and remove the plugin to restore the stock `omarchy.menu` button:

```bash
omarchy plugin disable ericvrp.custom-menu-icon
omarchy plugin remove ericvrp.custom-menu-icon --yes
```

## Dependencies and license

The plugin requires Omarchy Quattro. Custom HTTPS image support additionally
uses `curl` and ImageMagick (`magick`); no privileged setup is required. The
plugin is released under the MIT license; see [LICENSE](LICENSE).

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

<img src="screenshots/omarchy-default.png" width="600" alt="Default Omarchy icon">

<img src="screenshots/heart.png" width="600" alt="Heart emoji">

<img src="screenshots/torii.png" width="600" alt="Torii gate emoji">

<img src="screenshots/apple-rainbow.png" width="600" alt="Rainbow Apple logo">

<img src="screenshots/apple-modern.png" width="600" alt="Modern Apple logo image">

<img src="screenshots/apple-white.png" width="600" alt="White Apple logo image">

<img src="screenshots/google-color.png" width="600" alt="Google color logo">

<img src="screenshots/google-dark.png" width="600" alt="Google dark logo">

<img src="screenshots/google-white.png" width="600" alt="Google white logo">

<img src="screenshots/windows.png" width="600" alt="Blue Windows logo image">

<img src="screenshots/windows-dark.png" width="600" alt="Dark Windows logo image">

<img src="screenshots/windows-white.png" width="600" alt="White Windows logo image">

The image examples use these direct HTTPS sources:

- Rainbow Apple logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Apple%20Computer%20Logo%20rainbow.svg`
- Modern Apple logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Apple_logo_black.svg`
- White Apple logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Apple_logo_white.svg`
- Google color logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Google%20%22G%22%20logo.svg`
- Google dark logo — `https://raw.githubusercontent.com/ericvrp/omarchy-custom-menu-icon/main/assets/google-dark.png`
- Google white logo — `https://raw.githubusercontent.com/ericvrp/omarchy-custom-menu-icon/main/assets/google-white.png`
- Windows blue logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Windows_logo_-_2012.svg`
- Windows dark logo — `https://commons.wikimedia.org/wiki/Special:FilePath/Windows_logo_2012-Black.svg`
- Windows white logo — `https://raw.githubusercontent.com/ericvrp/omarchy-custom-menu-icon/main/assets/windows-white.png`

The chooser uses bundled, transparent high-resolution PNG previews for these
preset images. Custom HTTPS image URLs continue to be downloaded and cached
locally.
