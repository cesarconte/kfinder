#include <QTest>
#include <QSignalSpy>
#include <QStandardItemModel>
#include <QElapsedTimer>
#include <QDebug>

class TestModelSpike : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void testLargeListPerformance() {
        QStandardItemModel model;
        const int itemCount = 100000;

        QElapsedTimer timer;
        timer.start();

        QList<QStandardItem*> items;
        items.reserve(itemCount);
        for (int i = 0; i < itemCount; ++i) {
            auto *item = new QStandardItem(QStringLiteral("Document_%1.pdf").arg(i));
            items.append(item);
        }
        model.invisibleRootItem()->appendRows(items);

        qint64 insertElapsed = timer.elapsed();
        qDebug() << "Inserted" << itemCount << "items in" << insertElapsed << "ms";
        QVERIFY(insertElapsed < 1000); // Must be under 1s
        QCOMPARE(model.rowCount(), itemCount);
    }
};

QTEST_MAIN(TestModelSpike)
#include "test_model_spike.moc"
