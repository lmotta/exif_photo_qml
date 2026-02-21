#include <cmath>
#include "exifmodel.h"
#include <exiv2/exiv2.hpp>

namespace {

    double parseFraction(const QString& fraction){
        // "14567/100"
        QStringList numDen = fraction.split('/');
        if (numDen.size() != 2) return 0.0;

        double numerator = numDen[0].toDouble();
        double denominator = numDen[1].toDouble();

        return (denominator == 0) ? 0 : numerator / denominator;
    }

    double exifCoordinateToDouble(const QString& exifString, const QString& ref) {
        // "14/1 9/1 14567/100"
        QStringList parts = exifString.split(' ', Qt::SkipEmptyParts);
        if (parts.size() < 3) return 0.0;

        double degrees = parseFraction(parts[0]);
        double minutes = parseFraction(parts[1]);
        double seconds = parseFraction(parts[2]);

        double decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);
        if (ref == "S" || ref == "W") {
            decimal *= -1.0;
        }

        return decimal;
    }

    QString exifGPSTimeStampToTime(const QString& exifString) {
        // "19/1 35/1 51/1"
        QStringList parts = exifString.split(' ', Qt::SkipEmptyParts);
        if (parts.size() < 3) return QString();

        double hours = parseFraction(parts[0]);
        double minutes = parseFraction(parts[1]);
        double seconds = parseFraction(parts[2]);

        return QString::asprintf("%02.0f:%02.0f:%02.0f", hours, minutes, seconds);
    }

    bool existsTag(const QMap<QString, QString> targetTags, QString key) {
        return targetTags.contains(key) && !targetTags[key].isEmpty();
    }
}

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
    try {

        ExifPhoto item;
        item.filepath = fileUrl.toLocalFile();

        auto image = Exiv2::ImageFactory::open(item.filepath.toStdString());
        if (image.get() == nullptr) {
            endResetModel();
            return;
        }

        image->readMetadata();
        auto &exifData = image->exifData();

        // for (auto it = exifData.begin(); it != exifData.end(); ++it) {
        //     QString k = QString::fromStdString(it->key());
        //     QString v = QString::fromStdString(it->value().toString());
        //     qDebug() << "Tag encontrada:" << k << " -> Valor:" << v;
        // }

        // Target Tags
        QMap<QString, QString> targetTags;
        for (const QString& target : m_targetTags) {
            auto it = exifData.findKey( Exiv2::ExifKey( target.toStdString() ) );
            if( it != exifData.end() )
                targetTags.insert( target, QString::fromStdString( it->value().toString() ) );
        }

        const QString suffix = "Exif.GPSInfo.GPS";

        // << Datetime
        QString date_="", time_="";

        QString lblGps = "DateStamp";
        QString key =  suffix + lblGps;
        if( existsTag(  targetTags, key ) )
            date_ = targetTags[key];

        lblGps = "TimeStamp";
        key =  suffix + lblGps;
        if( existsTag(  targetTags, key ) )
            time_ = exifGPSTimeStampToTime( targetTags[key] );

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
        if( existsTag(  targetTags, key ) && existsTag(  targetTags, keyRef ))
            lat = exifCoordinateToDouble(targetTags[key], targetTags[keyRef]);

        lblGps = "Longitude";
        key = suffix + lblGps;
        keyRef = key + "Ref";
        if( existsTag(  targetTags, key ) && existsTag(  targetTags, keyRef ) )
            lng = exifCoordinateToDouble(targetTags[key], targetTags[keyRef]);

        lblGps = "Altitude";
        key = suffix + lblGps;
        keyRef = key + "Ref";
        if( existsTag(  targetTags, key ) && existsTag(  targetTags, keyRef ) ) {
            double value = parseFraction( targetTags[key] );
            if (targetTags.value(keyRef) == "1") value *= -1.0;
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
        item.direction = existsTag(  targetTags, key )
            ? parseFraction( targetTags[key] )
            : qQNaN(); // Null

        lblGps = "ImgDirectionRef";
        key =  suffix + lblGps;
        item.northIsTrue = existsTag(  targetTags, key )
            ? targetTags[key] == "T"
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
        //

    } catch (Exiv2::Error& e) {
        qWarning() << "Erro Exiv2:" << e.what();
        m_items.clear();
    }
}
