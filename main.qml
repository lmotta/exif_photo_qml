import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtQuick.Layouts
import ExifApp

ApplicationWindow {
    width: 600
    height: 800
    visible: true
    title: "Leitor EXIF"
    Material.theme: Material.Dark
    Material.accent: Material.DeepOrange

    ExifModel {
        id: exifModel
        onErrorOccurred: (message) => errorMsg.show(message)
        onVisibleRegionChanged: {
            if (visibleRegion.isValid && !visibleRegion.isEmpty)
                map.fitViewportToGeoShape(visibleRegion, 50)
        }
    }

    FileDialog {
        id: fileDialog
        title: "Escolha uma imagem"
        nameFilters: ["Imagens (*.jpg *.jpeg *.png *.tiff)"]
        onAccepted: exifModel.addPhoto(selectedFile)
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

        ExifMap {
            id: map
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: exifModel

            onPhotoClicked: (name, path, timestamp, direction, northType) => {
                detailPopup.photoName = name
                detailPopup.photoPath = path
                detailPopup.photoDate = timestamp
                detailPopup.photoDirection = direction
                detailPopup.photoNorthType = northType
                detailPopup.open()
            }
        }
    }

    PhotoDetailPopup {
        id: detailPopup
    }

    ErrorToolTip {
        id: errorMsg
        background: Rectangle {
                color: Theme.error
                radius: Theme.radius
            }
    }
}
