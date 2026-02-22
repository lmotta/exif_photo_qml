import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtLocation
import QtPositioning
import QtQuick.Layouts

import ExifApp

ApplicationWindow {
    width: 600
    height: 800
    visible: true
    title: "Leitor EXIF Profissional"
    Material.theme: Material.Dark
    Material.accent: Material.DeepOrange

    ExifModel {
        id: exifModel
        onErrorOccurred: (message) => {
            console.log("⚠️ Erro de Backend:", message)
            errorMsg.show(message)
        }
        onVisibleRegionChanged: function (){
            if (exifModel.visibleRegion.isValid && !exifModel.visibleRegion.isEmpty)
                map.fitViewportToGeoShape(exifModel.visibleRegion, 50)
        }
    }

    FileDialog {
        id: fileDialog
        title: "Escolha uma imagem"
        nameFilters: ["Imagens (*.jpg *.jpeg *.png *.tiff)"]
        onAccepted: {
            exifModel.addPhoto( selectedFile )
        }
    }

    Plugin {
        id: osmPlugin
        name: "osm"
        PluginParameter { name: "osm.mapping.useragent"; value: "ExifQmlReader" }
        PluginParameter { name: "osm.mapping.custom.host"; value: "https://tile.openstreetmap.org/" }
        PluginParameter { name: "osm.mapping.cache.directory"; value: "/tmp/exif_map_cache" }
    }


    Popup {
        id: detailPopup
        anchors.centerIn: parent
        width: isMaximized ? parent.width - 40 : 350
        height: isMaximized ? parent.height - 40 : 550
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property alias photoName: titleLabel.text
        property alias photoPath: previewImage.source
        property alias photoDate: dateLabel.text

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

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Label {
                    id: titleLabel
                    font.bold: true
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
                Button {
                    text: detailPopup.isMaximized ? "❐" : "⬜"
                    flat: true
                    onClicked: detailPopup.isMaximized = !detailPopup.isMaximized
                }
                Button {
                    text: "✕"
                    flat: true
                    onClicked: detailPopup.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#111"
                radius: 4
                clip: true

                Image {
                    id: previewImage
                    anchors.fill: parent
                    anchors.margins: 10
                    source: detailPopup.photoPath
                    fillMode: Image.PreserveAspectFit
                    rotation: detailPopup.rotationAngle
                    antialiasing: true
                    Behavior on rotation { NumberAnimation { duration: 200 } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Column {
                    Layout.fillWidth: true
                    Label { id: dateLabel; color: "#aaa"; font.pixelSize: 11 }
                    Label {
                        text: isNaN(detailPopup.photoDirection)
                            ? "Sem valor de Direção"
                            : "Direção: " + detailPopup.photoDirection + "° (" + detailPopup.photoNorthType + ")"
                        color: "#aaa"; font.pixelSize: 11 }
                }
                Button {
                    text: "Rotacionar ↻"
                    Layout.fillWidth: true
                    onClicked: detailPopup.rotationAngle = (detailPopup.rotationAngle + 90) % 360
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Button {
            text: "Abrir Imagem"
            highlighted: true
            Layout.alignment: Qt.AlignHCenter
            onClicked: fileDialog.open()
        }

        Map {
            id: map
            Layout.fillWidth: true
            Layout.fillHeight: true

            plugin: osmPlugin

            center: QtPositioning.coordinate(-23.55, -46.63)
            zoomLevel: 4

            MapItemView {
                model: exifModel
                delegate: MapQuickItem {
                    coordinate: model.GeoCoordinate
                    anchorPoint.x: markerItem.width / 2
                    anchorPoint.y: !isNaN(model.Direction) ? markerItem.height / 2 : markerItem.height

                    sourceItem: Item {
                        id: markerItem
                        width: 80; height: 80

                        Canvas {
                            anchors.fill: parent
                            visible: !isNaN(model.Direction)
                            rotation: model.Direction

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var centerX = width / 2
                                var centerY = height / 2
                                ctx.beginPath()
                                ctx.moveTo(centerX, centerY)
                                // Desenha o cone voltado para o topo (que será rotacionado pelo 'rotation')
                                ctx.arc(centerX, centerY, width * 0.5, (Math.PI * 1.5) - 0.5, (Math.PI * 1.5) + 0.5)
                                ctx.closePath()
                                ctx.fillStyle = Qt.rgba(1, 0.34, 0.2, 0.4)
                                ctx.fill()
                            }
                        }

                        Rectangle {
                            width: 16; height: 16
                            color: Material.accent
                            radius: 8
                            border.color: "white"
                            border.width: 2
                            anchors.centerIn: parent

                            SequentialAnimation on scale {
                                running: true
                                PauseAnimation { duration: 600 } // Waiting visibleRegion changed
                                NumberAnimation { from: 0; to: 2.0; duration: 400; easing.type: Easing.OutBack }
                                NumberAnimation { to: 1.0; duration: 300; easing.type: Easing.OutBounce }
                            }

                            Rectangle {
                                id: glowEffect
                                anchors.centerIn: parent
                                width: parent.width * 2.5
                                height: parent.height * 2.5
                                radius: width / 2
                                color: Material.accent
                                opacity: 0
                                visible: false
                                z: -1
                                SequentialAnimation on opacity {
                                    running: true
                                    PauseAnimation { duration: 600 } // Waiting visibleRegion changed
                                    PropertyAction { target: glowEffect; property: "visible"; value: true }
                                    NumberAnimation { from: 0; to: 0.5; duration: 200 }
                                    NumberAnimation { from: 0.5; to: 0; duration: 800 }
                                    PropertyAction { target: glowEffect; property: "visible"; value: false }
                                }
                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                detailPopup.photoName = model.Filepath.split('/').pop()
                                detailPopup.photoDate = model.Datetime.toLocaleString(Qt.locale("pt_BR"), "dd/MM/yyyy HH:mm:ss")
                                detailPopup.photoPath = "file://" + model.Filepath
                                detailPopup.photoDirection = model.Direction
                                detailPopup.photoNorthType = model.NorthIsTrue ? "Verdadeiro" : "Magnético"
                                detailPopup.open()
                                map.center = model.GeoCoordinate
                            }
                        }
                    }
                }
            }

            WheelHandler {
                acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                                 ? PointerDevice.Mouse | PointerDevice.TouchPad
                                 : PointerDevice.Mouse
                rotationScale: 5/120
                property: "zoomLevel"
            }
            DragHandler { target: null; onTranslationChanged: (delta) => map.pan(-delta.x, -delta.y) }

            Shortcut {
                enabled: map.zoomLevel < map.maximumZoomLevel
                // Aceita CTRL+, CTRL= (teclado comum) e CTRL+ do teclado numérico
                sequences: ["Ctrl++", "Ctrl+=", "StandardKey.ZoomIn"]
                context: Qt.ApplicationShortcut
                onActivated: map.zoomLevel = Math.floor(map.zoomLevel + 1)
            }

            Shortcut {
                enabled: map.zoomLevel > map.minimumZoomLevel
                // Aceita CTRL- e a tecla de menos do teclado numérico
                sequences: ["Ctrl+-", "StandardKey.ZoomOut"]
                context: Qt.ApplicationShortcut
                onActivated: map.zoomLevel = Math.ceil(map.zoomLevel - 1)
            }

            // Connections {
            //     target: exifModel
            //     function onVisibleRegionChanged() {
            //         if (exifModel.visibleRegion.isValid && !exifModel.visibleRegion.isEmpty)
            //             map.fitViewportToGeoShape(exifModel.visibleRegion, 50)
            //     }
            // }

            Behavior on center { CoordinateAnimation { duration: 500; easing.type: Easing.InOutQuad } }
            Behavior on zoomLevel { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

            Component.onCompleted: {
                // Last BaseMap (define by Plugin)
                activeMapType = supportedMapTypes[ supportedMapTypes.length - 1]
            }

        }
    }

    ToolTip {
        id: errorMsg
        text: ""
        timeout: 4000

        // Posicionamento absoluto no canto superior esquerdo
        x: 10
        y: 10

        // Customização para parecer um alerta
        contentItem: Text {
            text: errorMsg.text
            color: "white"
            font.pointSize: 10
        }

        background: Rectangle {
            color: "#E53935" // Vermelho Material
            radius: 4
            border.color: "#B71C1C"
        }

        // Efeito de entrada suave
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
        }
    }
}
