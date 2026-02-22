#ifndef EXIFUTILS_H
#define EXIFUTILS_H

#include <QString>
#include <QMap>

namespace ExifUtils {

    struct PhotoLoaded {
        bool success;
        QString messageError;
        QMap<QString, QString> targetTags;
    };

    void loadExif(const QString& filepath, const QStringList& targetKeys, PhotoLoaded& photoLoaded);

    double parseFraction(const QString& fraction);

    double exifCoordinateToDouble(const QString& exifString, const QString& ref);

    QString exifGPSTimeStampToTime(const QString& exifString);

    inline bool existsTag(const QMap<QString, QString>& targetTags, QString& key) {
        return targetTags.contains(key) && !targetTags[key].isEmpty();
    }

}

#endif // EXIFUTILS_H
