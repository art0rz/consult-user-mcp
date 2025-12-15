cmake_minimum_required(VERSION 3.16)
project(ConsultUserDialog LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick Qml)

add_executable(consult-user-dialog
    src/main.cpp
    qml/qml.qrc
)

target_link_libraries(consult-user-dialog
    PRIVATE Qt6::Quick Qt6::Qml
)

install(TARGETS consult-user-dialog RUNTIME DESTINATION bin)
install(DIRECTORY qml DESTINATION .)
