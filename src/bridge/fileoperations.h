#pragma once

#include <QObject>
#include <QUrl>
#include <QStringList>

namespace KFinder {

class FileOperations : public QObject
{
    Q_OBJECT

public:
    explicit FileOperations(QObject *parent = nullptr);
    ~FileOperations() override;

    Q_INVOKABLE void openUrl(const QUrl &url);
    Q_INVOKABLE void openWith(const QUrl &url);
    Q_INVOKABLE void moveToTrash(const QList<QUrl> &urls);
    Q_INVOKABLE void deletePermanently(const QList<QUrl> &urls);
    Q_INVOKABLE void copy(const QList<QUrl> &urls);
    Q_INVOKABLE void copyPath(const QList<QUrl> &urls);
    Q_INVOKABLE void paste(const QUrl &destinationUrl);
    Q_INVOKABLE void duplicate(const QUrl &url);
    Q_INVOKABLE void quickLook(const QUrl &url);
    Q_INVOKABLE void showProperties(const QUrl &url);
    Q_INVOKABLE void openTerminal(const QUrl &url);
    Q_INVOKABLE void setTag(const QUrl &url, const QString &color);
    Q_INVOKABLE void createNewFolder(const QUrl &parentUrl, const QString &suggestedName = QString());
    Q_INVOKABLE void createNewFile(const QUrl &parentUrl, const QString &suggestedName = QString());
    Q_INVOKABLE void rename(const QUrl &oldUrl, const QString &newName);
    Q_INVOKABLE void copyItems(const QList<QUrl> &sources, const QUrl &destination);
    Q_INVOKABLE void moveItems(const QList<QUrl> &sources, const QUrl &destination);
    Q_INVOKABLE void linkItems(const QList<QUrl> &sources, const QUrl &destination);
    Q_INVOKABLE void newWindow(const QUrl &url);
    Q_INVOKABLE void compressItems(const QList<QUrl> &sources, const QString &destinationArchive = QString());
    Q_INVOKABLE void extractArchive(const QUrl &archiveUrl, const QUrl &destinationDir = QUrl());

Q_SIGNALS:
    void operationFinished(const QString &message);
    void operationFailed(const QString &error);
};

} // namespace KFinder
