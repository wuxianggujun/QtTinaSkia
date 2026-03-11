#!/bin/sh -e
if [ ! -d "3rdparty/skia" ]; then
    git clone "https://gitee.com/QtSkia/skia.git" --branch QtSkia --depth 1 3rdparty/skia
    cd 3rdparty/skia
else
    cd 3rdparty/skia
    git pull --depth=1 "https://gitee.com/QtSkia/skia.git" QtSkia --allow-unrelated-histories
fi
export GIT_SYNC_DEPS_PATH=$PWD/DEPS-gitee
export PYTHONUTF8=1
export GIT_SYNC_DEPS_SKIP_EMSDK=1
python3 tools/git-sync-deps -v
cd ../..
