#include <kio/jobuidelegatefactory.h>
#include "fileoperations.h"
#include <KIO/OpenUrlJob>
#include <KIO/CopyJob>
#include <KIO/DeleteJob>
#include <KIO/MkdirJob>
#include <KIO/SimpleJob>
#include <KIO/JobUiDelegate>
#include <KIO/CommandLauncherJob>
#include <KFileItemListProperties>
#include <KPropertiesDialog>
#include <QClipboard>
#include <QGuiApplication>
#include <QMimeData>
#include <QProcess>
#include <QDir>
#include <QFileInfo>
#include <QFile>
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

void FileOperations::openTerminal(const QUrl &url)
{
    QString path = url.isLocalFile() ? url.toLocalFile() : QDir::homePath();
    auto *job = new KIO::CommandLauncherJob(QStringLiteral("konsole"), {QStringLiteral("--workdir"), path});
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    job->start();
}

void FileOperations::deletePermanently(const QList<QUrl> &urls)
{
    if (urls.isEmpty()) return;
    auto *job = KIO::del(urls);
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(job->errorString());
        } else {
            Q_EMIT operationFinished(QStringLiteral("Items permanently deleted"));
        }
    });
}

void FileOperations::copyPath(const QList<QUrl> &urls)
{
    if (urls.isEmpty()) return;
    QStringList paths;
    for (const auto &url : urls) {
        paths << (url.isLocalFile() ? url.toLocalFile() : url.toString());
    }
    if (auto *clipboard = QGuiApplication::clipboard()) {
        clipboard->setText(paths.join(QLatin1Char('\n')));
        Q_EMIT operationFinished(QStringLiteral("Paths copied to clipboard"));
    }
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

void FileOperations::createNewFolder(const QUrl &parentUrl, const QString &suggestedName)
{
    if (!parentUrl.isValid()) return;
    QString baseName = suggestedName.isEmpty() ? QStringLiteral("carpeta sin título") : suggestedName;
    if (parentUrl.isLocalFile()) {
        QDir dir(parentUrl.toLocalFile());
        QString candidate = baseName;
        int count = 2;
        while (dir.exists(candidate)) {
            candidate = QStringLiteral("%1 %2").arg(baseName).arg(count++);
        }
        if (dir.mkdir(candidate)) {
            Q_EMIT operationFinished(QStringLiteral("Folder created: %1").arg(candidate));
        } else {
            Q_EMIT operationFailed(QStringLiteral("Failed to create folder"));
        }
    } else {
        QString newPath = parentUrl.path();
        if (!newPath.endsWith(QLatin1Char('/'))) {
            newPath.append(QLatin1Char('/'));
        }
        newPath.append(baseName);
        QUrl folderUrl = parentUrl;
        folderUrl.setPath(newPath);
        auto *job = KIO::mkdir(folderUrl);
        job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
        job->start();
    }
}

void FileOperations::createNewFile(const QUrl &parentUrl, const QString &suggestedName)
{
    if (!parentUrl.isValid()) return;
    QString baseName = suggestedName.isEmpty() ? QStringLiteral("archivo sin título.txt") : suggestedName;
    if (parentUrl.isLocalFile()) {
        QDir dir(parentUrl.toLocalFile());
        QString candidate = baseName;
        int count = 2;
        while (dir.exists(candidate)) {
            candidate = QStringLiteral("archivo sin título %1.txt").arg(count++);
        }
        QFile file(dir.filePath(candidate));
        if (file.open(QIODevice::WriteOnly)) {
            file.close();
            Q_EMIT operationFinished(QStringLiteral("File created: %1").arg(candidate));
        } else {
            Q_EMIT operationFailed(QStringLiteral("Failed to create file"));
        }
    }
}

void FileOperations::rename(const QUrl &oldUrl, const QString &newName)
{
    if (!oldUrl.isValid() || newName.trimmed().isEmpty()) return;
    QUrl parentFolder = KIO::upUrl(oldUrl);
    QString newPath = parentFolder.path();
    if (!newPath.endsWith(QLatin1Char('/'))) {
        newPath.append(QLatin1Char('/'));
    }
    newPath.append(newName);
    QUrl newUrl = parentFolder;
    newUrl.setPath(newPath);
    auto *job = KIO::rename(oldUrl, newUrl, KIO::DefaultFlags);
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    connect(job, &KJob::result, this, [this, job, newName]() {
        if (job->error()) {
            Q_EMIT operationFailed(job->errorString());
        } else {
            Q_EMIT operationFinished(QStringLiteral("Renamed to %1").arg(newName));
        }
    });
}

void FileOperations::copyItems(const QList<QUrl> &sources, const QUrl &destination)
{
    if (sources.isEmpty() || !destination.isValid()) return;
    auto *job = KIO::copy(sources, destination);
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(job->errorString());
        } else {
            Q_EMIT operationFinished(QStringLiteral("Items copied successfully"));
        }
    });
}

