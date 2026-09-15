#!/usr/bin/env bash
# Idempotent Cloud Agent setup for Taskuary. Safe to re-run: a venv is reused,
# pip -e reconciles deps, and npm ci is deterministic.
set -euo pipefail
cd "$(dirname "$0")/.."

# Debian/Ubuntu split the stdlib venv module out of the base python; a fresh pod
# usually lacks it, so pull it in only when python3 -m venv can't bootstrap pip.
if ! python3 -c 'import ensurepip' >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq python3-venv
fi

# The app + tests: editable install with the dev extras (pytest, httpx, openpyxl)
# into a repo-local venv. Matches CONTRIBUTING's `pip install -e .[dev]`.
python3 -m venv .venv
# shellcheck disable=SC1091
. .venv/bin/activate
python -m pip install --upgrade pip -q
pip install -e ".[dev]"

# The React UI is build-time only (users never need Node; taskuary/web is
# committed). CONTRIBUTING pins Node 20, and website's `npm test`
# (`node --test test/`) only discovers the test dir on Node 20, not 22.
if [ -d website ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  nvm install 20 >/dev/null
  nvm alias default 20 >/dev/null
  (cd website && npm ci)
fi
