# Skia 升级方案

## 当前状态

- **Skia版本**：已切换到 upstream/main（当前检出：`27d12426`）
- **问题**：旧版 Skia 使用 Python 2 构建脚本，与 Python 3.13 不兼容（已通过升级绕过）
- **Qt版本**: Qt 6.9.1
- **目标**: 保持 Qt6-only + CMake-only，持续跟进 upstream Skia

## 升级目标

1. 升级Skia到最新稳定版本（支持Python 3）
2. 适配Qt6 API变化
3. 移除Qt5相关代码
4. 迁移构建系统到CMake（可选，推荐）

## 技术要点

### 1. Skia API变化（2020 → 最新）

#### 关键API变更：
- `GrContext` → `GrDirectContext` / `GrRecordingContext`
- `SkSurface::MakeRenderTarget()` 参数变化
- `SkImageInfo` 构造方式更新
- GPU相关API重构

#### 需要修改的文件：
- `QtSkia/QtSkiaWidget/QSkiaWidget.cpp`
- `QtSkia/QtSkiaWidget/QSkiaOpenGLWidget.cpp`
- `QtSkia/QtSkiaQuick/QuickItem/QSkiaQuickItem.cpp`
- `QtSkia/QtSkiaQuick/QuickWindow/QSkiaQuickWindow.cpp`
- `QtSkia/QtSkiaGui/QSkiaOpenGLWindow.cpp`

### 2. Qt6 API适配

#### Qt Quick相关：
- `QSGSimpleTextureNode` 在Qt6中的变化
- `QQuickWindow::createTextureFromId()` → `QQuickWindow::createTextureFromNativeObject()`
- RHI (Rendering Hardware Interface) 支持

#### OpenGL相关：
- Qt6默认使用RHI，需要适配OpenGL/Vulkan/Metal/D3D11
- `QOpenGLContext` API变化
- `QOpenGLFunctions` 使用方式更新

### 3. 构建系统升级

#### 当前问题：
- 使用qmake（Qt官方已推荐CMake）（已移除）
- Python 2依赖（已移除）
- 构建配置复杂（已收敛到 CMake）

#### 推荐方案：
- 迁移到CMake
- 使用FetchContent或ExternalProject管理Skia
- 支持vcpkg/conan等包管理器

## 升级步骤

### 阶段一：准备工作

1. **备份当前代码**
   ```bash
   git checkout -b backup-2020-version
   git push origin backup-2020-version
   ```

2. **创建升级分支**
   ```bash
   git checkout master
   git checkout -b upgrade-skia-latest
   ```

3. **检查最新Skia版本**
   - 访问 https://github.com/google/skia
   - 选择稳定的release tag或main分支
   - 记录commit hash

### 阶段二：更新Skia依赖

1. **更新Skia仓库**
   ```bash
   cd 3rdparty
   rm -rf skia
   git clone https://github.com/google/skia.git --depth 1
   cd skia
   # 或者指定特定版本
   # git clone https://github.com/google/skia.git
   # git checkout <commit-hash>
   ```

2. **同步依赖库**
   - 推荐使用仓库根目录的 `syncSkia.bat/.sh`
   - 脚本默认设置：
     - `PYTHONUTF8=1`（避免 Windows 下读取 `DEPS` 的编码问题）
     - `GIT_SYNC_DEPS_SKIP_EMSDK=1`（默认跳过 emsdk，避免拉取超大依赖）

   如需启用 emsdk（CanvasKit/WASM）：
   ```bash
   cd 3rdparty/skia
   PYTHONUTF8=1 GIT_SYNC_DEPS_SKIP_EMSDK=0 python3 tools/git-sync-deps -v
   python3 bin/activate-emsdk
   ```

3. **验证Python 3兼容性**
   - 确保所有构建脚本支持Python 3
   - 测试gn配置生成

### 阶段三：适配Skia API

#### 3.1 更新GrContext相关代码

**文件**: `QtSkia/QtSkiaWidget/QSkiaOpenGLWidget.cpp`

**旧代码**:
```cpp
#include "gpu/GrContext.h"

sk_sp<GrContext> grContext = GrContext::MakeGL(interface);
```

**新代码**:
```cpp
#include "gpu/GrDirectContext.h"

sk_sp<GrDirectContext> grContext = GrDirectContext::MakeGL(interface);
```

#### 3.2 更新Surface创建

**旧代码**:
```cpp
SkImageInfo info = SkImageInfo::Make(w, h, kRGBA_8888_SkColorType, kUnpremul_SkAlphaType);
```

**新代码**:
```cpp
SkImageInfo info = SkImageInfo::Make(w, h, kRGBA_8888_SkColorType, kPremul_SkAlphaType);
// 注意：新版Skia推荐使用Premul
```

#### 3.3 更新头文件包含

需要检查并更新所有Skia头文件路径，新版Skia可能重组了目录结构。

### 阶段四：适配Qt6 API