void FileOperations::moveItems(const QList<QUrl> &sources, const QUrl &destination)
{
    if (sources.isEmpty() || !destination.isValid()) return;
    auto *job = KIO::move(sources, destination);
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(job->errorString());
        } else {
            Q_EMIT operationFinished(QStringLiteral("Items moved successfully"));
        }
    });
}

void FileOperations::linkItems(const QList<QUrl> &sources, const QUrl &destination)
{
    if (sources.isEmpty() || !destination.isValid()) return;
    auto *job = KIO::link(sources, destination);
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT operationFailed(job->errorString());
        } else {
            Q_EMIT operationFinished(QStringLiteral("Links created successfully"));
        }
    });
}

void FileOperations::newWindow(const QUrl &url)
{
    QStringList args;
    if (url.isValid()) {
        args << url.toString();
    }
    QProcess::startDetached(QStringLiteral("kfinder"), args);
}

void FileOperations::compressItems(const QList<QUrl> &sources, const QString &destinationArchive)
{
    if (sources.isEmpty()) return;
    QStringList localPaths;
    for (const auto &u : sources) {
        if (u.isLocalFile()) localPaths << u.toLocalFile();
    }
    if (localPaths.isEmpty()) return;

    QString archivePath = destinationArchive;
    if (archivePath.isEmpty()) {
        QFileInfo fi(localPaths.first());
        QString baseName = fi.baseName();
        if (localPaths.size() > 1) {
            baseName = QStringLiteral("Archivo comprimido");
        }
        archivePath = fi.dir().filePath(baseName + QStringLiteral(".zip"));
        int c = 2;
        while (QFile::exists(archivePath)) {
            archivePath = fi.dir().filePath(QStringLiteral("%1 %2.zip").arg(baseName).arg(c++));
        }
    }

    QStringList args;
    args << QStringLiteral("-r") << archivePath;
    for (const auto &p : localPaths) {
        args << p;
    }
    auto *proc = new QProcess(this);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, proc, archivePath](int exitCode) {
        if (exitCode == 0) {
            Q_EMIT operationFinished(QStringLiteral("Compressed to %1").arg(QFileInfo(archivePath).fileName()));
        } else {
            Q_EMIT operationFailed(QStringLiteral("Compression failed"));
        }
        proc->deleteLater();
    });
    proc->start(QStringLiteral("zip"), args);
}

void FileOperations::extractArchive(const QUrl &archiveUrl, const QUrl &destinationDir)
{
    if (!archiveUrl.isLocalFile()) return;
    QString archivePath = archiveUrl.toLocalFile();
    QString destPath = destinationDir.isLocalFile() ? destinationDir.toLocalFile() : QFileInfo(archivePath).dir().path();

    auto *job = new KIO::CommandLauncherJob(QStringLiteral("ark"), {QStringLiteral("-b"), QStringLiteral("-o"), destPath, archivePath});
    job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr));
    job->start();
    Q_EMIT operationFinished(QStringLiteral("Extracting archive..."));
}

} // namespace KFinder
