#!/bin/bash
# =============================================================================
# data/layouts/02-coding.sh
#
# Layout: dev workspace — editor + shell + logs
#
# Grid (percent of usable workspace):
#   +----------------+-------------+
#   |                |   shell     |   (shell: 65-100, 0-60)
#   |                +-------------+
#   |     nvim       |   logs      |   (logs:  65-100, 60-100)
#   |   (0-65, 0-100)|             |
#   |                |             |
#   +----------------+-------------+
# =============================================================================

LAYOUT_NAME="Coding"

LAYOUT_APPS=(
    # type | command                              | x1 y1 x2 y2  | extras
    "term  | nvim                                 |  0  0  65 100 | cwd=$HOME/dotfiles"
    "term  | fish                                 | 65  0 100  60 | cwd=$HOME/dotfiles"
    "term  | tail -f ${XDG_STATE_HOME:-$HOME/.local/state}/rice_farm.log | 65 60 100 100"
)
