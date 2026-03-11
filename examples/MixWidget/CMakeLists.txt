qt_add_executable(MixWidget
    main.cpp
    MainWindow.cpp
    MainWindow.h
    MainWindow.ui
    SkWidget.cpp
    SkWidget.h
)

target_link_libraries(MixWidget PRIVATE Qt6::Widgets QtSkiaWidget QtTinaSkiaRenderer)
qtskia_set_project_warnings(MixWidget)

