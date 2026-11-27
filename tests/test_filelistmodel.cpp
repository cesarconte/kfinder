#include <QTest>
#include <QSignalSpy>
#include <QGuiApplication>
#include "bridge/filelistmodel.h"

class TestFileListModel : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void testInitialState() {
        KFinder::FileListModel model;
        QCOMPARE(model.count(), 0);
        QCOMPARE(model.loading(), false);
        QCOMPARE(model.showHiddenFiles(), false);
        QCOMPARE(model.sortOrder(), Qt::AscendingOrder);
    }

    void testDirectoryListing() {
        KFinder::FileListModel model;
        QSignalSpy loadedSpy(&model, &KFinder::FileListModel::directoryLoaded);

        model.setUrl(QUrl::fromLocalFile(QStringLiteral("/etc")));
        QVERIFY(loadedSpy.wait(5000));
        QVERIFY(model.count() > 0);

        QVariantMap first = model.get(0);
        QVERIFY(!first.value(QStringLiteral("name")).toString().isEmpty());
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    TestFileListModel tc;
    return QTest::qExec(&tc, argc, argv);
}
#include "test_filelistmodel.moc"
