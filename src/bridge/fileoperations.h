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
    Q_INVOKABLE void copy(const QList<QUrl> &urls);
    Q_INVOKABLE void paste(const QUrl &destinationUrl);
    Q_INVOKABLE void duplicate(const QUrl &url);
    Q_INVOKABLE void quickLook(const QUrl &url);
    Q_INVOKABLE void showProperties(const QUrl &url);
    Q_INVOKABLE void setTag(const QUrl &url, const QString &color);

Q_SIGNALS:
    void operationFinished(const QString &message);
    void operationFailed(const QString &error);
};

} // namespace KFinder
