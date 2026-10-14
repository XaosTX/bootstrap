#!/bin/sh
# groups/eclipse.sh — Eclipse and eclim for the vim eclim plugin (Linux). OFF by default.
# Pinned to old releases (Eclipse Neon 2, eclim 2.6.0); bump the URLs before relying on it.
# ITEMS: eclipse eclim   (eclim needs eclipse)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

if [ "$(uname)" = Darwin ]; then
  log_arrow "eclipse: Linux only — skipping"
  exit 0
fi

if has_item eclipse && [ ! -d "$HOME/eclipse" ]; then
  run curl -SLo "$HOME/eclipse-neon.tar.gz" \
    http://mirror.cc.columbia.edu/pub/software/eclipse/technology/epp/downloads/release/neon/2/eclipse-java-neon-2-linux-gtk-x86_64.tar.gz
  run tar -zxf "$HOME/eclipse-neon.tar.gz" -C "$HOME"
  run rm -f "$HOME/eclipse-neon.tar.gz"
fi

if has_item eclim && [ ! -e "$HOME/eclipse/eclim" ]; then
  run wget -O /tmp/eclim_2.6.0.jar "https://github.com/ervandew/eclim/releases/download/2.6.0/eclim_2.6.0.jar"
  run java -Dvim.files="$HOME/.vim" -Declipse.home="$HOME/eclipse" -jar /tmp/eclim_2.6.0.jar install
  run rm -f /tmp/eclim_2.6.0.jar
fi
