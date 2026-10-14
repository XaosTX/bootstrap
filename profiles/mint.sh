#!/bin/sh
# profiles/mint.sh — Ubuntu base, apt; Mint blocks snap by default (nosnap.pref)
# shellcheck disable=SC2034  # consumed by setup.sh after sourcing
PKG_MGR=apt
PROFILE_HAS_SNAP=0
