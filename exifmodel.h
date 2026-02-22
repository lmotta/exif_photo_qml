#ifndef EXIFMODEL_H
#define EXIFMODEL_H

#include <QAbstractListModel>
#include <QDateTime>
#include <QUrl>
#include <QGeoCoordinate>
#include <QGeoRectangle>
#include <QtQml/qqmlregistration.h>


struct ExifPhoto {
    QString filepath;
    QDateTime datetime;
    QGeoCoordinate geoCoordinate;
    double direction;
    bool northIsTrue;
};

class ExifModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QGeoRectangle visibleRegion READ visibleRegion NOTIFY visibleRegionChanged)

public:
    explicit ExifModel(QObject *parent = nullptr) {};

    enum ExifRoles {
        FilepathRole = Qt::UserRole + 1,
        DatetimeRole,
        GeoCoordinateRole,
        DirectionRole,
        NorthIsTrueRole
    };

    QHash<int, QByteArray> roleNames() const override {
        return {
            { FilepathRole, "Filepath" },
            { DatetimeRole, "Datetime" },
            { GeoCoordinateRole, "GeoCoordinate" },
            { DirectionRole, "Direction" },
            { NorthIsTrueRole, "NorthIsTrue" }
        };
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        return parent.isValid() ? 0 : m_items.count();
    }

    QVariant data(const QModelIndex &index, int role) const override;

    Q_INVOKABLE void addPhoto(const QUrl &fileUrl);

    // Q_PROPERTY visibleRegion need getter function
    QGeoRectangle visibleRegion() const {
        return m_visibleRegion;
    }
signals:
    void visibleRegionChanged();
    void errorOccurred(QString message );
private:
    QList<ExifPhoto> m_items;
    QGeoRectangle m_visibleRegion;
    inline static const QStringList m_targetTags = {
        "Exif.GPSInfo.GPSDateStamp",
        "Exif.GPSInfo.GPSTimeStamp",
        "Exif.GPSInfo.GPSLatitude",
        "Exif.GPSInfo.GPSLatitudeRef",
        "Exif.GPSInfo.GPSLongitude",
        "Exif.GPSInfo.GPSLongitudeRef",
        "Exif.GPSInfo.GPSAltitudeRef",
        "Exif.GPSInfo.GPSAltitude",
        "Exif.GPSInfo.GPSImgDirection",
        "Exif.GPSInfo.GPSImgDirectionRef"
    };
    bool containsFile(const QString &filepath) const;
};

#endif
