#include "ShaderRender.h"

#include "effects/SkDashPathEffect.h"
#include "effects/SkDiscretePathEffect.h"
#include "effects/SkGradient.h"
#include "core/SkPathBuilder.h"
static SkPath star()
{
    const SkScalar R = 115.2f, C = 128.0f;
    SkPathBuilder builder;
    builder.moveTo(C + R, C);
    for (int i = 1; i < 8; ++i) {
        SkScalar a = 2.6927937f * i;
        builder.lineTo(C + R * cos(a), C + R * sin(a));
    }
    return builder.detach();
}

void ShaderRender::draw(SkCanvas* canvas, int elapsed, int w, int h)
{
    canvas->clear(SK_ColorWHITE);
    canvas->drawPath(path, paint);
}

void ShaderRender::init(int w, int h)
{
    paint.setPathEffect(SkDiscretePathEffect::Make(10.0f, 4.0f));
    SkPoint points[2] = {
        SkPoint::Make(0.0f, 0.0f),
        SkPoint::Make(256.0f, 256.0f)
    };
    SkColor4f colors[2] = {
        SkColor4f::FromColor(SkColorSetRGB(66, 133, 244)),
        SkColor4f::FromColor(SkColorSetRGB(15, 157, 88)),
    };
    SkGradient::Colors gradColors(SkSpan(colors, 2), {}, SkTileMode::kClamp);
    SkGradient grad(gradColors, SkGradient::Interpolation{});
    paint.setShader(SkShaders::LinearGradient(points, grad));
    paint.setAntiAlias(true);
    path = star();
}

void ShaderRender::resize(int w, int h)
{
}
