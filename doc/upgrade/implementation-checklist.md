# 实施检查清单

本文档提供详细的实施步骤检查清单，确保升级过程有序进行。

## 前期准备

### 环境检查

- [ ] **Python 3.x 已安装** (推荐3.8+)
  ```bash
  python3 --version
  ```

- [ ] **Git 已安装**
  ```bash
  git --version
  ```

- [ ] **CMake 已安装** (3.21+)
  ```bash
  cmake --version
  ```

- [ ] **Ninja 已安装**
  ```bash
  ninja --version
  ```

- [ ] **Qt 6.x 已安装** (推荐6.5+)
  ```bash
  # 建议使用 CMake 方式确认 Qt6 已可用（示例）
  cmake --version
  ```

- [ ] **编译器已安装**
  - Windows: Visual Studio 2019/2022
  - macOS: Xcode Command Line Tools
  - Linux: GCC 9+ 或 Clang 10+

### 代码备份

- [ ] **创建备份分支**
  ```bash
  git checkout -b backup-original-2020
  git push origin backup-original-2020
  ```

- [ ] **标记当前版本**
  ```bash
  git tag v0.1.0-qt5-skia2020
  git push origin v0.1.0-qt5-skia2020
  ```

- [ ] **创建工作分支**
  ```bash
  git checkout master
  git checkout -b upgrade-skia-qt6
  ```

## 阶段一：更新Skia

### 1.1 下载最新Skia

- [ ] **获取 Skia 源码 + 同步依赖（推荐走脚本）**
  - Windows：运行仓库根目录 `syncSkia.bat`
  - macOS/Linux：运行仓库根目录 `syncSkia.sh`

  说明：
  - 脚本默认设置 `PYTHONUTF8=1`，避免 Windows 下读取 `DEPS` 的编码问题
  - 脚本默认设置 `GIT_SYNC_DEPS_SKIP_EMSDK=1`，避免默认下载超大 emsdk（CanvasKit/WASM）

- [ ] **验证依赖完整性**
  ```bash
  # 检查关键依赖
  ls third_party/externals/icu/common/icudtl.dat
  ls third_party/externals/sfntly/cpp/src/sample/chromium/font_subsetter.cc
  ls third_party/externals/swiftshader/
  ```

### 1.2 测试Skia编译

- [ ] **通过 CMake 驱动编译 Skia（推荐）**
  ```bash
  cmake -S . -B build/cmake-vs2022 -G "Visual Studio 17 2022" -A x64 -DQTSKIA_BUILD_SKIA=ON -DSKIA_BUILD_TYPE=Release
  cmake --build build/cmake-vs2022 --config Release --target qtskia_build_skia
  ```

- [ ] **emsdk（CanvasKit/WASM）启用方式**
  ```bash
  cd 3rdparty/skia
  PYTHONUTF8=1 GIT_SYNC_DEPS_SKIP_EMSDK=0 python3 tools/git-sync-deps -v
  python3 bin/activate-emsdk
  ```

## 阶段二：更新QtSkia代码

### 2.1 更新头文件

- [ ] **QtSkiaWidget/QSkiaWidget.cpp**
  - [ ] 更新 `#include` 语句
  - [ ] 检查 `SkSurface` 创建
  - [ ] 检查 `SkImageInfo` 使用

- [ ] **QtSkiaWidget/QSkiaOpenGLWidget.cpp**
  - [ ] `GrContext` → `GrDirectContext`
  - [ ] `#include "gpu/GrContext.h"` → `#include "gpu/GrDirectContext.h"`
  - [ ] `flush()` → `flushAndSubmit()`
  - [ ] 更新 `GrBackendRenderTarget` 创建

- [ ] **QtSkiaQuick/QuickItem/QSkiaQuickItem.cpp**
  - [ ] 适配Qt6 RHI
  - [ ] 更新纹理创建方式
  - [ ] `createTextureFromId` → `createTextureFromNativeObject`

- [ ] **QtSkiaQuick/QuickWindow/QSkiaQuickWindow.cpp**
  - [ ] 更新 `GrContext` 相关代码
  - [ ] 适配Qt6场景图API

- [ ] **QtSkiaGui/QSkiaOpenGLWindow.cpp**
  - [ ] 更新 `GrContext` → `GrDirectContext`
  - [ ] 检查OpenGL上下文管理

