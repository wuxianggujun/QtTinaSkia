@echo off
if not exist "3rdparty/skia" (
    git clone https://gitee.com/QtSkia/skia.git --branch QtSkia --depth 1 3rdparty/skia
    pushd 3rdparty\skia
) else (
    pushd 3rdparty\skia
    git pull --depth=1 https://gitee.com/QtSkia/skia.git QtSkia --allow-unrelated-histories
)
set GIT_SYNC_DEPS_PATH=%cd%/DEPS-gitee
set PYTHONUTF8=1
set GIT_SYNC_DEPS_SKIP_EMSDK=1
python3 tools/git-sync-deps -v
popd
