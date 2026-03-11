# API 迁移指南

本文档详细说明从旧版Skia (2020) 迁移到新版Skia时需要的API变更。

## 目录

- [核心API变更](#核心api变更)
- [GPU相关变更](#gpu相关变更)
- [Surface和Canvas](#surface和canvas)
- [图像和编解码](#图像和编解码)
- [文本渲染](#文本渲染)
- [代码示例](#代码示例)

## 核心API变更

### 1. GrContext → GrDirectContext

**变更原因**: Skia重构了GPU上下文系统，引入了录制上下文和直接上下文的概念。

#### 旧代码:
```cpp
#include "gpu/GrContext.h"

sk_sp<GrContext> context = GrContext::MakeGL(interface);
context->flush();
```

#### 新代码:
```cpp
#include "gpu/GrDirectContext.h"

sk_sp<GrDirectContext> context = GrDirectContext::MakeGL(interface);
context->flushAndSubmit();
```

**影响文件**:
- `QtSkia/QtSkiaWidget/QSkiaOpenGLWidget.cpp`
- `QtSkia/QtSkiaGui/QSkiaOpenGLWindow.cpp`
- `QtSkia/QtSkiaQuick/QuickWindow/QSkiaQuickWindow.cpp`

### 2. SkColorType 枚举值

部分颜色类型名称变更：

```cpp
// 旧
kRGBA_8888_SkColorType
kBGRA_8888_SkColorType

// 新（保持不变，但推荐使用）
kRGBA_8888_SkColorType
kBGRA_8888_SkColorType
```

### 3. SkAlphaType 默认值

```cpp
// 旧：常用 kUnpremul_SkAlphaType
SkImageInfo info = SkImageInfo::Make(w, h, kRGBA_8888_SkColorType, kUnpremul_SkAlphaType);

// 新：推荐使用 kPremul_SkAlphaType（性能更好）
SkImageInfo info = SkImageInfo::Make(w, h, kRGBA_8888_SkColorType, kPremul_SkAlphaType);
```

## GPU相关变更

### 1. GrBackendRenderTarget 创建

#### 旧代码:
```cpp
GrBackendRenderTarget backendRT(width, height,
                                 samples,
                                 stencilBits,
                                 framebufferInfo);
```

#### 新代码:
```cpp
GrGLFramebufferInfo framebufferInfo;
framebufferInfo.fFBOID = fboId;
framebufferInfo.fFormat = GL_RGBA8;

GrBackendRenderTarget backendRT = GrBackendRenderTargets::MakeGL(
    width, height, samples, stencilBits, framebufferInfo);
```

### 2. SkSurface::MakeFromBackendRenderTarget

#### 旧代码:
```cpp
sk_sp<SkSurface> surface = SkSurface::MakeFromBackendRenderTarget(
    context.get(),
    backendRT,
    kBottomLeft_GrSurfaceOrigin,
    kRGBA_8888_SkColorType,
    nullptr,
    nullptr);
```

#### 新代码:
```cpp
sk_sp<SkSurface> surface = SkSurfaces::WrapBackendRenderTarget(
    context.get(),
    backendRT,
    kBottomLeft_GrSurfaceOrigin,
    kRGBA_8888_SkColorType,
    nullptr,
    nullptr);
```

**注意**: `SkSurface::Make*` 系列函数移到了 `SkSurfaces` 命名空间。

### 3. flush() → flushAndSubmit()

```cpp
// 旧
context->flush();
surface->flush();

// 新
context->flushAndSubmit();
surface->flushAndSubmit();
```

## Surface和Canvas

### 1. SkSurface 创建

#### 光栅Surface:
```cpp
// 旧
sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(width, height);

// 新
sk_sp<SkSurface> surface = SkSurfaces::Raster(
    SkImageInfo::MakeN32Premul(width, height));
```

#### GPU Surface:
```cpp
// 旧
sk_sp<SkSurface> surface = SkSurface::MakeRenderTarget(
    context.get(),
    SkBudgeted::kNo,
    info);

// 新
sk_sp<SkSurface> surface = SkSurfaces::RenderTarget(
    context.get(),
    skgpu::Budgeted::kNo,
    info);
```

### 2. SkCanvas 操作

Canvas API基本保持不变，但部分参数类型更新：

```cpp
// 绘制操作保持不变
canvas->clear(SK_ColorWHITE);
canvas->drawRect(rect, paint);
canvas->drawPath(path, paint);
```

## 图像和编解码

### 1. SkImage 创建

```cpp
// 旧
sk_sp<SkImage> image = SkImage::MakeFromEncoded(data);

// 新
sk_sp<SkImage> image = SkImages::DeferredFromEncodedData(data);
```

### 2. SkCodec 使用

基本保持不变，但推荐使用新的工厂方法：

```cpp
// 推荐
std::unique_ptr<SkCodec> codec = SkCodec::MakeFromData(data);
```

## 文本渲染

### 1. SkTextBlob

```cpp
// 旧
SkTextBlobBuilder builder;
// ... 构建文本

// 新（API基本不变）
SkTextBlobBuilder builder;
// ... 构建文本
```

### 2. SkFont

```cpp
// 新版推荐使用 SkFont 而不是 SkPaint 设置字体
SkFont font;
font.setSize(24);
font.setTypeface(typeface);

canvas->drawString("Hello", x, y, font, paint);
```

## 代码示例

### 完整示例：创建GPU Surface并绘制

#### 旧代码:
```cpp
#include "gpu/GrContext.h"
#include "gpu/gl/GrGLInterface.h"

void setupSkia() {
    sk_sp<const GrGLInterface> interface = GrGLMakeNativeInterface();
    sk_sp<GrContext> context = GrContext::MakeGL(interface);

    SkImageInfo info = SkImageInfo::Make(800, 600,
                                          kRGBA_8888_SkColorType,
                                          kUnpremul_SkAlphaType);

    sk_sp<SkSurface> surface = SkSurface::MakeRenderTarget(
        context.get(), SkBudgeted::kNo, info);

    SkCanvas* canvas = surface->getCanvas();
    canvas->clear(SK_ColorWHITE);

    SkPaint paint;
    paint.setColor(SK_ColorRED);
    canvas->drawCircle(400, 300, 100, paint);

    context->flush();
}
```

#### 新代码:
```cpp
#include "gpu/GrDirectContext.h"
#include "gpu/gl/GrGLInterface.h"
#include "core/SkSurface.h"

void setupSkia() {
    sk_sp<const GrGLInterface> interface = GrGLMakeNativeInterface();
    sk_sp<GrDirectContext> context = GrDirectContext::MakeGL(interface);

    SkImageInfo info = SkImageInfo::Make(800, 600,
                                          kRGBA_8888_SkColorType,
                                          kPremul_SkAlphaType);

    sk_sp<SkSurface> surface = SkSurfaces::RenderTarget(
        context.get(), skgpu::Budgeted::kNo, info);

    SkCanvas* canvas = surface->getCanvas();
    canvas->clear(SK_ColorWHITE);

    SkPaint paint;
    paint.setColor(SK_ColorRED);
    canvas->drawCircle(400, 300, 100, paint);

    context->flushAndSubmit();
}
```

### Qt集成示例

#### QSkiaOpenGLWidget 更新

**文件**: `QtSkia/QtSkiaWidget/QSkiaOpenGLWidget.cpp`

```cpp
// 旧
#include "gpu/GrContext.h"

class QSkiaOpenGLWidgetPrivate {
public:
    sk_sp<GrContext> grContext;
    sk_sp<SkSurface> gpuSurface;
};

void QSkiaOpenGLWidget::initializeGL() {
    sk_sp<const GrGLInterface> interface = GrGLMakeNativeInterface();
    m_dptr->grContext = GrContext::MakeGL(interface);
}

void QSkiaOpenGLWidget::paintGL() {
    // ...
    m_dptr->grContext->flush();
}
```

```cpp
// 新
#include "gpu/GrDirectContext.h"

class QSkiaOpenGLWidgetPrivate {
public:
    sk_sp<GrDirectContext> grContext;
    sk_sp<SkSurface> gpuSurface;
};

void QSkiaOpenGLWidget::initializeGL() {
    sk_sp<const GrGLInterface> interface = GrGLMakeNativeInterface();
    m_dptr->grContext = GrDirectContext::MakeGL(interface);
}

void QSkiaOpenGLWidget::paintGL() {
    // ...
    m_dptr->grContext->flushAndSubmit();
}
```

## 头文件变更清单

### 需要更新的include

```cpp
// GPU相关
#include "gpu/GrContext.h"              → #include "gpu/GrDirectContext.h"
#include "gpu/GrBackendSurface.h"       → #include "gpu/GrBackendSurface.h" (保持)

// Surface相关
#include "core/SkSurface.h"             → #include "core/SkSurface.h" (保持)
// 但使用 SkSurfaces:: 命名空间

// Image相关
#include "core/SkImage.h"               → #include "core/SkImage.h" (保持)
// 但使用 SkImages:: 命名空间
```

## 编译器要求

新版Skia要求：
- **C++17** 或更高
- **MSVC 2019** 或更高（Windows）
- **Clang 10** 或更高（macOS/Linux）
- **Python 3.8** 或更高

## 常见编译错误

### 错误1: 'GrContext' was not declared

```
error: 'GrContext' was not declared in this scope
```

**解决**: 替换为 `GrDirectContext`

### 错误2: 'MakeRenderTarget' is not a member of 'SkSurface'

```
error: 'MakeRenderTarget' is not a member of 'SkSurface'
```

**解决**: 使用 `SkSurfaces::RenderTarget()`

### 错误3: no matching function for call to 'flush'

```
error: no matching function for call to 'flush'
```

**解决**: 使用 `flushAndSubmit()`

## 性能优化建议

1. **使用Premultiplied Alpha**: `kPremul_SkAlphaType` 性能优于 `kUnpremul_SkAlphaType`

2. **批量提交**: 使用 `flushAndSubmit()` 而不是频繁调用 `flush()`

3. **资源管理**: 使用 `skgpu::Budgeted::kYes` 让Skia管理GPU资源

4. **避免频繁创建Surface**: 复用Surface对象

## 测试检查清单

升级后需要测试：

- [ ] 基本图形绘制（矩形、圆形、路径）
- [ ] 文本渲染
- [ ] 图片加载和显示
- [ ] GPU加速是否正常
- [ ] 内存泄漏检查
- [ ] 性能对比（FPS）
- [ ] 多线程渲染
- [ ] 窗口大小调整

## 参考链接

- [Skia API文档](https://api.skia.org/)
- [Skia变更日志](https://skia.googlesource.com/skia/+log)
- [Skia示例代码](https://skia.org/docs/user/sample/)
