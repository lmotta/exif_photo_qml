pragma Singleton
import QtQuick

Item {
    // Main colors
    readonly property color primary: "#FF5722"   // Deep Orange
    readonly property color background: "#121212"
    readonly property color surface: "#1E1E1E"
    readonly property color error: "#E53935"

    // Text
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#AAAAAA"

    // Spacing and Radius
    readonly property int paddingSmall: 8
    readonly property int paddingMedium: 16
    readonly property int radius: 4

    // Sources
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 14
}
