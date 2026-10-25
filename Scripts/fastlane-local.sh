#!/bin/bash
# Use an explicit maintained Ruby and project-owned gems, preserving Apple Ruby.
set -euo pipefail
cd "$(dirname "$0")/.."

ruby_root="${TEMPO_RUBY_ROOT:-/opt/homebrew/opt/ruby}"
if [ ! -x "$ruby_root/bin/ruby" ]; then
  echo "Install Ruby without changing the global PATH: brew install --skip-link ruby" >&2
  exit 1
fi
export PATH="$ruby_root/bin:$PATH"
ruby -e 'abort "Tempo tooling requires Ruby >=4.0.9 and <5" unless Gem::Requirement.new(">=4.0.9", "<5").satisfied_by?(Gem::Version.new(RUBY_VERSION))'

export GEM_HOME="${TEMPO_GEM_HOME:-$HOME/.local/share/project-ruby/tempo/ruby4}"
export GEM_PATH="$GEM_HOME"
export BUNDLE_PATH="$GEM_HOME/bundle"
export BUNDLE_APP_CONFIG="$GEM_HOME/config"
export BUNDLE_USER_CONFIG="$GEM_HOME/user-config"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export FASTLANE_OPT_OUT_USAGE=1 FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_CHANGELOG=1

case "${1:-}" in
  --install)
    shift
    exec bundle install "$@"
    ;;
  --update)
    shift
    exec bundle update fastlane "$@"
    ;;
  '')
    echo "Usage: $0 --install | --update | <fastlane arguments>"
    echo "Read-only checks: $0 --version; $0 lanes"
    exit 0
    ;;
esac
exec bundle exec fastlane "$@"
