#include <QDebug>
#include <exiv2/exiv2.hpp>

#include "exifutils.h"

namespace ExifUtils {

    void loadExif(const QString& filepath, const QStringList& targetKeys, PhotoLoaded& photoLoaded) {
        try {
            auto image = Exiv2::ImageFactory::open(filepath.toStdString());
            if (image.get() == nullptr) {
                photoLoaded.success = false;
                photoLoaded.messageError = "Missing '" + filepath + "'";

                return;
            }

            image->readMetadata();
            auto &exifData = image->exifData();

            // for (auto it = exifData.begin(); it != exifData.end(); ++it) {
            //     QString k = QString::fromStdString(it->key());
            //     QString v = QString::fromStdString(it->value().toString());
            //     qDebug() << filepath;
            //     qDebug() << "Tag encontrada:" << k << " -> Valor:" << v;
            // }

            // Target Tags
            for (const QString& target : targetKeys) {
                auto it = exifData.findKey( Exiv2::ExifKey( target.toStdString() ) );
                if( it != exifData.end() )
                    photoLoaded.targetTags.insert( target, QString::fromStdString( it->value().toString() ) );
            }
        }catch (Exiv2::Error& e) {
            photoLoaded.success = false;
            photoLoaded.messageError = "Erro Exiv2: " + QString(e.what());

            return;
        }

        if( !photoLoaded.targetTags.size() ){
            photoLoaded.success = false;
            photoLoaded.messageError = "Missing TAGs";

            return;
        }
        photoLoaded.success = true;
    }

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

}
