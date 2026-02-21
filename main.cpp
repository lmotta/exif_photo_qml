#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
// #include "imagehandler.h"
// #include "exifmodel.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    //QQuickStyle::setStyle(); "Material", "Fusion", "Universal"  "Imagine"
    //QQuickStyle::setStyle("Material");
    //QQuickStyle::setStyle("Fusion");
    //QQuickStyle::setStyle("Universal");
    QQuickStyle::setStyle("Imagine");

    // qmlRegisterType<ImageHandler>("ExifApp", 1, 0, "ImageHandler");
    // qmlRegisterType<ExifModel>("ExifApp", 1, 0, "ExifModel");

    QQmlApplicationEngine engine;
    const QUrl url("qrc:/qt/qml/ExifApp/main.qml");
    engine.load(url);

    return app.exec();
}
