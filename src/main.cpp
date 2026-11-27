#include "bridge/fileoperations.h"
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <KAboutData>
#include <KLocalizedString>
#include <KDBusService>
#include <KCrash>
#include "bridge/filelistmodel.h"
#include "bridge/placesmodel.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    KCrash::initialize();

    KAboutData aboutData(
        QStringLiteral("kfinder"),
        i18n("Finder"),
        QStringLiteral("0.1.0"),
        i18n("macOS 27 Golden Gate Finder replica for CachyOS / KDE Plasma 6"),
        KAboutLicense::GPL_V2,
        i18n("© 2026 Cesar")
    );
    KAboutData::setApplicationData(aboutData);
    QApplication::setWindowIcon(QIcon::fromTheme(QStringLiteral("system-file-manager")));

    KDBusService service(KDBusService::Unique);

    qmlRegisterType<KFinder::FileListModel>("org.cesar.kfinder", 1, 0, "FileListModel");
    qmlRegisterType<KFinder::PlacesModel>("org.cesar.kfinder", 1, 0, "PlacesModel");
    qmlRegisterType<KFinder::FileOperations>("org.cesar.kfinder", 1, 0, "FileOperations");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/org/cesar/kfinder/qml/Main.qml"));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection
    );

    engine.load(url);

    return app.exec();
}
