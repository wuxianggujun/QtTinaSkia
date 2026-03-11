add_executable(HelloSkiaQuickWindow
    main.cpp
    SkiaQuickWindow.h
)

target_link_libraries(HelloSkiaQuickWindow PRIVATE Qt6::Quick QtSkiaQuick)
target_link_libraries(HelloSkiaQuickWindow PRIVATE QtTinaSkiaRenderer)
qtskia_set_project_warnings(HelloSkiaQuickWindow)
