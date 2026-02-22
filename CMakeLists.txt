cmake_minimum_required(VERSION 3.16)

project(ExifQmlReader VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Resolve o aviso QTP0001
set(QT_POLICY_QTP0001 NEW)

find_package(Qt6 REQUIRED COMPONENTS
    Gui Qml Quick QuickControls2 Positioning Location
)
find_package(PkgConfig REQUIRED)
pkg_check_modules(EXIV2 REQUIRED exiv2)

qt_add_executable(ExifQmlReader
    main.cpp
)

qt_add_qml_module(ExifQmlReader
    URI ExifApp
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        main.qml
    SOURCES
        exifmodel.cpp
        exifmodel.h
        exifutils.h
        exifutils.cpp
)

target_include_directories(ExifQmlReader PRIVATE ${EXIV2_INCLUDE_DIRS})

target_link_libraries(ExifQmlReader PRIVATE
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Positioning
    Qt6::Location
    ${EXIV2_LIBRARIES}
)
