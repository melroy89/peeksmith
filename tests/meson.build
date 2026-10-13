if get_option('build-tests')
  imgur_tests = executable('test-imgur-client',
    'test-imgur-client.vala',
    join_paths(meson.source_root(), 'src/sharing/imgur-client.vala'),
    join_paths(meson.source_root(), 'src/ui/share-dialog.vala'),
    dependencies: [dependency('gtk+-3.0'), dependency('libsoup-3.0'), dependency('json-glib-1.0')],
  )
  test_schema = custom_target('sharing-test-schema',
    input: '../data/org.melroy.Peeksmith.gschema.xml',
    output: 'gschemas.compiled',
    command: [find_program('glib-compile-schemas'), '--strict', '--targetdir', meson.current_build_dir(), join_paths(meson.source_root(), 'data')],
    build_by_default: true,
  )
  test('Testing Imgur sharing', find_program('xvfb-run'),
    args: ['-a', imgur_tests.full_path()], timeout: 30,
    depends: [test_schema, imgur_tests],
    env: ['NO_AT_BRIDGE=1', 'GSETTINGS_BACKEND=memory', 'GSETTINGS_SCHEMA_DIR=' + meson.current_build_dir(), 'LC_ALL=C.UTF-8'],
  )

  # /desktop-integration/
  test_desktop_integration = executable('test-desktop-integration',
    'test-desktop-integration.vala',
    join_paths(meson.source_root(), 'src/desktop-integration.vala'),
    join_paths(meson.source_root(), 'src/dbus/freedesktop-filemanager.vala'),
    dependencies: [
      dependency('gtk+-3.0'),
    ],
  )
  test('Testing desktop-integration', test_desktop_integration)

  # /utils/
  test_utils = executable('test-utils',
    'test-utils.vala',
    join_paths(meson.source_root(), 'src/defaults.vala'),
    join_paths(meson.source_root(), 'src/utils.vala'),
    dependencies: [
      dependency('gtk+-3.0'),
    ],
  )
  test('Testing utils', test_utils)

  # /screen-recorder/recording-area/
  test_recording_area = executable('test-recording-area',
    'screen-recorder/test-recording-area.vala',
    join_paths(meson.source_root(), 'src/recording/recording-area.vala'),
    dependencies: [dependency('gtk+-3.0')],
  )
  test('Testing recording-area', test_recording_area)

  # /screen-recorder/cli-screen-recorder/
  test_utils = executable('test-cli-screen-recorder',
    'screen-recorder/test-cli-screen-recorder.vala',
    join_paths(meson.source_root(), 'src/post-processing/cli-post-processor.vala'),
    join_paths(meson.source_root(), 'src/post-processing/extract-frames-post-processor.vala'),
    join_paths(meson.source_root(), 'src/post-processing/ffmpeg-post-processor.vala'),
    join_paths(meson.source_root(), 'src/post-processing/gifski-post-processor.vala'),
    join_paths(meson.source_root(), 'src/post-processing/post-processing-pipeline.vala'),
    join_paths(meson.source_root(), 'src/post-processing/post-processor.vala'),
    join_paths(meson.source_root(), 'src/recording/recording-area.vala'),
    join_paths(meson.source_root(), 'src/recording/recording-config.vala'),
    join_paths(meson.source_root(), 'src/recording/screen-recorder.vala'),
    join_paths(meson.source_root(), 'src/recording/base-screen-recorder.vala'),
    join_paths(meson.source_root(), 'src/recording/cli-screen-recorder.vala'),
    join_paths(meson.source_root(), 'src/recording/ffmpeg-screen-recorder.vala'),
    join_paths(meson.source_root(), 'src/recording/ffmpeg.vala'),
    join_paths(meson.source_root(), 'src/defaults.vala'),
    join_paths(meson.source_root(), 'src/errordomain.vala'),
    join_paths(meson.source_root(), 'src/utils.vala'),
    vala_args: ['--pkg', 'posix'],
    dependencies: [
      dependency('gtk+-3.0'),
    ],
  )
  test('Testing cli-screen-recorder', test_utils)
endif
