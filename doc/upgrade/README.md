# QtTinaSkia 升级项目总览（已切换到 CMake + Qt6 + upstream Skia）

## 当前状态（2026-03-11）

**当前工程形态**：
- Skia：`upstream/main`（当前检出：`27d12426`）
- Qt：仅支持 Qt6
- 构建系统：仅 CMake（qmake 已移除）
- Python：Python 3（建议 3.8+）

**已验证**：
- `qtskia_build_skia`（通过 CMake 驱动 gn + ninja 编译 Skia）
- `QtSkiaWidget/QtSkiaGui/QtSkiaQuick` 三个库 Release 编译通过
- 示例 Release 编译通过：HelloSkiaWidget / HelloSkiaOpenGLWidget / HelloSkiaOpenGLWindow / HelloSkiaQuickItem / HelloSkiaQuickWindow / FeatureShow / MixWidget

## 核心问题（已处理的主要阻塞）

### 当前阻塞问题

1. **Python 2/3 不兼容**
   - 症状：旧版 Skia 构建脚本触发 `SyntaxError: Missing parentheses in call to 'print'`
   - 解决：升级到 upstream Skia，构建链路切到 Python 3

2. **依赖同步（含网络波动）**
   - Skia 的依赖来自多个域名（含 `*.googlesource.com` / GCS），网络不稳定时容易失败
   - 已在同步脚本内默认设置：`PYTHONUTF8=1`，避免 Windows 下 `DEPS` 读取触发编码问题

3. **Qt6 API差异**
   - Qt Quick / OpenGL / RHI 相关接口变化已做适配并完成编译验证

## 文档结构

所有升级相关文档已保存在 `doc/upgrade/` 目录：

```
doc/upgrade/
├── README.md                          # 本文件
├── skia-upgrade-plan.md              # 总体升级方案
├── api-migration-guide.md            # Skia API迁移指南
├── qt6-adaptation-guide.md           # Qt6适配指南
└── implementation-checklist.md       # 实施检查清单
```

## 快速开始

### 给实施者的建议

1. **先阅读文档**
   - 按顺序阅读上述5个文档
   - 理解整体架构和变更点

2. **准备环境**
   - Python 3.8+
   - Qt 6.5+（当前验证环境：Qt 6.9.1）
   - CMake 3.21+
   - Windows：建议 Visual Studio 2022

3. **按阶段实施**
   - 参考 `implementation-checklist.md`
   - 逐个阶段完成，不要跳跃
   - 每个阶段完成后提交代码

4. **遇到问题**
   - 查阅对应的迁移指南
   - 搜索Skia官方文档
   - 记录问题和解决方案

## 关键技术点

### Skia API变更（提示）

最重要的变更：

```cpp
// 旧 (2020)
#include "gpu/GrContext.h"
sk_sp<GrContext> context = GrContext::MakeGL(interface);
context->flush();

// 新 (upstream)
#include "gpu/ganesh/GrDirectContext.h"
#include "gpu/ganesh/gl/GrGLDirectContext.h"
sk_sp<GrDirectContext> context = GrDirectContexts::MakeGL(interface);
context->flushAndSubmit();
```

详见: `doc/upgrade/api-migration-guide.md`

### Qt6 RHI适配

Qt6不再直接暴露OpenGL，需要通过RHI：

```cpp
QSGRendererInterface *rif = window()->rendererInterface();
if (rif->graphicsApi() == QSGRendererInterface::OpenGL) {
    // OpenGL路径
}
```

详见: `doc/upgrade/qt6-adaptation-guide.md`

### CMake 构建（唯一入口）

Windows（VS2022 / x64）：

```powershell
cmake -S . -B build/cmake-vs2022 -G "Visual Studio 17 2022" -A x64 -DQTSKIA_BUILD_SKIA=ON -DSKIA_BUILD_TYPE=Release
cmake --build build/cmake-vs2022 --config Release
```

说明：Skia 的编译由 CMake target `qtskia_build_skia` 驱动（底层使用 gn + ninja）。

