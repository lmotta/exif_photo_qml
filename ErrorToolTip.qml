import QtQuick
import QtQuick.Controls

ToolTip {
    id: control
    timeout: 4000
    x: 10
    y: 10

    contentItem: Text {
        text: control.text
        color: "white"
        font.pointSize: 10
    }

    background: Rectangle {
        color: "#E53935"
        radius: 4
        border.color: "#B71C1C"
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
    }
}
