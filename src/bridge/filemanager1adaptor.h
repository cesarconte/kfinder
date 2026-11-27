#pragma once

#include <QDBusAbstractAdaptor>
#include <QStringList>
#include <QUrl>

namespace KFinder {

class FileManager1Adaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.FileManager1")

public:
    explicit FileManager1Adaptor(QObject *parent);
    ~FileManager1Adaptor() override = default;

public Q_SLOTS:
    void ShowFolders(const QStringList &uriList, const QString &startUpId);
    void ShowItems(const QStringList &uriList, const QString &startUpId);
    void ShowItemProperties(const QStringList &uriList, const QString &startUpId);

Q_SIGNALS:
    void openFolderRequested(const QUrl &url);
    void showItemRequested(const QUrl &url);
    void showPropertiesRequested(const QUrl &url);
};

} // namespace KFinder
