cmake_minimum_required(VERSION 3.16)
project(ExifQmlReader VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_POLICY_QTP0001 NEW)

find_package(Qt6 REQUIRED COMPONENTS
    Gui Qml Quick QuickControls2 Positioning Location
)
find_package(PkgConfig REQUIRED)
pkg_check_modules(EXIV2 REQUIRED exiv2)

qt_add_executable(ExifQmlReader
    main.cpp
)

set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
qt_add_qml_module(ExifQmlReader
    URI ExifApp
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        main.qml
        ExifMap.qml
        ErrorToolTip.qml
        PhotoDetailPopup.qml
        Theme.qml
    SOURCES
        exifmodel.h exifmodel.cpp
        exifutils.h exifutils.cpp
        RESOURCES
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
