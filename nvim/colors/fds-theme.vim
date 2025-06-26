" SPDX-FileCopyrightText: 2022-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
"
" SPDX-License-Identifier: MIT

" You probably always want to set this in your vim file
set background=dark
let g:colors_name="fds-theme"

" include our theme file and pass it to lush to apply
lua require('lush')(require('lush_theme.fds-theme'))
