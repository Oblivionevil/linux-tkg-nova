#!/bin/bash

set -euo pipefail

src="linux-tkg-config/7.0/config.x86_64"
dst="linux-tkg-config/7.0-nova/config.x86_64"

if [[ ! -f "$src" ]]; then
  echo "Base config not found: $src" >&2
  exit 1
fi

awk '
  BEGIN {
    skip_nouveau = 0
    rust_section = 0
  }

  {
    if ($0 == "CONFIG_PROFILING=y") {
      print
      print "CONFIG_RUST=y"
      next
    }

    if ($0 == "CONFIG_FW_LOADER_DEBUG=y") {
      print
      print "CONFIG_RUST_FW_LOADER_ABSTRACTIONS=y"
      next
    }

    if ($0 == "CONFIG_FIXED_PHY=m") {
      print
      print "CONFIG_RUST_PHYLIB_ABSTRACTIONS=y"
      next
    }

    if ($0 == "CONFIG_VGA_SWITCHEROO=y") {
      print
      print "CONFIG_NOVA_CORE=m"
      next
    }

    if ($0 == "CONFIG_DRM_PANIC_SCREEN=\"qr_code\"") {
      print
      print "CONFIG_DRM_PANIC_SCREEN_QR_CODE=y"
      print "CONFIG_DRM_PANIC_SCREEN_QR_CODE_URL=\"\""
      print "CONFIG_DRM_PANIC_SCREEN_QR_VERSION=40"
      next
    }

    if ($0 == "CONFIG_DRM_MGAG200=m") {
      print
      print "# CONFIG_DRM_NOUVEAU is not set"
      print "CONFIG_DRM_NOVA=m"
      skip_nouveau = 1
      next
    }

    if (skip_nouveau == 1) {
      if ($0 == "CONFIG_DRM_PANEL=y") {
        skip_nouveau = 0
        print
      }
      next
    }

    if ($0 == "CONFIG_LIST_HARDENED=y") {
      print
      print "CONFIG_RUST_BITMAP_HARDENED=y"
      next
    }

    if ($0 == "# Rust hacking") {
      rust_section = 1
      print
      next
    }

    if (rust_section == 1 && $0 == "# end of Rust hacking") {
      print "CONFIG_SAMPLES_RUST=y"
      print "CONFIG_RUST_DEBUG_ASSERTIONS=y"
      print "CONFIG_RUST_OVERFLOW_CHECKS=y"
      print
      rust_section = 0
      next
    }

    print
  }
' "$src" > "$dst"

echo "Generated Nova config at $dst"