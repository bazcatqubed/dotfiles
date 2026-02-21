# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

# Like `glob` built-in except it lists paths relative to the current directory.
export def glob-relative --env [glob: string] {
  glob $glob | path relative-to $env.PWD
}