### 2.2 API迁移

- [ ] **全局搜索替换**
  ```bash
  # 在QtSkia目录下执行
  grep -r "GrContext" --include="*.cpp" --include="*.h"
  grep -r "SkSurface::Make" --include="*.cpp" --include="*.h"
  grep -r "->flush()" --include="*.cpp" --include="*.h"
  ```

- [ ] **手动检查每个匹配项**
  - 不要盲目替换，理解上下文
  - 参考 `doc/upgrade/api-migration-guide.md`

### 2.3 Qt6适配

- [ ] **移除Qt5兼容代码**
  ```bash
  grep -r "QT_VERSION_CHECK" QtSkia/
  grep -r "QT_VERSION <" QtSkia/
  grep -r "#if QT_VERSION" QtSkia/
  ```

- [ ] **更新QQuickItem集成**
  - [ ] 检查 `updatePaintNode` 实现
  - [ ] 适配RHI纹理系统
  - [ ] 测试不同图形后端（OpenGL/Vulkan/D3D11）

- [ ] **更新信号槽连接**
  - [ ] 使用新式信号槽语法
  - [ ] 移除 `SIGNAL()` 和 `SLOT()` 宏

## 阶段三：构建系统

### 3.1 CMake配置（推荐）

- [ ] **创建根CMakeLists.txt**
  - 参考 `CMakeLists.txt` / `cmake/SkiaConfig.cmake`

- [ ] **创建cmake模块**
  - [ ] `cmake/SkiaConfig.cmake`
  - [ ] `cmake/CompilerWarnings.cmake`

- [ ] **为每个子项目创建CMakeLists.txt**
  - [ ] `QtSkia/CMakeLists.txt`
  - [ ] `QtSkia/QtSkiaWidget/CMakeLists.txt`
  - [ ] `QtSkia/QtSkiaQuick/CMakeLists.txt`
  - [ ] `QtSkia/QtSkiaGui/CMakeLists.txt`
  - [ ] `examples/CMakeLists.txt`

### 3.2 qmake（已移除）

（已移除）当前仓库仅保留 CMake 构建入口，qmake 的 `.pro/.pri` 已被删除。

## 阶段四：编译测试

### 4.1 首次编译

- [ ] **清理旧构建**
  ```bash
  rm -rf build bin
  ```

- [ ] **CMake配置**
  ```bash
  cmake -S . -B build/cmake-vs2022 -G "Visual Studio 17 2022" -A x64 -DQTSKIA_BUILD_SKIA=ON -DSKIA_BUILD_TYPE=Release
  ```

- [ ] **编译**
  ```bash
  cmake --build build/cmake-vs2022 --config Release
  ```

- [ ] **记录编译错误**
  - 保存完整错误日志
  - 逐个修复

### 4.2 修复编译错误

- [ ] **Skia API错误**
  - 参考 `doc/upgrade/api-migration-guide.md`
  - 检查函数签名变化

- [ ] **Qt6 API错误**
  - 参考 `doc/upgrade/qt6-adaptation-guide.md`
  - 检查废弃API

- [ ] **链接错误**
  - 检查库依赖
  - 更新CMakeLists.txt中的链接库

### 4.3 迭代修复

- [ ] **每次修复后重新编译**
  ```bash
  cmake --build . -j8 2>&1 | tee build.log
  ```

- [ ] **记录修改**
  - 提交有意义的commit
  - 写清楚修改原因

## 阶段五：功能测试

### 5.1 基础示例测试

- [ ] **HelloSkiaWidget**
  - [ ] 编译成功
  - [ ] 运行正常
  - [ ] 绘制正确

- [ ] **HelloSkiaOpenGLWidget**
  - [ ] 编译成功
  - [ ] GPU加速工作
  - [ ] 性能正常

- [ ] **HelloSkiaQuickItem**
  - [ ] 编译成功
  - [ ] QML集成正常
  - [ ] 纹理显示正确

- [ ] **HelloSkiaQuickWindow**
  - [ ] 编译成功
  - [ ] 窗口渲染正常

### 5.2 功能验证

- [ ] **基本绘制**
  - [ ] 线条、矩形、圆形
  - [ ] 路径绘制
  - [ ] 颜色填充

- [ ] **文本渲染**
  - [ ] 英文文本
  - [ ] 中文文本
  - [ ] 字体样式

