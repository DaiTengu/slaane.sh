#!/usr/bin/env bash
# jc - Convert CLI output to JSON (pairs well with jq)

MODULE_BIN="jc"
MODULE_PIPX="jc"
MODULE_PROJECT_URL="https://github.com/kellyjonbrazil/jc"

# No custom install() needed - framework auto-bootstraps pipx and installs
# Usage: command | jc --command | jq '.field'
# Example: ps aux | jc --ps | jq '.[0].pid'
