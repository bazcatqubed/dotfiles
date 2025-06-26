;;; SPDX-FileCopyrightText: 2024-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

;;; tools/wiki/autoload.el -*- lexical-binding: t; -*-

;;;autoload
(when (versionp! emacs-version >= "29")
  (use-package! emacsql-sqlite-builtin)
  (setq org-roam-database-connector 'sqlite-builtin))