提示：若你使用 CLion 等 IDE，且未指定 `-DQTSKIA_BUILD_SKIA=ON`，当未发现预编译 Skia 产物时工程会自动切换为构建模式（可通过 `-DQTSKIA_AUTO_BUILD_SKIA=OFF` 关闭）。

## 预期时间线

| 阶段 | 任务 | 预计时间 |
|------|------|----------|
| 1 | 环境准备 + Skia更新 | 1-2天 |
| 2 | Skia API适配 | 2-3天 |
| 3 | Qt6 API适配 | 2-3天 |
| 4 | 构建系统迁移 | 1-2天 |
| 5 | 测试和修复 | 2-3天 |
| 6 | 文档更新 | 1天 |
| **总计** | | **9-14天** |

## 风险评估

### 高风险项

1. **Skia API大幅变化**
   - 风险: 可能有未文档化的API变更
   - 缓解: 参考Skia官方示例代码

2. **Qt6 RHI兼容性**
   - 风险: QQuickItem集成可能需要重写
   - 缓解: 参考Qt6官方示例

3. **性能回退**
   - 风险: 新版本可能性能不如旧版
   - 缓解: 进行性能基准测试

### 中风险项

1. **编译时间增加**
   - 新版Skia可能更大
   - 缓解: 使用ccache

2. **第三方依赖问题**
   - 某些依赖可能下载失败
   - 缓解: 使用镜像源

## 成功标准

### 必须达成

- [ ] 使用Python 3成功编译Skia
- [ ] QtSkia库编译成功
- [ ] 所有示例程序运行正常
- [ ] 基本绘制功能正常
- [ ] GPU加速工作

### 期望达成

- [ ] 性能不低于旧版本
- [ ] 支持Qt6 RHI多后端
- [ ] CMake构建系统完善
- [ ] 文档完整更新

### 可选达成

- [ ] 支持Vulkan后端
- [ ] 支持Metal后端 (macOS)
- [ ] 支持Direct3D 11后端 (Windows)

## 联系方式

如果在实施过程中遇到问题：

1. **查阅文档**: 先查看 `doc/upgrade/` 目录下的相关文档
2. **搜索资源**:
   - Skia官方文档: https://skia.org/docs/
   - Qt6文档: https://doc.qt.io/qt-6/
3. **记录问题**: 在项目issue中记录遇到的问题和解决方案

## emsdk 说明（重要）

Skia 的 `tools/git-sync-deps` 默认会尝试执行 `bin/activate-emsdk` 来安装/激活 Emscripten（用于 CanvasKit/WASM）。

本项目在同步脚本内默认设置了：
- `GIT_SYNC_DEPS_SKIP_EMSDK=1`（默认跳过 emsdk，避免拉取超大依赖）

如果你确实需要构建 WASM/CanvasKit：

```powershell
cd 3rdparty/skia
$env:PYTHONUTF8=1
$env:GIT_SYNC_DEPS_SKIP_EMSDK=0
python3 tools/git-sync-deps -v
python3 bin/activate-emsdk
```

## 附录

### 有用的命令

```bash
# 查找需要修改的文件
grep -r "GrContext" QtSkia/ --include="*.cpp" --include="*.h"
grep -r "QT_VERSION" QtSkia/ --include="*.cpp" --include="*.h"

# 同步 Skia 依赖（默认跳过 emsdk）
./syncSkia.bat

# 编译（Windows VS2022）
cmake -S . -B build/cmake-vs2022 -G "Visual Studio 17 2022" -A x64 -DQTSKIA_BUILD_SKIA=ON -DSKIA_BUILD_TYPE=Release
cmake --build build/cmake-vs2022 --config Release
```

### 参考链接

- Skia官网: https://skia.org
- Skia GitHub: https://github.com/google/skia
- Qt6迁移指南: https://doc.qt.io/qt-6/portingguide.html
- CMake文档: https://cmake.org/documentation/

---

**文档版本**: 1.0
**创建日期**: 2025-03-11
**最后更新**: 2025-03-11
