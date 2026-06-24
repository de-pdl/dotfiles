#!/bin/bash
# =============================================================================
# data/layouts/01-monitor.sh
#
# Layout: full system monitor dashboard.
# Matches the original screenshot arrangement.
#
# Grid (percent of usable workspace):
#   +------+-----------------+
#   |      |         | clock |   (clock: 80-100, 0-18)
#   | btop +---------+-------+
#   |      |                 |
#   |      |     shell       |
#   +------+                 |
#   | fast |                 |
#   |fetch +-----------------+
#   |      |      cava       |
#   +------+-----------------+
# =============================================================================

LAYOUT_NAME="Monitor Dashboard"

LAYOUT_APPS=(
    # type | command                                 | x1 y1 x2 y2  | extras
    "term  | btop                                    |  80  0  40 60"
    "term  | fastfetch; exec sleep infinity          |  0 60  40 100"
    "term  | tty-clock -c -C 4                       | 80  0 100 18"
    "term  | fish                                    | 40 18 100 80 | cwd=$HOME/dotfiles"
    "term  | cava                                    | 40 80 100 100"
)
