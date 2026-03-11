qt_add_executable(FeatureShow
    main.cpp
    SkiaItem.h
    Qml.qrc
)

target_link_libraries(FeatureShow PRIVATE Qt6::Quick QtSkiaQuick QtTinaSkiaRenderer)
qtskia_set_project_warnings(FeatureShow)
