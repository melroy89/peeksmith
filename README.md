# Peeksmith - an animated GIF recorder
[![Build and test](https://github.com/melroy89/peeksmith/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/melroy89/peeksmith/actions/workflows/ci.yml)
[![GitHub release](https://img.shields.io/github/v/release/melroy89/peeksmith)](https://github.com/melroy89/peeksmith/releases)
[![License: GPL v3+](https://img.shields.io/badge/license-GPL%20v3%2B-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Upstream packaging status](https://repology.org/badge/tiny-repos/peek.svg)](https://repology.org/project/peek/packages)
[![Upstream translation status](https://hosted.weblate.org/widgets/peek/-/svg-badge.svg)](https://hosted.weblate.org/engage/peek/?utm_source=widget)

Peeksmith is a continuation of [the original Peek project](https://github.com/phw/peek).
Report issues and contribute changes at [melroy89/peeksmith](https://github.com/melroy89/peeksmith).

![Upstream Peek recording itself](https://raw.githubusercontent.com/phw/peek/master/data/screenshots/peek-recording-itself.gif)

Simple screen recorder with an easy to use interface

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Contents

- [About](#about)
- [Requirements](#requirements)
  - [Runtime](#runtime)
  - [Development](#development)
- [Installation](#installation)
  - [Release packages](#release-packages)
  - [Build from source](#build-from-source)
- [Frequently Asked Questions](#frequently-asked-questions)
  - [How can I capture mouse clicks and/or keystrokes?](#how-can-i-capture-mouse-clicks-andor-keystrokes)
  - [How can I improve the quality of recorded GIF files](#how-can-i-improve-the-quality-of-recorded-gif-files)
  - [Why are the GIF files so big?](#why-are-the-gif-files-so-big)
  - [If GIF is so bad why use it at all?](#if-gif-is-so-bad-why-use-it-at-all)
  - [What about WebM or MP4? Those are well supported on the web.](#what-about-webm-or-mp4-those-are-well-supported-on-the-web)
  - [What is the cause for "Could not start GNOME Shell recorder" errors?](#what-is-the-cause-for-could-not-start-gnome-shell-recorder-errors)
  - [Why can't I interact with the UI elements inside the recording area?](#why-cant-i-interact-with-the-ui-elements-inside-the-recording-area)
  - [My recorded GIFs flicker, what is wrong?](#my-recorded-gifs-flicker-what-is-wrong)
  - [On i3 the recording area is all black, how can I record anything?](#on-i3-the-recording-area-is-all-black-how-can-i-record-anything)
  - [Why no native Wayland support?](#why-no-native-wayland-support)
- [Contribute](#contribute)
  - [Development](#development-1)
  - [Translations](#translations)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## About
Peeksmith makes it easy to create short screencasts of a screen area. It was built
for the specific use case of recording screen areas, e.g. for easily showing UI
features of your own apps or for showing a bug in bug reports. With Peeksmith, you
simply place the Peeksmith window over the area you want to record and press
"Record". Peeksmith is optimized for generating animated GIFs, but you can also
directly record to WebM or MP4 if you prefer.

Peeksmith is not a general purpose screencast app with extended features but
rather focuses on the single task of creating small, silent screencasts of
an area of the screen for creating GIF animations or WebM and MP4 videos.

Peeksmith runs on X11 or inside a GNOME Shell Wayland session using XWayland.
On X11, Peeksmith prefers FFmpeg; on Wayland, it prefers the GNOME Shell recorder.
Use `peeksmith --backend=ffmpeg` or `peeksmith --backend=gnome-shell` to select a backend
explicitly. Support for more Wayland desktops might be added in the future
(see FAQs below).


Peeksmith uses its own application ID (`org.melroy.Peeksmith`), settings, and
cache directory, so it can be installed alongside upstream Peek. Existing Peek
preferences are not automatically migrated.

## Requirements
### Runtime

- GTK+ >= 3.22
- GLib >= 2.52
- [libkeybinder3](https://github.com/kupferlauncher/keybinder)
- FFmpeg >= 3 with libx264, libx264rgb, and libvpx-vp9 encoders
- GStreamer 'Good' plugins (for recording on GNOME Shell)
- [gifski](https://gif.ski/) (optional but recommended for improved GIF quality)

### Development

- Vala compiler >= 0.22
- Meson >= 0.47.0
- Gettext (>= 0.19 for localized .desktop entry)
- txt2man (optional for building man page)


## Installation
### Release packages
The first Peeksmith release, 1.6.0, is being prepared. Download assets will appear
on the [releases page](https://github.com/melroy89/peeksmith/releases) after publication.

Native x86-64 packages target Ubuntu 22.04, 24.04 and 26.04, Debian 12 and 13,
and Fedora 44. Choose the asset matching your installed distribution version:

- Debian/Ubuntu: `sudo apt install ./peeksmith-<version>-<distribution>-amd64.deb`
- Fedora: `sudo dnf install ./peeksmith-<version>-1.fc44.x86_64.rpm`

Fedora needs the `ffmpeg` package from [RPM Fusion](https://rpmfusion.org/Configuration)
for the x264 encoders; `ffmpeg-free` is insufficient for GIF/APNG and MP4 recording.
The release also includes source archives and `SHA256SUMS`. Download the checksum
file beside your package, then run `sha256sum -c SHA256SUMS --ignore-missing`.
Packages are unsigned. Run the installed application with `peeksmith` or its launcher.

### Build from source
Peeksmith is built from this repository. Packages named `peek` in distribution
repositories, Flathub, and upstream release downloads are the original Peek;
they do not install Peeksmith.

You can build and install Peeksmith using Meson with Ninja:

    git clone https://github.com/melroy89/peeksmith.git
    cd peeksmith
    meson --prefix=/usr/local builddir
    cd builddir
    ninja

    # Run directly from source with the local settings schema
    glib-compile-schemas --targetdir=data ../data
    GSETTINGS_SCHEMA_DIR="$PWD/data" ./src/peeksmith

    # Install system-wide
    sudo ninja install

*Note: `ninja` might be called `ninja-build` on some distributions.*

## Frequently Asked Questions
### How can I capture mouse clicks and/or keystrokes?
Peeksmith does not support this natively. But you could install an external tool
like [key-mon](https://github.com/critiqjo/key-mon) which is usually included
in most distributions, so you can easily install with your package manager.
Then start key-mon with `key-mon --visible_click`. The `--visible_click` option
is for drawing small circles around mouse clicks.

### How can I improve the quality of recorded GIF files
To get the best possible quality you should install the [gifski](https://gif.ski/)
GIF encoder. If available Peeksmith will automatically use gifski and will provide
a quality slider in the preferences dialog. The default value will give a
balanced result between quality and file size. Set the quality to maximum if you
want to get the highest possible quality even with thousands of colors. The file
size will increase significantly, though (see below).

### Why are the GIF files so big?
The GIF format is highly inefficient and not well suited for doing large
animations with a lot of changes and colors. Peeksmith tries its best to reduce the
file size by using FFmpeg or [gifski](https://gif.ski/) to generate optimized
GIF files. For best results:

- Use a lower frame rate. 10fps is the default and works well, but in many
  cases you can even get good results with lower framerates.
- If you have [gifski](https://gif.ski/) installed you can adjust the GIF
  quality in the preferences. A lower quality gives a smaller file size at the
  expense of visual quality (see above).
- Avoid too much change. If there is heavy animation the frames will differ
  a lot.
- Record small areas or use the downsample option to scale the image. The GIF
  file format is not well suited for high resolution or full-screen recording.
- Avoid too many colors, since GIF is limited to a 256 color palette per frame.
  This one is not so much about file size but more about visual quality.
- If the above suggestions are not suitable for your use case, consider using
  WebM format (see below).

### If GIF is so bad why use it at all?
While GIF is a very old format, it has seen some rise in usage again in recent
years. One reason is its easy usage in the Web. GIF files are supported nearly
everywhere, which means you can add animations easily to everywhere where you
can upload images. With real video files you are still more limited. Typical use
cases for Peeksmith are recording small user interactions for showing UI features
of an app you developed, for making short tutorials or for reporting bugs.

### What about WebM or MP4? Those are well supported on the web.
Peeksmith allows you to record in WebM or MP4 format; choose your preferred output
format in the preferences. WebM is well supported by modern browsers, even
though they are still not as universally supported by tools and online services
as GIFs.

MP4 recording is available again in this fork. For GNOME Shell recording,
MP4 encoding requires the GStreamer ugly plugins.

### What is the cause for "Could not start GNOME Shell recorder" errors?

This usually indicates an error while starting the built-in GNOME shell
recorder. Unfortunately Peeksmith does not receive any error details, to find out
more about this issues look at the GNOME Shell log output in `journalctl`.

On recent GNOME Shell versions, a failed or unavailable PipeWire stream can
also prevent recording. Check that PipeWire is running and inspect the GNOME
Shell logs. On X11, try `peeksmith --backend=ffmpeg`.

A common cause for this is that the GNOME Shell recorder is already running,
either because it was started via the GNOME Shell keyboard shortcut or by
another application.

If this error is shown when trying to record MP4 a common cause is that you are
missing the [GStreamer ugly](https://gstreamer.freedesktop.org/modules/gst-plugins-ugly.html)
plugins, which provide MP4 encoding. Please refer to the documentation of your
distribution on how to install these.
Do note that you have to logout and login for Peeksmith to recognize the new
installed libraries if you are running the Wayland display server.

See also issue [#287](https://github.com/phw/peek/issues/287) for related discussion.

### Why can't I interact with the UI elements inside the recording area?
You absolutely should be able to click the UI elements inside the area you are
recording. If you use i3 you should stack Peeksmith with the window you intend to
record or make sure all windows are floating and uncheck "Always on top" from
the Peeksmith settings. If you want to be able to control the area when recording
in i3 you can move Peeksmith to the Scratchpad it will keep recording the area once
you hide the window. If this does not work for you on any other window manager
please open an [issue on GitHub](https://github.com/melroy89/peeksmith/issues).

### My recorded GIFs flicker, what is wrong?
Some users have experienced recorded windows flicker or other strange visual
artifacts only visible in the recorded GIF. This is most likely a video driver
issue. If you are using Intel video drivers switching between the SNA and UXA
acceleration methods can help. For NVIDIA drivers changing the "Allow Flipping"
setting in the NVIDIA control panel
[was reported to help](https://github.com/phw/peek/issues/86).

### On i3 the recording area is all black, how can I record anything?
i3 does not support the X shape extension. In order to get a transparent
recording area, you have to run a compositor such as Compton.

### Why no native Wayland support?
Wayland has two restrictions that make it hard for Peeksmith to support Wayland
natively:

1. The Wayland protocol does not define a standard way for applications to
   obtain a screenshot. That is intentional, as taking an arbitrary screenshot
   essentially means any application can read the contents of the whole display,
   and Wayland strives to offer improved security by isolating applications. It
   is up to the compositors to provide screenshot capability, and most do. GNOME
   Shell also provides a public interface for applications to use which Peeksmith
   does support.

2. The Wayland protocol does not provide absolute screen coordinates to the
   applications. There is not even a coordinate system for windows at all. Again
   this is intentional, as they are not needed in many cases and you do not need
   to follow restrictions imposed by the traditional assumption that the screen
   is a rectangular area (e.g. you can have circular screens or [layout windows
   in 3D space](https://www.youtube.com/watch?v=_FjuPn7MXMs)).

Unfortunately, the whole concept of the Peeksmith UI is that the window position
itself is used to obtain the recording coordinates. That means, for now, there
cannot be any fully native Wayland support without special support for this
use case by the compositor.

However, it is possible to use Peeksmith in a GNOME Shell Wayland session using
XWayland by launching Peeksmith with the X11 backend:

    GDK_BACKEND=x11 peeksmith

Support for compositors other than GNOME Shell can be added if a suitable
screencasting interface is provided.


## Contribute
If you want to help make Peeksmith better the easiest thing you can do is to
[report issues and feature requests](https://github.com/melroy89/peeksmith/issues).
Or you can help in development and translation.

### Development
You are welcome to contribute code and provide pull requests for Peeksmith. The
easiest way to start is looking at the open issues tagged with
[good first issue](https://github.com/melroy89/peeksmith/labels/good%20first%20issue).
Those are open issues which are not too difficult to solve and can be started
without too much knowledge about the code.

Another good starting point is issues tagged with
[help wanted](https://github.com/melroy89/peeksmith/labels/help%20wanted). These issues
may require more familiarity with the code.

In any case, just leave a note on the issue itself that you are working on it,
to avoid multiple people working on the same issue.


### Translations
The Weblate links below belong to the upstream translation project. Translation
changes for this fork can also be submitted as pull requests to
[melroy89/peeksmith](https://github.com/melroy89/peeksmith/pulls).

Peeksmith reuses translations from the upstream Peek project, which uses
[Weblate](https://weblate.org/) for translation management.

Go to the [Peek localization project](https://hosted.weblate.org/projects/peek/translations/)
to start translating. If the language you want to translate into is not already
available, you [can add it here](https://hosted.weblate.org/projects/peek/translations/#newlang).

If you want to be credited for your translation, please add your name to the
[translator-credits](https://hosted.weblate.org/search/peek/translations/?q=translator-credits&search=exact&source=on&type=all&ignored=False)
for your language. The translator credits are shown in Peeksmith's About dialog.


## License
Peek Copyright © 2015-2024 by Philipp Wolfer <ph.wolfer@gmail.com>

Copyright © 2026 by Melroy van den Berg <melroy@melroy.org>

Peeksmith is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Peeksmith is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Peeksmith.  If not, see <https://www.gnu.org/licenses/>.
