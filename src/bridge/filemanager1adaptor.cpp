#include "filemanager1adaptor.h"

namespace KFinder {

FileManager1Adaptor::FileManager1Adaptor(QObject *parent)
    : QDBusAbstractAdaptor(parent)
{
    setAutoRelaySignals(true);
}

void FileManager1Adaptor::ShowFolders(const QStringList &uriList, const QString &/*startUpId*/)
{
    if (uriList.isEmpty()) return;
    QUrl url(uriList.first());
    Q_EMIT openFolderRequested(url);
}

void FileManager1Adaptor::ShowItems(const QStringList &uriList, const QString &/*startUpId*/)
{
    if (uriList.isEmpty()) return;
    QUrl url(uriList.first());
    Q_EMIT showItemRequested(url);
}

void FileManager1Adaptor::ShowItemProperties(const QStringList &uriList, const QString &/*startUpId*/)
{
    if (uriList.isEmpty()) return;
    QUrl url(uriList.first());
    Q_EMIT showPropertiesRequested(url);
}

} // namespace KFinder
