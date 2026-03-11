qtskia_enable_skia()

add_library(QtSkiaWidget
    QSkiaWidget.cpp
    QSkiaWidget.h
    QSkiaOpenGLWidget.cpp
    QSkiaOpenGLWidget.h
)

target_link_libraries(QtSkiaWidget
    PUBLIC
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
        Qt6::OpenGL
        Qt6::OpenGLWidgets
        Skia::Skia
        QtSkiaCommon
)

target_include_directories(QtSkiaWidget
    PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}"
)

qtskia_set_project_warnings(QtSkiaWidget)
target_compile_definitions(QtSkiaWidget PRIVATE QTSKIA_LIBRARY)
if(NOT BUILD_SHARED_LIBS)
    target_compile_definitions(QtSkiaWidget PUBLIC QTSKIA_STATIC)
endif()
target_compile_definitions(QtSkiaWidget PUBLIC QT_NO_FOREACH)
