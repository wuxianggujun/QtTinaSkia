add_executable(HelloSkiaWidget
    main.cpp
    SkiaWidget.h
)

target_link_libraries(HelloSkiaWidget PRIVATE Qt6::Widgets QtSkiaWidget QtTinaSkiaRenderer)
qtskia_set_project_warnings(HelloSkiaWidget)
