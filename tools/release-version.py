#!/usr/bin/env python3
"""Check that all release metadata agrees before building or tagging."""
import argparse
import re
from pathlib import Path
from xml.etree import ElementTree

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--tag', help='Require a matching vMAJOR.MINOR.PATCH tag')
args = parser.parse_args()
version = re.search(r"version: '([0-9]+\.[0-9]+\.[0-9]+)'", (root / 'meson.build').read_text()).group(1)
checks = {
    'RPM': re.search(r'^Version:\s+(\S+)', (root / 'rpm/peeksmith.spec').read_text(), re.M).group(1),
    'Debian': re.search(r'^peeksmith \(([^)]+)-[0-9]+\)', (root / 'debian/changelog').read_text()).group(1),
    'AppStream': ElementTree.parse(root / 'data/org.melroy.Peeksmith.appdata.xml.in').find('releases/release').get('version'),
    'Changelog': re.search(r'^# Version (\S+)', (root / 'CHANGES.md').read_text()).group(1),
}
if args.tag and 'unreleased' in (root / 'CHANGES.md').read_text().splitlines()[0]:
    parser.error('Date the changelog before creating a release tag')
if args.tag:
    checks['Git tag'] = args.tag.removeprefix('v') if args.tag.startswith('v') else args.tag + ' (missing v prefix)'
for name, value in checks.items():
    if value != version:
        parser.error(f'{name} version {value!r} differs from {version!r}')
if not (root / f'docs/releases/{version}.md').is_file():
    parser.error(f'Release notes are missing for {version}')
print(version)
