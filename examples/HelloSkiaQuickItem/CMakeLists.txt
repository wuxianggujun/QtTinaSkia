qt_add_executable(HelloSkiaQuickItem
    main.cpp
    SkiaQuickItem.h
    Qml.qrc
)

target_link_libraries(HelloSkiaQuickItem PRIVATE Qt6::Quick QtSkiaQuick)
target_link_libraries(HelloSkiaQuickItem PRIVATE QtTinaSkiaRenderer)
qtskia_set_project_warnings(HelloSkiaQuickItem)
