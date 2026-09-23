#!/bin/sh
set -x

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

pnpm store prune
pnpm install --force

# bin/vite dev shells out to Ruby (vite_ruby/vite_rails) which needs gems like
# rack-mini-profiler present -- without this, vite dev fails to boot and
# ViteRuby's autoBuild fallback runs `vite build` inside the rails container
# on every request instead, burning CPU there.
bundle install

echo "Ready to run Vite development server."

exec "$@"
