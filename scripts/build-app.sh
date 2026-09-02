#!/bin/zsh

set -euo pipefail

repo_root="${0:A:h:h}"
build_root="$repo_root/.build"
app_root="$repo_root/dist/BzKeeb.app"

cd "$repo_root"

export CLANG_MODULE_CACHE_PATH="$build_root/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$build_root/swift-module-cache"

swift build -c debug --disable-sandbox

mkdir -p "$app_root/Contents/MacOS"
cp "$repo_root/Support/Info.plist" "$app_root/Contents/Info.plist"
cp "$build_root/debug/BzKeeb" "$app_root/Contents/MacOS/BzKeeb"

codesign --force --deep --sign - "$app_root"

echo "$app_root"
