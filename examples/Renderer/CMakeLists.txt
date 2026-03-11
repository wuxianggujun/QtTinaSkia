add_library(QtTinaSkiaRenderer
    BezierRender.cpp
    BezierRender.h
    ComposeRender.cpp
    ComposeRender.h
    DiscretePathRender.cpp
    DiscretePathRender.h
    RotationsRender.cpp
    RotationsRender.h
    SampleRender.cpp
    SampleRender.h
    ShaderRender.cpp
    ShaderRender.h
    ShapesRender.cpp
    ShapesRender.h
    SumPathRender.cpp
    SumPathRender.h
    TextRender.cpp
    TextRender.h
    IRender.h
)

target_link_libraries(QtTinaSkiaRenderer
    PUBLIC
        Qt6::Core
        Qt6::Gui
        Skia::Skia
)

target_include_directories(QtTinaSkiaRenderer
    PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}"
)

qtskia_set_project_warnings(QtTinaSkiaRenderer)
