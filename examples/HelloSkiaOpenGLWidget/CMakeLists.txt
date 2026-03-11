add_executable(HelloSkiaOpenGLWidget
    main.cpp
    SkiaGLWidget.h
)

target_link_libraries(HelloSkiaOpenGLWidget PRIVATE Qt6::Widgets Qt6::OpenGLWidgets QtSkiaWidget)
target_link_libraries(HelloSkiaOpenGLWidget PRIVATE QtTinaSkiaRenderer)
qtskia_set_project_warnings(HelloSkiaOpenGLWidget)
