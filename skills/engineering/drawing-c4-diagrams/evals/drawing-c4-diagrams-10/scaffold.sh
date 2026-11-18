#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Allen Sanborn
# Puts this case's input file into the empty eval workspace (claude plugin eval --scaffold).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$here/workspace.dsl" .
