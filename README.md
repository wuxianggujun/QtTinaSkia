[中文简体](README-zh.md)

# QtSkia

[github repo https://github.com/QtSkia/QtSkia](https://github.com/QtSkia/QtSkia)

[gitee mirror https://gitee.com/QtSkia/QtSkia](https://gitee.com/QtSkia/QtSkia)

# catalogue

- [QtSkia](#qtskia)
- [catalogue](#catalogue)
- [Introduction](#introduction)
  - [Skia](#skia)
  - [QtSkia](#qtskia-1)
- [CI Badge](#ci-badge)
- [Feature show](#feature-show)
  - [Shapes](#shapes)
  - [Bezier Curves](#bezier-curves)
  - [Translations and Rotations](#translations-and-rotations)
  - [Text Rendering](#text-rendering)
  - [Discrete Path Effects](#discrete-path-effects)
  - [Composed Path Effects](#composed-path-effects)
  - [Sum Path Effects](#sum-path-effects)
  - [Shaders](#shaders)
- [QtSkia use example](#qtskia-use-example)
- [Scheduled plan](#scheduled-plan)
- [Build](#build)
  - [dependency library](#dependency-library)
    - [windows](#windows)
    - [MacOS](#macos)
    - [Android](#android)
    - [Linux](#linux)
  - [code download](#code-download)
    - [skia and 3rdparty explain](#skia-and-3rdparty-explain)
  - [compile](#compile)
  - [Code struct](#code-struct)
- [Sponsor](#sponsor)



# Introduction

## Skia

Skia is an open source 2D graphics library which provides common APIs that work
across a variety of hardware and software platforms.  It serves as the graphics
engine for Google Chrome and Chrome OS, Android, Mozilla Firefox and Firefox
OS, and many other products.

Skia is sponsored and managed by Google, but is available for use by anyone
under the BSD Free Software License.  While engineering of the core components
is done by the Skia development team, we consider contributions from any
source.

  * Canonical source tree:
    [skia.googlesource.com/skia](https://skia.googlesource.com/skia).
  * Issue tracker:
    [bug.skia.org](https://bug.skia.org/).
  * Discussion forum:
    [skia-discuss@googlegroups.com](https://groups.google.com/forum/#!forum/skia-discuss).
  * API Reference and Overview: [skia.org/user/api](https://skia.org/user/api/).
  * Skia Fiddle: [fiddle.skia.org](https://fiddle.skia.org/c/@skcanvas_paint).

  * github mirror: https://github.com/google/skia.git

## QtSkia

QtSkia is an open source 2D graphics library which integration skia with qt's render framework.

This project aims to provide a stable and controllable rendering backend for Qt applications, unifying text, paths, animations, Canvas, and GPU rendering.

QtSkia provides connection with QWidget, QOpenGLWidget, QQuickWindow, QQuickItem. Qt developers can import skia to qt easily.

It will support high-performance code editors, charts, drawing tools, and even custom UI components, reusing the same rendering capabilities across Windows/Linux/Android.

# CI Badge

| [Windows][win-link]|[MacOS][macos-link]| [Ubuntu][ubuntu-link]|[Android][android-link]|[IOS][ios-link]|
|---------------|---------------|-----------------|-----------------|----------------|
| ![win-badge]  |![macos-badge] | ![ubuntu-badge]      | ![android-badge]   |![ios-badge]   |

|[License][license-link]| [Release][release-link]|[Download][download-link]|[Issues][issues-link]|[Wiki][wiki-links]|
|-----------------|-----------------|-----------------|-----------------|-----------------|
|![license-badge] |![release-badge] | ![download-badge]|![issues-badge]|![wiki-badge]|

[win-link]: https://github.com/JaredTao/QtSkia/actions?query=workflow%3AWindows "WindowsAction"
[win-badge]: https://github.com/JaredTao/QtSkia/workflows/Windows/badge.svg  "Windows"

[ubuntu-link]: https://github.com/JaredTao/QtSkia/actions?query=workflow%3AUbuntu "UbuntuAction"
[ubuntu-badge]: https://github.com/JaredTao/QtSkia/workflows/Ubuntu/badge.svg "Ubuntu"

[macos-link]: https://github.com/JaredTao/QtSkia/actions?query=workflow%3AMacOS "MacOSAction"
[macos-badge]: https://github.com/JaredTao/QtSkia/workflows/MacOS/badge.svg "MacOS"

[android-link]: https://github.com/JaredTao/QtSkia/actions?query=workflow%3AAndroid "AndroidAction"
[android-badge]: https://github.com/JaredTao/QtSkia/workflows/Android/badge.svg "Android"

[ios-link]: https://github.com/JaredTao/QtSkia/actions?query=workflow%3AIOS "IOSAction"
[ios-badge]: https://github.com/JaredTao/QtSkia/workflows/IOS/badge.svg "IOS"

[release-link]: https://github.com/jaredtao/QtSkia/releases "Release status"
[release-badge]: https://img.shields.io/github/release/jaredtao/QtSkia.svg?style=flat-square "Release status"

[download-link]: https://github.com/jaredtao/QtSkia/releases/latest "Download status"
[download-badge]: https://img.shields.io/github/downloads/jaredtao/QtSkia/total.svg?style=flat-square "Download status"

[license-link]: https://github.com/jaredtao/QtSkia/blob/master/LICENSE "LICENSE"
[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg "MIT"


[issues-link]: https://github.com/jaredtao/QtSkia/issues "Issues"
[issues-badge]: https://img.shields.io/badge/github-issues-red.svg?maxAge=60 "Issues"

[wiki-links]: https://github.com/jaredtao/QtSkia/wiki "wiki"
[wiki-badge]: https://img.shields.io/badge/github-wiki-181717.svg?maxAge=60 "wiki"
# Feature show

## Shapes
![](doc/feature/1.png)

## Bezier Curves
![](doc/feature/2.png)

## Translations and Rotations
![](doc/feature/3.png)

## Text Rendering

![](doc/feature/4.png)

## Discrete Path Effects
![](doc/feature/5.png)

## Composed Path Effects

![](doc/feature/6.png)

## Sum Path Effects

![](doc/feature/7.png)

## Shaders

![](doc/feature/8.png)

# QtSkia use example

[QtSkia us example](doc/Examples.md)

QtTinaSkia upgrade docs: `doc/upgrade/README.md`


# Scheduled plan

* code mirror
- [x] skia code mirror
- [x] 3rdparth mirror
- [x] auto sync upstream code
- [x] local script for fetch code

* Compile and ci
- [x] CMake build flow (qmake removed)
- [x] Windows platform compile.
- [x] MacOS compile
- [ ] Linux compile
- [ ] Android

* effect
- [x] sample text,line
- [X] Skia inner effect
- [ ] texture
- [ ] Lottie

* Qt Framework adapted

1. Gui 
- [x] QOpenGLWindow
- [ ] QWindow
- [ ] QVulkanWindow

2. Widget
- [x] QWidget CPURaster
- [x] QOpenGLWidget

3. Quick
- [x] QOuickWindow
- [X] QQuickItem
- [ ] QQuickFrameBuffer

4. Qt6 RHI

- [ ] under construction

* performance test
  
- [ ] under construction

# Build

## dependency library

Python 3.8+

Qt 6.x (tested with Qt 6.9.1, MSVC 2022 x64)

CMake 3.21+

Visual Studio 2022 (Windows)

Note:32bit/x86 arch, need the toolchain by google， QtSkia not suooprt，detail info can be found in: https://skia.org/user/build

### windows

Compiler need visual studio 2017 and later, clang-cl is better.

### MacOS

under construction

### Android

under construction

### Linux

under construction

## code download

1. Downlaod QtSkia

```shell
git clone https://github.com/QtSkia/QtSkia.git
```

China user can use gitee mirror for speed up.

```shell
git clone https://gitee.com/QtSkia/QtSkia.git
```

2. Download skia and 3rdparty

run script 'syncSkia' at root directory of QtSkia.

China user can use syncSkia-gitee replace for speed up from gitee mirror.

Windows platform click run syncSkia.bat， or termianl run：

```bat
cd QtSkia
syncSkia.bat
```

MacOS or linux platform, termianl run：
```shell
cd QtSkia
chmod a+x syncSkia.sh
./syncSkia.sh
```

### emsdk note (CanvasKit/WASM)

Skia's `tools/git-sync-deps` will try to run `bin/activate-emsdk` by default.
This repo sets the following env vars in sync scripts to avoid downloading huge emsdk assets by default:

- `GIT_SYNC_DEPS_SKIP_EMSDK=1`
- `PYTHONUTF8=1`

If you need CanvasKit/WASM:

```shell
cd 3rdparty/skia
PYTHONUTF8=1 GIT_SYNC_DEPS_SKIP_EMSDK=0 python3 tools/git-sync-deps -v
python3 bin/activate-emsdk
```

### skia and 3rdparty explain

skia origin site: https://skia.googlesource.com/skia

github mirror: https://github.com/google/skia

skia depend on many thrid library. (about 28+)

QtSkia provite mirror on github、gitee, detail on：

https://github.com/QtSkia

https://gitee.com/QtSkia


QtSkia use script auto sync these code from upstream on timer。

QtSkia not edit there code，just add github、gitee mirror support and compiler support.

## compile

This repo is **CMake-only** (qmake project files have been removed).

Windows (VS2022 x64):

```powershell
cmake -S . -B build/cmake-vs2022 -G "Visual Studio 17 2022" -A x64 -DQTSKIA_BUILD_SKIA=ON -DSKIA_BUILD_TYPE=Release
cmake --build build/cmake-vs2022 --config Release
```

## Code struct

|directory|descript|
|:-----------:|:-------------:|
|3rdparty|skia and depency library|
|doc| document |
|examples| examples|
|QtSkia|QtSkia|
|cmake| CMake helper modules |


# Sponsor

If you feel the share content is good, treat the author a drink.

<img src="doc/sponsor/zhifubao.jpg" width="25%" height="25%" /><img src="doc/sponsor/weixin.jpg" width="25%" height="25%" />

it's WeChat Pay and Alipay
