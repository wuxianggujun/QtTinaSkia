#include "QSkiaOpenGLWidget.h"

#include "core/SkCanvas.h"
#include "core/SkImageInfo.h"
#include "core/SkSurface.h"
#include "gpu/ganesh/GrDirectContext.h"
#include "gpu/ganesh/gl/GrGLDirectContext.h"
#include "gpu/ganesh/gl/GrGLInterface.h"
#include "gpu/ganesh/SkSurfaceGanesh.h"

#include <QOpenGLFunctions>
#include <QElapsedTimer>
#include <QTimer>
#include <QGuiApplication>
#include <QScreen>
#include <QDebug>
class QSkiaOpenGLWidgetPrivate {
public:
    QOpenGLFunctions funcs;
    sk_sp<const GrGLInterface> glInterface = nullptr;
    sk_sp<GrDirectContext> context = nullptr;
    sk_sp<SkSurface> gpuSurface = nullptr;
    SkImageInfo info;
    QTimer timer;
    QElapsedTimer lastTime;
};
QSkiaOpenGLWidget::QSkiaOpenGLWidget(QWidget* parent)
    : QOpenGLWidget(parent)
    , m_dptr(new QSkiaOpenGLWidgetPrivate)
{
    connect(&m_dptr->timer, &QTimer::timeout, this, QOverload<>::of(&QSkiaOpenGLWidget::update));
    m_dptr->timer.start(1000 / qRound(qApp->primaryScreen()->refreshRate()));
}

QSkiaOpenGLWidget::~QSkiaOpenGLWidget()
{
    makeCurrent();
    m_dptr->gpuSurface = nullptr;
    if (m_dptr->context) {
        m_dptr->context->releaseResourcesAndAbandonContext();
        m_dptr->context = nullptr;
    }
    delete m_dptr;
    m_dptr = nullptr;
    doneCurrent();
}

void QSkiaOpenGLWidget::initializeGL()
{
    m_dptr->funcs.initializeOpenGLFunctions();
    m_dptr->glInterface = GrGLMakeNativeInterface();
    m_dptr->context = GrDirectContexts::MakeGL(m_dptr->glInterface);
    SkASSERT(m_dptr->context);
    init(this->width(), this->height());
    m_dptr->lastTime.start();
}

void QSkiaOpenGLWidget::resizeGL(int w, int h)
{
    if (this->width() == w && this->height() == h) {
        return;
    }
    init(w, h);
}

void QSkiaOpenGLWidget::init(int w, int h)
{
    m_dptr->info = SkImageInfo::MakeN32Premul(w, h);
    m_dptr->gpuSurface = SkSurfaces::RenderTarget(m_dptr->context.get(),
        skgpu::Budgeted::kNo, m_dptr->info);
    if (!m_dptr->gpuSurface) {
        qDebug() << "SkSurface::MakeRenderTarget return null";
        return;
    }
    m_dptr->funcs.glViewport(0, 0, w, h);
}

void QSkiaOpenGLWidget::paintGL()
{
    if (!this->isVisible()) {
        return;
    }
    if (!m_dptr->gpuSurface) {
        return;
    }
    auto canvas = m_dptr->gpuSurface->getCanvas();
    if (!canvas) {
        return;
    }
    const auto elapsed = static_cast<int>(m_dptr->lastTime.restart());
    canvas->save();
    this->draw(canvas, elapsed);
    canvas->restore();
    m_dptr->context->flushAndSubmit();
}
