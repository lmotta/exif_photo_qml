#include <cmath>
#include <exiv2/exiv2.hpp>

#include "exifmodel.h"
#include "exifutils.h"


QVariant ExifModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_items.count()) return QVariant();

    const auto &item = m_items[index.row()];
    switch (role) {
        case FilepathRole: return item.filepath;
        case DatetimeRole: return item.datetime;
        case GeoCoordinateRole: return QVariant::fromValue(item.geoCoordinate);
        case DirectionRole: return item.direction;
        case NorthIsTrueRole: return item.northIsTrue;
        default: return QVariant();
    }
}

void ExifModel::addPhoto(const QUrl &fileUrl ) {

    int nextRow = m_items.count();

    ExifPhoto item;
    item.filepath = fileUrl.toLocalFile();

    if( containsFile(item.filepath) ) {
        emit errorOccurred( item.filepath + " - Já existe");
        return;
    }

    ExifUtils::PhotoLoaded photoLoaded;
    ExifUtils::loadExif( item.filepath, m_targetTags, photoLoaded );

    if( !photoLoaded.success ){
        emit errorOccurred( item.filepath + " - " + photoLoaded.messageError );
        return;
    }

    const QString suffix = "Exif.GPSInfo.GPS";

    // << Datetime
    QString date_="", time_="";

    QString lblGps = "DateStamp";
    QString key =  suffix + lblGps;
    if( ExifUtils::existsTag(  photoLoaded.targetTags, key ) )
        date_ = photoLoaded.targetTags[key];

    lblGps = "TimeStamp";
    key =  suffix + lblGps;
    if( ExifUtils::existsTag(  photoLoaded.targetTags, key ) )
        time_ = ExifUtils::exifGPSTimeStampToTime( photoLoaded.targetTags[key] );

    item.datetime = !date_.isEmpty() && ! time_.isEmpty()
        ?   QDateTime::fromString(
                QString("%1 %2").arg( date_, time_), "yyyy:MM:dd hh:mm:ss"
            )
        :   QDateTime(); // Null
    // Datetime >>

    // << GpsInfo Coordinates
    double
        lat = std::numeric_limits<double>::quiet_NaN(),
        lng = std::numeric_limits<double>::quiet_NaN(),
        alt = std::numeric_limits<double>::quiet_NaN();

    lblGps = "Latitude";
    key = suffix + lblGps;
    QString keyRef = key + "Ref";
    if( ExifUtils::existsTag( photoLoaded.targetTags, key ) && ExifUtils::existsTag( photoLoaded.targetTags, keyRef ))
        lat = ExifUtils::exifCoordinateToDouble(photoLoaded.targetTags[key], photoLoaded.targetTags[keyRef]);

    lblGps = "Longitude";
    key = suffix + lblGps;
    keyRef = key + "Ref";
    if( ExifUtils::existsTag( photoLoaded.targetTags, key ) && ExifUtils::existsTag( photoLoaded.targetTags, keyRef ) )
        lng = ExifUtils::exifCoordinateToDouble(photoLoaded.targetTags[key], photoLoaded.targetTags[keyRef]);

    lblGps = "Altitude";
    key = suffix + lblGps;
    keyRef = key + "Ref";
    if( ExifUtils::existsTag( photoLoaded.targetTags, key ) && ExifUtils::existsTag( photoLoaded.targetTags, keyRef ) ) {
        double value = ExifUtils::parseFraction( photoLoaded.targetTags[key] );
        if (photoLoaded.targetTags.value(keyRef) == "1") value *= -1.0;
        alt = value;
    }

    // GeoCoordinate
    if( !std::isnan(lat) && !std::isnan(lng) ) {
        item.geoCoordinate = QGeoCoordinate( lat, lng );
        if( !std::isnan(alt) ) item.geoCoordinate.setAltitude( alt );
    }
    else item.geoCoordinate = QGeoCoordinate(); // Null

    // GpsInfo Coordinates>>

    lblGps = "ImgDirection";
    key =  suffix + lblGps;
    item.direction = ExifUtils::existsTag( photoLoaded.targetTags, key )
        ? ExifUtils::parseFraction( photoLoaded.targetTags[key] )
        : qQNaN(); // Null

    lblGps = "ImgDirectionRef";
    key =  suffix + lblGps;
    item.northIsTrue = ExifUtils::existsTag( photoLoaded.targetTags, key )
        ? photoLoaded.targetTags[key] == "T"
        : false;

    // Update Visible Region
    QGeoRectangle oldRegion = m_visibleRegion;
    if (item.geoCoordinate.isValid()) {
        if (m_items.isEmpty()) {
            m_visibleRegion = QGeoRectangle(item.geoCoordinate, item.geoCoordinate);
        } else {
            m_visibleRegion.extendRectangle(item.geoCoordinate);
        }
    }

    // Add Photo
    beginInsertRows(QModelIndex(), nextRow, nextRow);
    m_items.append( item );
    endInsertRows();
    if (m_visibleRegion != oldRegion)
        emit visibleRegionChanged();

}

bool ExifModel::containsFile(const QString &filepath) const {
    return std::any_of( m_items.begin(), m_items.end(), [&](const ExifPhoto &item){
        return item.filepath == filepath;
    });
}
