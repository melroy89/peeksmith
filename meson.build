project('peeksmith', ['c', 'vala'],
  version: '1.6.1',
  meson_version: '>= 0.47.0',
)

add_project_arguments([
    '-DVERSION="' + meson.project_version() + '"',
  ], language: 'c')

i18n = import('i18n')

subdir('data')
subdir('po')
imgur_client_id = get_option('imgur-client-id').strip()
if imgur_client_id != imgur_client_id.underscorify() or imgur_client_id.contains('_')
  error('imgur-client-id must contain only ASCII letters and digits')
endif
sharing_config = configuration_data()
sharing_config.set('IMGUR_CLIENT_ID', imgur_client_id)
sharing_config_source = configure_file(input: 'src/sharing/build-config.vala.in', output: 'sharing-build-config.vala', configuration: sharing_config)

subdir('src')
subdir('tests')

meson.add_install_script('build-aux/meson/postinstall.py')
