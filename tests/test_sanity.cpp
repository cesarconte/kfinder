#include <QTest>

class TestKFinderSanity : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void testBasicSanity() {
        QVERIFY(true);
    }
};

QTEST_MAIN(TestKFinderSanity)
#include "test_sanity.moc"
