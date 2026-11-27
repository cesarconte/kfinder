#include "bridge/fileoperations.h"
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QDir>
#include <QDBusConnection>
#include <KAboutData>
#include <KLocalizedString>
#include <KDBusService>
#include <KCrash>
#include "bridge/filelistmodel.h"
#include "bridge/placesmodel.h"
#include "bridge/terminalbridge.h"
#include "bridge/filemanager1adaptor.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("kfinder");
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
    app.setDesktopFileName(QStringLiteral("org.cesar.kfinder"));

    KDBusService service(KDBusService::Unique);

    QString initialUrl = QStringLiteral("file:///home/cesar");
    if (app.arguments().size() > 1) {
        QString arg = app.arguments().at(1);
        if (arg.startsWith(QLatin1String("file://"))) {
            initialUrl = arg;
        } else if (!arg.startsWith(QLatin1String("-"))) {
            initialUrl = QUrl::fromUserInput(arg, QDir::currentPath()).toString();
        }
    }

    qmlRegisterType<KFinder::FileListModel>("org.cesar.kfinder", 1, 0, "FileListModel");
    qmlRegisterType<KFinder::PlacesModel>("org.cesar.kfinder", 1, 0, "PlacesModel");
    qmlRegisterType<KFinder::FileOperations>("org.cesar.kfinder", 1, 0, "FileOperations");
    qmlRegisterType<KFinder::TerminalBridge>("org.cesar.kfinder", 1, 0, "TerminalBridge");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("initialUrl"), initialUrl);

    QObject::connect(&service, &KDBusService::activateRequested, [&engine](const QStringList &arguments, const QString &workingDirectory) {
        if (arguments.size() > 1) {
            QString path = arguments.at(1);
            QUrl targetUrl;
            if (path.startsWith(QLatin1String("file://"))) {
                targetUrl = QUrl(path);
            } else {
                targetUrl = QUrl::fromUserInput(path, workingDirectory);
            }
            const auto rootObjects = engine.rootObjects();
            if (!rootObjects.isEmpty()) {
                QMetaObject::invokeMethod(rootObjects.first(), "navigateToUrl", Q_ARG(QVariant, targetUrl.toString()));
            }
        }
    });
    auto *adaptor = new KFinder::FileManager1Adaptor(&app);
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/org/freedesktop/FileManager1"), &app);
    QDBusConnection::sessionBus().registerService(QStringLiteral("org.freedesktop.FileManager1"));

    QObject::connect(adaptor, &KFinder::FileManager1Adaptor::openFolderRequested, [&engine](const QUrl &targetUrl) {
        const auto rootObjects = engine.rootObjects();
        if (!rootObjects.isEmpty()) {
            QMetaObject::invokeMethod(rootObjects.first(), "navigateToUrl", Q_ARG(QVariant, targetUrl.toString()));
        }
    });

    QObject::connect(adaptor, &KFinder::FileManager1Adaptor::showItemRequested, [&engine](const QUrl &itemUrl) {
        const auto rootObjects = engine.rootObjects();
        if (!rootObjects.isEmpty()) {
            QUrl parentUrl = KIO::upUrl(itemUrl);
            QMetaObject::invokeMethod(rootObjects.first(), "navigateToUrl", Q_ARG(QVariant, parentUrl.toString()));
        }
    });

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
