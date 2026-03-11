# Qt6 适配指南

本文档说明从Qt5迁移到Qt6时，QtSkia项目需要进行的适配工作。

## 目录

- [Qt6主要变化](#qt6主要变化)
- [RHI渲染系统](#rhi渲染系统)
- [QQuickItem适配](#qquickitem适配)
- [OpenGL相关变化](#opengl相关变化)
- [构建系统变化](#构建系统变化)
- [代码清理](#代码清理)

## Qt6主要变化

### 1. 渲染架构变化

Qt6引入了RHI (Rendering Hardware Interface)，统一了不同图形API的接口：

- **OpenGL** (桌面和移动)
- **Vulkan** (跨平台)
- **Metal** (macOS/iOS)
- **Direct3D 11** (Windows)

**影响**: QtSkia需要适配RHI系统，不能再直接假设使用OpenGL。

### 2. 模块重组

```cpp
// Qt5
#include <QtWidgets>
#include <QOpenGLWidget>

// Qt6 (保持不变，但某些类移动了)
#include <QtWidgets>
#include <QOpenGLWidget>  // 仍然可用
```

### 3. 废弃的API

- `QMatrix` → `QTransform`
- `QGL*` 类 → `QOpenGL*` 类（Qt5.0已迁移，Qt6移除旧类）
- 某些信号/槽宏定义

## RHI渲染系统

### 概述

Qt6的Quick场景图默认使用RHI，不再直接暴露OpenGL上下文。

### QQuickItem中获取图形API信息

```cpp
#include <QQuickWindow>
#include <QSGRendererInterface>

void MyQuickItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) {
    QSGRendererInterface *rif = window()->rendererInterface();

    // 检查当前使用的图形API
    switch (rif->graphicsApi()) {
        case QSGRendererInterface::OpenGL:
            // 使用OpenGL路径
            break;
        case QSGRendererInterface::Vulkan:
            // 使用Vulkan路径
            break;
        case QSGRendererInterface::Direct3D11:
            // 使用D3D11路径
            break;
        case QSGRendererInterface::Metal:
            // 使用Metal路径
            break;
        default:
            // 软件渲染或其他
            break;
    }
}
```

### 获取原生图形资源

```cpp
// Qt5: 直接获取OpenGL上下文
QOpenGLContext *glContext = window()->openglContext();

// Qt6: 通过RHI获取
QSGRendererInterface *rif = window()->rendererInterface();
if (rif->graphicsApi() == QSGRendererInterface::OpenGL) {
    QOpenGLContext *glContext =
        static_cast<QOpenGLContext*>(
            rif->getResource(window(),
                           QSGRendererInterface::OpenGLContextResource));
}
```

## QQuickItem适配

### 1. 纹理创建变化

#### Qt5代码:
```cpp
#include <QQuickWindow>
#include <QSGSimpleTextureNode>

class TextureNode : public QSGSimpleTextureNode {
public:
    TextureNode(QQuickWindow* window) : m_window(window) {
        // Qt5: 从OpenGL纹理ID创建
        m_texture = m_window->createTextureFromId(textureId,
                                                   QSize(width, height));
        setTexture(m_texture);
    }

private:
    QQuickWindow* m_window;
    QSGTexture* m_texture;
};
```

#### Qt6代码:
```cpp
#include <QQuickWindow>
#include <QSGSimpleTextureNode>
#include <QSGRendererInterface>

class TextureNode : public QSGSimpleTextureNode {
public:
    TextureNode(QQuickWindow* window) : m_window(window) {
        // Qt6: 使用createTextureFromNativeObject
        QSGRendererInterface *rif = window->rendererInterface();

        if (rif->graphicsApi() == QSGRendererInterface::OpenGL) {
            // OpenGL路径
            quint64 nativeTexture = textureId;
            m_texture = m_window->createTextureFromNativeObject(
                QQuickWindow::NativeObjectTexture,
                &nativeTexture,
                0,  // flags
                QSize(width, height),
                QQuickWindow::TextureHasAlphaChannel);
        }

        setTexture(m_texture);
    }

private:
    QQuickWindow* m_window;
    QSGTexture* m_texture;
};
```

### 2. 场景图节点更新

```cpp
// Qt5和Qt6基本相同，但需要注意线程安全
QSGNode* QSkiaQuickItem::updatePaintNode(QSGNode *oldNode,
                                          UpdatePaintNodeData *data) {
    TextureNode *node = static_cast<TextureNode*>(oldNode);

    if (!node) {
        node = new TextureNode(window());
    }

    // 更新纹理
    node->updateTexture(m_textureId, size());

    return node;
}
```

### 3. 渲染线程同步

Qt6对渲染线程的要求更严格：

```cpp
class QSkiaQuickItem : public QQuickItem {
    Q_OBJECT

public:
    QSkiaQuickItem(QQuickItem *parent = nullptr)
        : QQuickItem(parent) {
        // 重要：启用场景图渲染
        setFlag(ItemHasContents, true);
    }

protected:
    QSGNode* updatePaintNode(QSGNode *oldNode,
                            UpdatePaintNodeData *data) override {
        // 这个函数在渲染线程调用
        // 不要在这里访问QML属性或发射信号

        // 使用信号槽在渲染线程和主线程间通信
        return node;
    }

signals:
    void textureReady(uint textureId, const QSize &size);

private slots:
    void handleTextureReady(uint textureId, const QSize &size) {
        // 在主线程处理
        update();  // 触发重绘
    }
};
```

## OpenGL相关变化

### 1. QOpenGLWidget

Qt6中`QOpenGLWidget`仍然可用，API基本不变：

```cpp
#include <QOpenGLWidget>
#include <QOpenGLFunctions>

class QSkiaOpenGLWidget : public QOpenGLWidget {
protected:
    void initializeGL() override {
        // 初始化OpenGL
        initializeOpenGLFunctions();

        // 初始化Skia
        sk_sp<const GrGLInterface> interface = GrGLMakeNativeInterface();
        m_grContext = GrDirectContext::MakeGL(interface);
    }

    void paintGL() override {
        // 绘制
        SkCanvas* canvas = m_surface->getCanvas();
        // ... 绘制操作

        m_grContext->flushAndSubmit();
    }

    void resizeGL(int w, int h) override {
        // 重建surface
        recreateSurface(w, h);
    }
};
```

### 2. QOpenGLFunctions

```cpp
// Qt5和Qt6相同
class MyWidget : public QOpenGLWidget, protected QOpenGLFunctions {
public:
    void initializeGL() override {
        initializeOpenGLFunctions();

        // 使用OpenGL函数
        glClearColor(0, 0, 0, 1);
        glEnable(GL_DEPTH_TEST);
    }
};
```

### 3. OpenGL上下文管理

```cpp
// 获取当前上下文
QOpenGLContext *ctx = QOpenGLContext::currentContext();

// 确保上下文激活
makeCurrent();
// ... OpenGL操作
doneCurrent();
```

## 构建系统变化

### 1. qmake项目文件

```qmake
# Qt5
QT += core gui widgets quick

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

# Qt6 (简化)
QT += core gui widgets quick

# 不再需要版本检查
```

### 2. CMake配置

```cmake
# Qt5
find_package(Qt5 REQUIRED COMPONENTS Core Gui Widgets Quick)

target_link_libraries(myapp
    Qt5::Core
    Qt5::Gui
    Qt5::Widgets
    Qt5::Quick
)

# Qt6
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick)

target_link_libraries(myapp
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Quick
)
```

### 3. 移除Qt5兼容代码

搜索并移除：

```bash
# 查找Qt版本检查
grep -r "QT_VERSION_CHECK" .
grep -r "QT_VERSION <" .
grep -r "QT_VERSION >=" .
grep -r "#if QT_VERSION" .

# 查找Qt5特定代码
grep -r "greaterThan(QT_MAJOR_VERSION" .
```

## 代码清理

### 1. 移除Qt5条件编译

#### 清理前:
```cpp
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    // Qt5代码
    m_texture = window()->createTextureFromId(id, size);
#else
    // Qt6代码
    m_texture = window()->createTextureFromNativeObject(...);
#endif
```

#### 清理后:
```cpp
// 只保留Qt6代码
m_texture = window()->createTextureFromNativeObject(...);
```

### 2. 更新信号槽连接

```cpp
// 旧式连接（仍然可用，但不推荐）
connect(obj, SIGNAL(valueChanged(int)),
        this, SLOT(onValueChanged(int)));

// 新式连接（推荐，类型安全）
connect(obj, &MyObject::valueChanged,
        this, &MyClass::onValueChanged);
```

### 3. 移除废弃的API

```cpp
// 移除 QMatrix，使用 QTransform
// QMatrix matrix;  // 移除
QTransform transform;  // 使用

// 移除 QRegExp，使用 QRegularExpression
// QRegExp rx("pattern");  // 移除
QRegularExpression rx("pattern");  // 使用
```

## 具体文件修改清单

### QtSkia/QtSkiaQuick/QuickItem/QSkiaQuickItem.cpp

**需要修改的部分**:

1. 纹理创建方式
2. 添加RHI支持检测
3. 更新线程同步机制

**修改示例**:

```cpp
// 添加头文件
#include <QSGRendererInterface>

// 在updatePaintNode中
QSGNode* QSkiaQuickItem::updatePaintNode(QSGNode *oldNode,
                                          UpdatePaintNodeData *) {
    TextureNode *node = static_cast<TextureNode*>(oldNode);

    if (!node) {
        node = new TextureNode(window());

        // 检查图形API
        QSGRendererInterface *rif = window()->rendererInterface();
        if (rif->graphicsApi() != QSGRendererInterface::OpenGL) {
            qWarning() << "QtSkia currently only supports OpenGL backend";
            // 可以考虑添加其他后端支持
        }
    }

    // 更新节点
    node->setRect(boundingRect());
    node->markDirty(QSGNode::DirtyGeometry);

    return node;
}
```

### QtSkia/QtSkiaQuick/QuickWindow/QSkiaQuickWindow.cpp

**需要修改的部分**:

1. 获取OpenGL上下文的方式
2. 适配RHI系统

**修改示例**:

```cpp
void QSkiaQuickWindow::initializeSkia() {
    QSGRendererInterface *rif = rendererInterface();

    if (rif->graphicsApi() == QSGRendererInterface::OpenGL) {
        // 获取OpenGL上下文
        QOpenGLContext *glContext =
            static_cast<QOpenGLContext*>(
                rif->getResource(this,
                               QSGRendererInterface::OpenGLContextResource));

        if (glContext) {
            glContext->makeCurrent(this);

            // 初始化Skia
            sk_sp<const GrGLInterface> interface = GrGLMakeNativeInterface();
            m_grContext = GrDirectContext::MakeGL(interface);

            glContext->doneCurrent();
        }
    }
}
```

## 测试要点

### 1. 基本功能测试

- [ ] QWidget集成正常工作
- [ ] QOpenGLWidget集成正常工作
- [ ] QQuickItem集成正常工作
- [ ] QQuickWindow集成正常工作

### 2. 渲染测试

- [ ] 基本图形绘制正确
- [ ] 文本渲染正确
- [ ] 图片加载和显示正确
- [ ] GPU加速工作正常

### 3. 性能测试

- [ ] 帧率稳定
- [ ] 内存使用正常
- [ ] CPU占用合理

### 4. 平台测试

- [ ] Windows (OpenGL/D3D11)
- [ ] Linux (OpenGL/Vulkan)
- [ ] macOS (Metal)
- [ ] Android (OpenGL ES/Vulkan)

## 常见问题

### Q1: QQuickItem渲染黑屏

**原因**: 纹理创建方式不正确

**解决**: 使用`createTextureFromNativeObject`而不是`createTextureFromId`

### Q2: 编译错误：找不到QOpenGLWidget

**原因**: Qt6中需要显式链接OpenGL模块

**解决**:
```qmake
QT += opengl openglwidgets
```

或CMake:
```cmake
find_package(Qt6 REQUIRED COMPONENTS OpenGLWidgets)
target_link_libraries(myapp Qt6::OpenGLWidgets)
```

### Q3: 运行时警告：RHI backend not supported

**原因**: 当前平台不支持选择的图形API

**解决**: 设置环境变量强制使用OpenGL:
```bash
export QSG_RHI_BACKEND=opengl
```

## 参考资源

- Qt6迁移指南: https://doc.qt.io/qt-6/portingguide.html
- Qt6 RHI文档: https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html
- QQuickItem文档: https://doc.qt.io/qt-6/qquickitem.html
- QOpenGLWidget文档: https://doc.qt.io/qt-6/qopenglwidget.html