#### 4.1 更新QQuickItem集成

**文件**: `QtSkia/QtSkiaQuick/QuickItem/QSkiaQuickItem.cpp`

需要适配：
- `QSGTexture` 创建方式
- RHI纹理对接
- 可能需要使用 `QSGRendererInterface` 查询渲染后端

#### 4.2 移除Qt5兼容代码

搜索并移除：
```bash
grep -r "QT_VERSION_CHECK" QtSkia/
grep -r "QT_VERSION < " QtSkia/
grep -r "#if QT_VERSION" QtSkia/
```

### 阶段五：构建系统更新

#### 5.1 qmake（已移除）

当前仓库仅保留 CMake 构建入口，qmake 的 `.pro/.pri` 文件已删除。

#### 5.2 创建CMake构建（推荐）

创建 `CMakeLists.txt`:
```cmake
cmake_minimum_required(VERSION 3.21)
project(QtTinaSkia VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick)

# Skia配置
set(SKIA_DIR ${CMAKE_SOURCE_DIR}/3rdparty/skia)
set(SKIA_INCLUDE_DIRS ${SKIA_DIR}/include)
set(SKIA_LIBRARY_DIR ${CMAKE_BINARY_DIR}/skia)

# 添加子项目
add_subdirectory(QtSkia)
add_subdirectory(examples)
```

### 阶段六：测试验证

1. **编译测试**
   ```bash
   cmake -S . -B build/cmake-vs2022 -G "Visual Studio 17 2022" -A x64 -DQTSKIA_BUILD_SKIA=ON -DSKIA_BUILD_TYPE=Release
   cmake --build build/cmake-vs2022 --config Release
   ```

2. **运行示例**
   - HelloSkiaWidget
   - HelloSkiaQuickItem
   - FeatureShow

3. **功能验证**
   - 基本绘制功能
   - GPU加速
   - 文本渲染
   - 图片编解码

## 预期问题和解决方案

### 问题1：GrContext API变化

**症状**: 编译错误 `'GrContext' was not declared`

**解决**:
```cpp
// 全局替换
GrContext → GrDirectContext
#include "gpu/GrContext.h" → #include "gpu/GrDirectContext.h"
```

### 问题2：SkSurface创建失败

**症状**: `SkSurface::MakeRenderTarget` 返回nullptr

**解决**: 检查参数，新版API可能需要额外的配置参数

### 问题3：Qt6 RHI兼容性

**症状**: QQuickItem渲染黑屏

**解决**: 需要适配Qt6的RHI系统，可能需要重写纹理对接部分

### 问题4：编译性能问题

**症状**: Skia编译时间过长（>30分钟）

**解决**:
- 使用预编译的Skia库
- 减少编译目标（禁用不需要的模块）
- 使用ccache加速

## 文件清单

### 需要修改的核心文件

```
QtSkia/
├── QtSkiaWidget/
│   ├── QSkiaWidget.cpp          # 更新SkSurface API
│   ├── QSkiaWidget.h
│   ├── QSkiaOpenGLWidget.cpp    # 更新GrContext → GrDirectContext
│   └── QSkiaOpenGLWidget.h
├── QtSkiaQuick/
│   ├── QuickItem/
│   │   ├── QSkiaQuickItem.cpp   # 适配Qt6 RHI
│   │   └── QSkiaQuickItem.h
│   └── QuickWindow/
│       ├── QSkiaQuickWindow.cpp # 适配Qt6 RHI
│       └── QSkiaQuickWindow.h
└── QtSkiaGui/
    ├── QSkiaOpenGLWindow.cpp    # 更新GrContext API
    └── QSkiaOpenGLWindow.h
```

### 需要更新的构建文件

```
├── CMakeLists.txt               # 新建
├── QtSkia.pro                   # 更新或废弃
├── skiaCommon.pri              # 更新Python路径
└── skiaBuild/
    └── buildConfig/
        └── buildConfig.pri      # 更新构建配置
```

## 参考资源

- Skia官方文档: https://skia.org/docs/
- Skia API参考: https://api.skia.org/
- Qt6迁移指南: https://doc.qt.io/qt-6/portingguide.html
- Qt6 RHI文档: https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html

## 时间估算

- 阶段一（准备）: 0.5天
- 阶段二（更新Skia）: 1天
- 阶段三（API适配）: 2-3天
- 阶段四（Qt6适配）: 2-3天
- 阶段五（构建系统）: 1-2天
- 阶段六（测试）: 1-2天

**总计**: 7-12天（取决于遇到的问题复杂度）

## 成功标准

- [ ] Skia编译成功（Python 3环境）
- [ ] QtSkia库编译成功
- [ ] 所有示例程序运行正常
- [ ] 基本绘制功能正常
- [ ] GPU加速工作正常
- [ ] 文本渲染正确
- [ ] 无Qt5相关代码残留
- [ ] 文档更新完成
