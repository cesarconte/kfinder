#include <QTest>
#include <QIcon>
#include <CachyOSUI/cachytheme.h>

class TestKFinderSanity : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void testBasicSanity() {
        QCOMPARE(QIcon::themeName(), QStringLiteral("MacTahoe"));
        CachyTheme cTheme;
        QString folderUrl = cTheme.iconUrl(QStringLiteral("inode-directory"));
        QVERIFY(folderUrl.contains(QStringLiteral("MacTahoe")));
        QVERIFY(folderUrl.contains(QStringLiteral("inode-directory.svg")));
    }
};

QTEST_MAIN(TestKFinderSanity)
#include "test_sanity.moc"
