# Peeksmith build and packaging notes
This file contains information about building and packaging Peeksmith. The
information here is mainly for developers and packagers, end users should
refer to the [installation instructions in README.md](README.md#installation).
For the source checkout instructions for this fork, see
[building from source](README.md#build-from-source).

## Building

### Building from source

From inside the Peeksmith source folder run:

    meson setup --prefix=/usr builddir
    cd builddir
    ninja

`ninja` might be called `ninja-build` on some distributions.

### Run tests

    ninja test

The GitHub Actions workflow in `.github/workflows/ci.yml` builds the default
configuration and an alternate configuration covering the optional feature
switches. A separate job runs all registered unit tests and validates desktop,
AppStream (offline), and GSettings metadata under Xvfb and a D-Bus session.
Build jobs also check a staged installation; CI does not exercise real screen
capture or publish packages.

For an isolated X11 recording smoke test, install FFmpeg, Openbox, xdotool,
Xvfb, xauth, and D-Bus, then run from the source root:

    xvfb-run -a -s "-screen 0 1280x800x24" dbus-run-session -- \
      bash -c 'openbox & sleep 1; tests/ui-smoke.sh builddir/src/peeksmith'

This drives recording, saving, cancellation, and recovery after recorder
failure. Set `PEEKSMITH_FORMAT=mp4` (or `apng` / `webm`) to exercise other formats.
Run it on a disposable display: it grabs a global shortcut and records
the screen. GNOME Shell coverage requires a real GNOME session and can use
`PEEKSMITH_BACKEND=gnome-shell tests/ui-smoke.sh builddir/src/peeksmith`.


### Running Peeksmith with debug output

    glib-compile-schemas --targetdir=data ../data
    GSETTINGS_SCHEMA_DIR="$PWD/data" G_MESSAGES_DEBUG=all ./src/peeksmith

### Update translations

    ninja peeksmith-update-po
    ninja peeksmith-pot


## Packaging

### Debian package

#### Build requirements
 - meson (>= 0.47.0)
 - valac (>= 0.22)
 - libgtk-3-dev (>= 3.22)
 - libkeybinder-3.0-dev
 - libxml2-utils
 - gettext (>= 0.19 for localized .desktop entry)
 - txt2man (optional for building man page)
 - gzip (optional for building man page)

#### Runtime requirements
 - libgtk-3-0 (>= 3.22)
 - libglib2.0-0 (>= 2.52)
 - libkeybinder-3.0-0
 - ffmpeg >= 3 with libx264, libx264rgb, and libvpx-vp9 encoders

### Packaging

The recipes under `build-aux/` are legacy upstream infrastructure and are not
verified Peeksmith distribution channels. Build from source as described above.
