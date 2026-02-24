import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    anchors.centerIn: parent
    width: isMaximized ? parent.width - 40 : 350
    height: isMaximized ? parent.height - 40 : 550
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string photoName: ""
    property string photoPath: ""
    property var photoDate: new Date()
    property double photoDirection: 0
    property string photoNorthType: ""
    property int rotationAngle: 0
    property bool isMaximized: false

    onAboutToShow: {
        rotationAngle = 0
        isMaximized = false
    }

    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radius
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.paddingSmall

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: root.photoName
                font.bold: true
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
            Button {
                text: root.isMaximized ? "❐" : "⬜"
                flat: true
                onClicked: root.isMaximized = !root.isMaximized
            }
            Button {
                text: "✕"
                flat: true
                onClicked: root.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#111"
            radius: 4
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: 10
                source: root.photoPath
                fillMode: Image.PreserveAspectFit
                rotation: root.rotationAngle
                antialiasing: true
                Behavior on rotation { NumberAnimation { duration: 200 } }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Column {
                Layout.fillWidth: true
                Label {
                    text: root.photoDate.toLocaleString(Qt.locale("pt_BR"), "dd/MM/yyyy HH:mm:ss")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                }
                Label {
                    text: isNaN(root.photoDirection)
                        ? "Sem valor de Direção"
                        : "Direção: " + root.photoDirection + "° (" + root.photoNorthType + ")"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
            Button {
                text: "Rotacionar ↻"
                Layout.fillWidth: true
                onClicked: root.rotationAngle = (root.rotationAngle + 90) % 360
            }
        }
    }
}