- [ ] **图像处理**
  - [ ] 图片加载
  - [ ] 图片绘制
  - [ ] 图片变换

- [ ] **GPU加速**
  - [ ] OpenGL后端
  - [ ] 性能测试
  - [ ] 内存使用

### 5.3 跨平台测试

- [ ] **Windows**
  - [ ] 编译
  - [ ] 运行
  - [ ] 功能测试

- [ ] **Linux** (如果支持)
  - [ ] 编译
  - [ ] 运行
  - [ ] 功能测试

- [ ] **macOS** (如果支持)
  - [ ] 编译
  - [ ] 运行
  - [ ] 功能测试

## 阶段六：文档更新

### 6.1 README更新

- [ ] **更新依赖要求**
  - Python 3.x
  - Qt 6.x
  - CMake 3.21+

- [ ] **更新编译说明**
  - CMake构建步骤
  - 移除Qt5相关说明

- [ ] **更新示例说明**

### 6.2 技术文档

- [ ] **API文档**
  - 更新类接口说明
  - 添加使用示例

- [ ] **迁移指南**
  - 已完成：`doc/upgrade/skia-upgrade-plan.md`
  - 已完成：`doc/upgrade/api-migration-guide.md`
  - 已完成：`doc/upgrade/qt6-adaptation-guide.md`
  - `doc/upgrade/cmake-migration-guide.md` 不存在（迁移已完成，旧文档已删除）

### 6.3 CHANGELOG

- [ ] **创建CHANGELOG.md**
  ```markdown
  # Changelog

  ## [2.0.0] - YYYY-MM-DD

  ### Changed
  - 升级Skia到最新版本
  - 迁移到Qt6
  - 使用CMake构建系统

  ### Removed
  - Qt5支持
  - Python 2支持
  - qmake构建（已移除）

  ### Fixed
  - [列出修复的问题]
  ```

## 阶段七：发布准备

### 7.1 代码审查

- [ ] **代码质量检查**
  - [ ] 移除调试代码
  - [ ] 统一代码风格
  - [ ] 添加必要注释

- [ ] **性能检查**
  - [ ] 内存泄漏检查
  - [ ] 性能对比测试

### 7.2 版本标记

- [ ] **合并到主分支**
  ```bash
  git checkout master
  git merge upgrade-skia-qt6
  ```

- [ ] **创建版本标签**
  ```bash
  git tag v2.0.0-qt6-skia-latest
  git push origin v2.0.0-qt6-skia-latest
  ```

### 7.3 发布说明

- [ ] **编写Release Notes**
  - 主要变更
  - 破坏性变更
  - 迁移指南链接

- [ ] **更新GitHub Release**
  - 上传编译产物（可选）
  - 链接文档

## 问题追踪

### 遇到的问题

| 问题描述 | 解决方案 | 状态 |
|---------|---------|------|
| Python 2语法错误 | 升级到最新Skia | ✅ 已识别 |
| ICU依赖缺失 | 重新下载ICU | ✅ 已解决 |
| sfntly依赖缺失 | 重新下载sfntly | ✅ 已解决 |
|  |  |  |

### 待办事项

- [ ] 升级Skia到最新版本
- [ ] 适配所有API变更
- [ ] 完成Qt6适配
- [ ] 迁移到CMake
- [ ] 完成所有测试
- [ ] 更新文档

## 时间估算

| 阶段 | 预计时间 | 实际时间 | 备注 |
|-----|---------|---------|------|
| 阶段一：更新Skia | 1天 |  |  |
| 阶段二：更新代码 | 3-4天 |  |  |
| 阶段三：构建系统 | 1-2天 |  |  |
| 阶段四：编译测试 | 1-2天 |  |  |
| 阶段五：功能测试 | 1-2天 |  |  |
| 阶段六：文档更新 | 1天 |  |  |
| 阶段七：发布准备 | 0.5天 |  |  |
| **总计** | **8-13天** |  |  |

## 联系和支持

如果在实施过程中遇到问题：

1. 查阅 `doc/upgrade/` 目录下的相关文档
2. 搜索Skia官方文档：https://skia.org/docs/
3. 查看Qt6迁移指南：https://doc.qt.io/qt-6/portingguide.html
4. 提交Issue到项目仓库

---

**最后更新**: 2025-03-11
**文档版本**: 1.0
