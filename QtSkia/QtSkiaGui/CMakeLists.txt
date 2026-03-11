qtskia_enable_skia()

add_library(QtSkiaGui
    QSkiaOpenGLWindow.cpp
    QSkiaOpenGLWindow.h
    QSkiaVulkanWindow.cpp
    QSkiaVulkanWindow.h
)

target_link_libraries(QtSkiaGui
    PUBLIC
        Qt6::Core
        Qt6::Gui
        Qt6::OpenGL
        Skia::Skia
        QtSkiaCommon
)

target_include_directories(QtSkiaGui
    PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}"
)

qtskia_set_project_warnings(QtSkiaGui)
target_compile_definitions(QtSkiaGui PRIVATE QTSKIA_LIBRARY)
if(NOT BUILD_SHARED_LIBS)
    target_compile_definitions(QtSkiaGui PUBLIC QTSKIA_STATIC)
endif()
target_compile_definitions(QtSkiaGui PUBLIC QT_NO_FOREACH)
