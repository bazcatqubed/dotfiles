;;; SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
;;;
;;; SPDX-License-Identifier: BSD-3-Clause

(define-configuration buffer
  ((default-modes
    (pushnew 'nyxt/mode/vi:vi-normal-mode %slot-value%))))
