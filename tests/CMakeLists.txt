find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Test)

add_executable(test_kfinder_sanity
    test_sanity.cpp
)

target_link_libraries(test_kfinder_sanity PRIVATE
    Qt6::Core
    Qt6::Test
)

add_test(NAME test_kfinder_sanity COMMAND test_kfinder_sanity)
