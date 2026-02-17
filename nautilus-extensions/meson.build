# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

project('nautilus-python-extension', 'c',
  version: '0.1.0',
  license: 'GPL-3.0-or-later',
  meson_version: '>= 1.0.0',
)

gnome = import('gnome')

prefix = get_option('prefix')
datadir = get_option('datadir')
project_name = meson.project_name()
project_version = meson.project_version()

glib_required_version = '>= 2.80'

nautilus_python = dependency('nautilus-python', version: '>= 4')
dependency('glib-2.0', version: glib_required_version)
dependency('gobject-2.0', version: glib_required_version)
dependency('pygobject-3.0', version: '>= 3.18')
dependency('libadwaita-1', version: '>= 1.7')
dependency('libnautilus-extension-4', version: '>= 48')

blueprint_compiler = find_program('blueprint-compiler', required: true)
python = import('python').find_installation(required: true)
nautilus_extension_dir = nautilus_python.get_variable('pythondir', pkgconfig_define: [ 'datadir', datadir ])

extension_files = [ 'fds-hash.py' ]

install_data(
  extension_files,
  install_dir: nautilus_extension_dir,
  install_mode: 'r--r--r--',
)

fs = import('fs')
blueprint_files = [ 'fds-hash.blp' ]
ui_files = []

foreach file : blueprint_files
  ui_files += fs.replace_suffix(file, '.ui')
endforeach

blueprints = custom_target(
  'fds-nautilus-extension-ui',
  input: files(blueprint_files),
  output: ui_files,
  command: [
    blueprint_compiler,
    'batch-compile',
    '@OUTDIR@',
    '@CURRENT_SOURCE_DIR@',
    '@INPUT@',
  ],
  install: true,
  install_dir: prefix / nautilus_extension_dir,
  install_mode: 'r--r--r--',
)
