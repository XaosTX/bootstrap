#!/bin/sh
# profiles/debian.sh — apt; no snap by default; firefox ships as firefox-esr
# shellcheck disable=SC2034  # consumed by setup.sh after sourcing
PKG_MGR=apt
PROFILE_HAS_SNAP=0
