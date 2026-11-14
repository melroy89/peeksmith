project('peeksmith', ['c', 'vala'],
  version: '1.6.1',
  meson_version: '>= 1.0.0',
)

vala_compiler = meson.get_compiler('vala')
if not vala_compiler.version().version_compare('>= 0.56.0')
  error('Vala >= 0.56.0 is required')
endif

add_project_arguments([
    '-DVERSION="' + meson.project_version() + '"',
  ], language: 'c')

i18n = import('i18n')

subdir('data')
subdir('po')
subdir('src')
subdir('tests')

meson.add_install_script('build-aux/meson/postinstall.py')
