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
Xvfb, xauth, procps (procps-ng on Fedora), and D-Bus, then run from the source root:

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


## Packaging and releases

Release metadata is checked with `python3 tools/release-version.py`. Meson,
Debian, RPM, AppStream, the changelog, and `docs/releases/<version>.md` must agree.

### Debian and Ubuntu

Install the build dependencies listed in `debian/control`, then run:

    tools/build-package.sh deb

This uses debhelper and Meson, runs the registered tests, and writes a
platform-specific `.deb` to `dist/`. Shared-library dependencies are generated
by `dh_shlibdeps`; FFmpeg is an explicit runtime dependency. The build happens
in a temporary copy and leaves the checkout untouched.

### Fedora

Install the `BuildRequires` from `rpm/peeksmith.spec`, plus `rpm-build` and
`redhat-rpm-config`, then run:

    tools/build-package.sh rpm

This runs the Meson tests and produces binary and source RPMs in `dist/`.
Installation requires RPM Fusion's full FFmpeg package for the x264 encoders.

### Release workflow

`.github/workflows/release.yml` supports a manual dry run and `vMAJOR.MINOR.PATCH`
tag pushes. Both run the existing CI workflow, build native x86-64 packages for
Ubuntu 22.04/24.04/26.04, Debian 12/13, and Fedora 44, and test dependency
resolution, installed branding and GSettings, real X11 recording in all four formats, and removal
in clean distribution containers. Source archives and SHA-256 checksums are
collected into the downloadable `release-bundle` Actions artifact.

A manual run does not create a GitHub release. A matching version tag creates a
**draft** release with the assets only after every required job passes. Review
the draft and publish it explicitly when ready. Packages are not GPG signed.
Checksums detect corruption and are not a substitute for package signatures.

For 1.6.0:

1. Review release notes, confirm the date in AppStream and Debian/RPM changelogs,
   including the release date in `CHANGES.md`.
2. Commit and push the release preparation, then run the release workflow
   manually and check the exact commit's complete build/install matrix.
3. Tag that validated commit with `v1.6.0` and push the tag.
4. Check the tag workflow, download and verify the draft assets, then publish
   the reviewed draft and update the README's preparation notice.

The recipes under `build-aux/` are legacy upstream infrastructure; Flatpak,
Snap, and AppImage distribution are outside this native-package release.
