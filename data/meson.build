desktop_file = i18n.merge_file(
  input: 'org.melroy.Peeksmith.desktop.in',
  output: 'org.melroy.Peeksmith.desktop',
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils,
    args: [desktop_file]
  )
endif

appstream_file = i18n.merge_file(
  input: 'org.melroy.Peeksmith.appdata.xml.in',
  output: 'org.melroy.Peeksmith.appdata.xml',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
  test('Validate appstream file', appstream_util,
    # Validate packaged metadata independently of remote screenshot availability.
    args: ['--nonet', 'validate', appstream_file]
  )
endif

install_data('org.melroy.Peeksmith.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema file', compile_schemas,
    args: ['--strict', '--dry-run', meson.current_source_dir()]
  )
endif

configuration_data = configuration_data()
# FIXME: That variable name is used as long as we have both cmake and meson builds
configuration_data.set(
  'CMAKE_INSTALL_FULL_BINDIR',
  join_paths(get_option('prefix'), get_option('bindir')))
configure_file(
  input: 'org.melroy.Peeksmith.service.in',
  output: 'org.melroy.Peeksmith.service',
  configuration: configuration_data,
  install_dir: join_paths(get_option('datadir'), 'dbus-1/services')
)

subdir('icons')
subdir('man')
