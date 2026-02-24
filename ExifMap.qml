import QtQuick
import QtLocation
import QtPositioning
import QtQuick.Controls.Material

Map {
    id: map
    property alias model: itemView.model
    signal photoClicked(string name, string path, date timestamp, double direction, string northType)

    plugin: Plugin {
        id: osmPlugin
        name: "osm"
        PluginParameter { name: "osm.mapping.useragent"; value: "ExifQmlReader" }
        PluginParameter { name: "osm.mapping.custom.host"; value: "https://tile.openstreetmap.org/" }
        PluginParameter { name: "osm.mapping.cache.directory"; value: "/tmp/exif_map_cache" }
    }

    center: QtPositioning.coordinate(-23.55, -46.63)
    zoomLevel: 4

    MapItemView {
        id: itemView
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
                        PauseAnimation { duration: 600 }
                        NumberAnimation { from: 0; to: 2.0; duration: 400; easing.type: Easing.OutBack }
                        NumberAnimation { to: 1.0; duration: 300; easing.type: Easing.OutBounce }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        map.photoClicked(
                            model.Filepath.split('/').pop(),
                            "file://" + model.Filepath,
                            model.Datetime,
                            model.Direction,
                            model.NorthIsTrue ? "Verdadeiro" : "Magnético"
                        )
                        map.center = model.GeoCoordinate
                    }
                }
            }
        }
    }

    // Handlers e Atalhos
    WheelHandler {
        acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                         ? PointerDevice.Mouse | PointerDevice.TouchPad : PointerDevice.Mouse
        rotationScale: 5/120
        property: "zoomLevel"
    }
    DragHandler { target: null; onTranslationChanged: (delta) => map.pan(-delta.x, -delta.y) }

    Behavior on center { CoordinateAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    Behavior on zoomLevel { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

    Component.onCompleted: {
        activeMapType = supportedMapTypes[supportedMapTypes.length - 1]
    }
}
