add_executable(HelloSkiaOpenGLWindow
    main.cpp
    SkiaGLWindow.h
)

target_link_libraries(HelloSkiaOpenGLWindow PRIVATE Qt6::Gui Qt6::OpenGL QtSkiaGui)
qtskia_set_project_warnings(HelloSkiaOpenGLWindow)

