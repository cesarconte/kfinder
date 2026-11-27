qt_add_executable(kfinder
    main.cpp
    bridge/filelistmodel.h
    bridge/filelistmodel.cpp
    bridge/placesmodel.h
    bridge/placesmodel.cpp
    core/fileitementry.h
)

target_include_directories(kfinder PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(kfinder PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::DBus
    KF6::CoreAddons
    KF6::I18n
    KF6::WindowSystem
    KF6::IconThemes
    KF6::KIOCore
    KF6::KIOGui
    KF6::KIOWidgets
    KF6::KIOFileWidgets
    KF6::Solid
    KF6::FileMetaData
    KF6::DBusAddons
    KF6::Crash
    KF6::Notifications
    CachyOSUI::cachyosui
)

qt_add_qml_module(kfinder
    URI org.cesar.kfinder
    VERSION 1.0
    QML_FILES
        qml/Main.qml
)

install(TARGETS kfinder ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
