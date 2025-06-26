# SPDX-FileCopyrightText: 2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

$env.config = $env.config | merge deep --strategy=append {
    show_banner: false
    shell_integration: {
        osc2: true
        osc7: true
        osc133: true
        osc633: true
    }
}
