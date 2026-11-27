#include <kio/jobuidelegatefactory.h>
#include "fileoperations.h"
#include <KIO/OpenUrlJob>
#include <KIO/CopyJob>
#include <KIO/DeleteJob>
#include <KIO/JobUiDelegate>
#include <KIO/CommandLauncherJob>
#include <KFileItemListProperties>
#include <KPropertiesDialog>
#include <QClipboard>
#include <QGuiApplication>
#include <QMimeData>
#include <QProcess>
#include <sys/xattr.h>

namespace KFinder {

FileOperations::FileOperations(QObject *parent)
    : QObject(parent)
{
}

FileOperations::~FileOperations() = default;

void FileOperations::openUrl(const QUrl &url)
{
    if (!url.isValid()) return;
    auto *job = new KIO::OpenUrlJob(url);
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    job->start();
}

void FileOperations::openWith(const QUrl &url)
{
    if (!url.isValid()) return;
    // Launch open with selector
    QProcess::startDetached(QStringLiteral("plasma-open"), {url.toString()});
}

void FileOperations::moveToTrash(const QList<QUrl> &urls)
{
    if (urls.isEmpty()) return;
    auto *job = KIO::trash(urls);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(job->errorString());
        } else {
            Q_EMIT operationFinished(QStringLiteral("Items moved to trash"));
        }
    });
}

void FileOperations::copy(const QList<QUrl> &urls)
{
    if (urls.isEmpty()) return;
    if (auto *clipboard = QGuiApplication::clipboard()) {
        auto *mimeData = new QMimeData();
        mimeData->setUrls(urls);
        clipboard->setMimeData(mimeData);
        Q_EMIT operationFinished(QStringLiteral("Copied to clipboard"));
    }
}

void FileOperations::paste(const QUrl &destinationUrl)
{
    if (!destinationUrl.isValid()) return;
    if (auto *clipboard = QGuiApplication::clipboard()) {
        const auto *mimeData = clipboard->mimeData();
        if (mimeData && mimeData->hasUrls()) {
            auto *job = KIO::copy(mimeData->urls(), destinationUrl);
            connect(job, &KJob::result, this, [this, job]() {
                if (job->error()) {
                    Q_EMIT operationFailed(job->errorString());
                } else {
                    Q_EMIT operationFinished(QStringLiteral("Pasted successfully"));
                }
            });
        }
    }
}

void FileOperations::duplicate(const QUrl &url)
{
    if (!url.isValid()) return;
    QUrl parent = KIO::upUrl(url);
    auto *job = KIO::copy(url, parent);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(job->errorString());
        } else {
            Q_EMIT operationFinished(QStringLiteral("Item duplicated"));
        }
    });
}

void FileOperations::quickLook(const QUrl &url)
{
    if (!url.isValid()) return;
    // Invoke kpeek directly via CommandLauncherJob
    auto *job = new KIO::CommandLauncherJob(QStringLiteral("kpeek"), {url.toLocalFile()});
    job->start();
}

void FileOperations::showProperties(const QUrl &url)
{
    if (!url.isValid()) return;
    KPropertiesDialog::showDialog(url);
}

void FileOperations::setTag(const QUrl &url, const QString &color)
{
    if (!url.isLocalFile()) return;
    QString path = url.toLocalFile();
    QByteArray val = color.toUtf8();
    if (color.isEmpty()) {
        removexattr(path.toUtf8().constData(), "user.color.tag");
    } else {
        setxattr(path.toUtf8().constData(), "user.color.tag", val.constData(), val.size(), 0);
    }
    Q_EMIT operationFinished(QStringLiteral("Tag updated"));
}

} // namespace KFinder
