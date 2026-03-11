qtskia_enable_skia()

add_library(QtSkiaQuick
    QuickItem/QSkiaQuickItem.cpp
    QuickItem/QSkiaQuickItem.h
    QuickWindow/QSkiaQuickWindow.cpp
    QuickWindow/QSkiaQuickWindow.h
)

target_link_libraries(QtSkiaQuick
    PUBLIC
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::OpenGL
        Skia::Skia
        QtSkiaCommon
)

target_include_directories(QtSkiaQuick
    PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CMAKE_CURRENT_SOURCE_DIR}/QuickItem"
        "${CMAKE_CURRENT_SOURCE_DIR}/QuickWindow"
)

qtskia_set_project_warnings(QtSkiaQuick)
target_compile_definitions(QtSkiaQuick PRIVATE QTSKIA_LIBRARY)
if(NOT BUILD_SHARED_LIBS)
    target_compile_definitions(QtSkiaQuick PUBLIC QTSKIA_STATIC)
endif()
target_compile_definitions(QtSkiaQuick PUBLIC QT_NO_FOREACH)
