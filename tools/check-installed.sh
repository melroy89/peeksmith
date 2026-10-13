#!/usr/bin/env bash
# Run inside a disposable installation-test container after apt/dnf installation.
set -euo pipefail
VERSION=${1:?Expected version required}
test "$(peeksmith --version 2>&1)" = "Peeksmith $VERSION"
HELP=$(peeksmith --help)
if grep -Eq '\bPeek\b' <<< "$HELP"; then
  echo 'CLI output still contains the old application name' >&2
  exit 1
fi
test -f /usr/share/applications/org.melroy.Peeksmith.desktop
grep -Fx 'Name=Peeksmith' /usr/share/applications/org.melroy.Peeksmith.desktop
grep -Fx 'Exec=peeksmith' /usr/share/applications/org.melroy.Peeksmith.desktop
desktop-file-validate /usr/share/applications/org.melroy.Peeksmith.desktop
test -f /usr/share/metainfo/org.melroy.Peeksmith.appdata.xml
test -f /usr/share/icons/hicolor/scalable/apps/org.melroy.Peeksmith.svg
test -f /usr/share/dbus-1/services/org.melroy.Peeksmith.service
grep -Fx 'Name=org.melroy.Peeksmith' /usr/share/dbus-1/services/org.melroy.Peeksmith.service
gsettings list-schemas | grep -Fx org.melroy.Peeksmith
GSETTINGS_BACKEND=memory gsettings get org.melroy.Peeksmith interface-default-file-name-format | grep 'Peeksmith'
echo "Installed Peeksmith $VERSION identity and schema checks passed"
