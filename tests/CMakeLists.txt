find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Test)

add_executable(test_kfinder_sanity
    test_sanity.cpp
)

target_link_libraries(test_kfinder_sanity PRIVATE
    Qt6::Core
    Qt6::Test
)

add_test(NAME test_kfinder_sanity COMMAND test_kfinder_sanity)

add_executable(test_model_spike
    test_model_spike.cpp
)

target_link_libraries(test_model_spike PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
)

add_test(NAME test_model_spike COMMAND test_model_spike)

add_executable(test_filelistmodel
    test_filelistmodel.cpp
    ../src/bridge/filelistmodel.cpp
)

target_include_directories(test_filelistmodel PRIVATE
    ../src
)

target_link_libraries(test_filelistmodel PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
    KF6::CoreAddons
    KF6::I18n
    KF6::KIOCore
    KF6::KIOGui
)

add_test(NAME test_filelistmodel COMMAND test_filelistmodel)
