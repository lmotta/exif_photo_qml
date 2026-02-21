import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtLocation
import QtPositioning
import QtQuick.Layouts // IMPORTANTE: Adicionado para o Layout.fillWidth

import ExifApp

ApplicationWindow {
    id: window
    width: 600
    height: 800
    visible: true
    title: "Leitor EXIF Profissional"
    Material.theme: Material.Dark
    Material.accent: Material.DeepOrange

    ExifModel { id: exifModel }

    FileDialog {
        id: fileDialog
        title: "Escolha uma imagem"
        nameFilters: ["Imagens (*.jpg *.jpeg *.png *.tiff)"]
        onAccepted: {
            exifModel.addPhoto( selectedFile )
        }
    }

    Plugin {
        id: mapPlugin
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

        property string photoName: ""
        property string photoDate: ""
        property string photoPath: ""
        property double photoDirection: 0
        property string photoNorthType: ""

        property int rotationAngle: 0
        property bool isMaximized: false

        onAboutToShow: {
            rotationAngle = 0
            isMaximized = false
        }

        // Transição suave de tamanho
        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // Barra de Título
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: detailPopup.photoName
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

            // Image
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

            // Controles
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Rotacionar ↻"
                    Layout.fillWidth: true
                    onClicked: detailPopup.rotationAngle = (detailPopup.rotationAngle + 90) % 360
                }
            }

            Column {
                Layout.fillWidth: true
                Label { text: "Data: " + detailPopup.photoDate; color: "#aaa"; font.pixelSize: 11 }
                Label {
                    text: "Direção: " + detailPopup.photoDirection + "° (" + detailPopup.photoNorthType + ")";
                    color: "#aaa"; font.pixelSize: 11 }
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
            plugin: mapPlugin
            center: QtPositioning.coordinate(-23.55, -46.63)
            zoomLevel: 4

            MapItemView {
                model: exifModel
                delegate: MapQuickItem {
                    coordinate: model.GeoCoordinate
                    anchorPoint.x: markerItem.width / 2
                    anchorPoint.y: model.NorthIsTrue ? markerItem.height / 2 : markerItem.height

                    sourceItem: Item {
                        id: markerItem
                        width: 80; height: 80

                        Canvas {
                            id: directionCone
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
                            id: simplePin
                            width: 16; height: 16
                            color: Material.accent
                            radius: 8
                            border.color: "white"
                            border.width: 2
                            anchors.centerIn: parent
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
                id: wheel
                // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
                // Magic Mouse pretends to be a trackpad but doesn't work with PinchHandler
                // and we don't yet distinguish mice and trackpads on Wayland either
                acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                                 ? PointerDevice.Mouse | PointerDevice.TouchPad
                                 : PointerDevice.Mouse
                rotationScale: 5/120
                property: "zoomLevel"
            }
            DragHandler { id: drag; target: null; onTranslationChanged: (delta) => map.pan(-delta.x, -delta.y) }

            Shortcut {
                enabled: map.zoomLevel < map.maximumZoomLevel
                sequence: StandardKey.ZoomIn
                onActivated: map.zoomLevel = Math.round(map.zoomLevel + 1)
            }
            Shortcut {
                enabled: map.zoomLevel > map.minimumZoomLevel
                sequence: StandardKey.ZoomOut
                onActivated: map.zoomLevel = Math.round(map.zoomLevel - 1)
            }

            Connections {
                target: exifModel
                function onVisibleRegionChanged() {
                    if (exifModel.visibleRegion.isValid && !exifModel.visibleRegion.isEmpty)
                        map.fitViewportToGeoShape(exifModel.visibleRegion, 50, 50)
                }
            }

            Behavior on center { CoordinateAnimation { duration: 500; easing.type: Easing.InOutQuad } }
            Behavior on zoomLevel { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

            Component.onCompleted: {
                // Last BaseMap
                activeMapType = supportedMapTypes[ supportedMapTypes.length - 1]
            }

        }
    }
}
