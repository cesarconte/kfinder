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
#include <KFileItemActions>
#include <knewfilemenu.h>
#include <kfilecopytomenu.h>
#include <kfilemetadata/usermetadata.h>
#include <KLocalizedString>
#include <KFormat>
#include <QClipboard>
#include <QGuiApplication>
#include <QMimeData>
#include <QProcess>
#include <QDir>
#include <QFileInfo>
#include <QFile>
#include <QMenu>
#include <QAction>
#include <QStorageInfo>
#include <QDateTime>
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

void FileOperations::showContextMenu(const QList<QUrl> &urls, int globalX, int globalY, const QUrl &currentFolderUrl)
{
    QMenu menu;

    if (urls.isEmpty()) {
        QUrl targetUrl = currentFolderUrl.isValid() ? currentFolderUrl : QUrl::fromLocalFile(QDir::homePath());

        auto *newFileMenu = new KNewFileMenu(&menu);
        newFileMenu->setWorkingDirectory(targetUrl);
        newFileMenu->checkUpToDate();
        menu.addMenu(newFileMenu->menu());

        QAction *pasteAction = menu.addAction(QIcon::fromTheme(QStringLiteral("edit-paste")), i18n("Pegar contenido del portapapeles..."));
        pasteAction->setShortcut(QKeySequence::Paste);
        connect(pasteAction, &QAction::triggered, this, [this, targetUrl]() {
            paste(targetUrl);
        });

        menu.addSeparator();

        QAction *terminalAction = menu.addAction(QIcon::fromTheme(QStringLiteral("utilities-terminal")), i18n("Abrir terminal aquí"));
        connect(terminalAction, &QAction::triggered, this, [this, targetUrl]() {
            openTerminal(targetUrl);
        });

        menu.addSeparator();

        QAction *propAction = menu.addAction(QIcon::fromTheme(QStringLiteral("document-properties")), i18n("Propiedades"));
        connect(propAction, &QAction::triggered, this, [this, targetUrl]() {
            showProperties(targetUrl);
        });

        menu.exec(QPoint(globalX, globalY));
        return;
    }

    KFileItemList itemList;
    for (const QUrl &u : urls) {
        itemList.append(KFileItem(u));
    }
    const KFileItemListProperties props(itemList);
    const KFileItem firstItem = itemList.first();
    const QUrl firstUrl = firstItem.url();
    const bool isSingle = (urls.count() == 1);

    auto *fileItemActions = new KFileItemActions(&menu);
    fileItemActions->setItemListProperties(props);

    if (firstItem.isDir()) {
        QAction *newTabAction = menu.addAction(QIcon::fromTheme(QStringLiteral("tab-new")), i18n("Abrir en una pestaña nueva"));
        connect(newTabAction, &QAction::triggered, this, [this, firstUrl]() {
            Q_EMIT newTabRequested(firstUrl);
        });

        QAction *newWindowAction = menu.addAction(QIcon::fromTheme(QStringLiteral("window-new")), i18n("Abrir en ventana nueva"));
        connect(newWindowAction, &QAction::triggered, this, [this, firstUrl]() {
            Q_EMIT newWindowRequested(firstUrl);
        });

        QAction *splitAction = menu.addAction(QIcon::fromTheme(QStringLiteral("view-split-left-right")), i18n("Abrir en vista dividida"));
        connect(splitAction, &QAction::triggered, this, [this, firstUrl]() {
            Q_EMIT splitViewRequested(firstUrl);
        });
    }

    fileItemActions->insertOpenWithActionsTo(nullptr, &menu, {qApp->desktopFileName()});

    menu.addSeparator();

    if (firstItem.isDir()) {
        auto *newFileMenu = new KNewFileMenu(&menu);
        newFileMenu->setWorkingDirectory(firstUrl);
        newFileMenu->checkUpToDate();
        menu.addMenu(newFileMenu->menu());
        menu.addSeparator();
    }

    QAction *cutAction = menu.addAction(QIcon::fromTheme(QStringLiteral("edit-cut")), i18n("Cortar"));
    cutAction->setShortcut(QKeySequence::Cut);
    connect(cutAction, &QAction::triggered, this, [this, urls]() {
        copy(urls);
    });

    QAction *copyAction = menu.addAction(QIcon::fromTheme(QStringLiteral("edit-copy")), i18n("Copiar"));
    copyAction->setShortcut(QKeySequence::Copy);
    connect(copyAction, &QAction::triggered, this, [this, urls]() {
        copy(urls);
    });

    QAction *copyPathAction = menu.addAction(i18n("Copiar ubicación"));
    copyPathAction->setShortcut(QKeySequence(Qt::CTRL | Qt::ALT | Qt::Key_C));
    connect(copyPathAction, &QAction::triggered, this, [this, urls]() {
        copyPath(urls);
    });

    if (firstItem.isDir()) {
        QAction *pasteAction = menu.addAction(QIcon::fromTheme(QStringLiteral("edit-paste")), i18n("Pegar contenido del portapapeles..."));
        pasteAction->setShortcut(QKeySequence::Paste);
        connect(pasteAction, &QAction::triggered, this, [this, firstUrl]() {
            paste(firstUrl);
        });
    }

    if (isSingle) {
        QAction *dupAction = menu.addAction(i18n("Duplicar aquí"));
        dupAction->setShortcut(QKeySequence(Qt::CTRL | Qt::Key_D));
        connect(dupAction, &QAction::triggered, this, [this, firstUrl]() {
            duplicate(firstUrl);
        });

        QAction *renAction = menu.addAction(i18n("Cambiar nombre..."));
        renAction->setShortcut(Qt::Key_F2);
        connect(renAction, &QAction::triggered, this, [this, firstUrl]() {
            Q_EMIT renameRequested(firstUrl);
        });
    }

    QAction *trashAction = menu.addAction(QIcon::fromTheme(QStringLiteral("user-trash")), i18n("Mover a la papelera"));
    trashAction->setShortcut(QKeySequence::Delete);
    connect(trashAction, &QAction::triggered, this, [this, urls]() {
        moveToTrash(urls);
    });

    menu.addSeparator();

    QList<QAction *> additionalActions;
    if (firstItem.isDir()) {
        auto *termAction = new QAction(QIcon::fromTheme(QStringLiteral("utilities-terminal")), i18n("Abrir terminal aquí"), &menu);
        termAction->setShortcut(QKeySequence(Qt::ALT | Qt::SHIFT | Qt::Key_F4));
        connect(termAction, &QAction::triggered, this, [this, firstUrl]() {
            openTerminal(firstUrl);
        });
        additionalActions << termAction;
    }
    fileItemActions->addActionsTo(&menu, KFileItemActions::MenuActionSource::All, additionalActions);

    QMenu *tagsMenu = menu.addMenu(QIcon::fromTheme(QStringLiteral("tag")), i18n("Etiquetas de color"));
    static const struct { const char *name; const char *tag; } s_tags[] = {
        {"Rojo", "red"},
        {"Naranja", "orange"},
        {"Amarillo", "yellow"},
        {"Verde", "green"},
        {"Azul", "blue"},
        {"Púrpura", "purple"},
        {"Gris", "gray"},
        {"Sin etiqueta", ""}
    };
    for (const auto &t : s_tags) {
        QAction *tAction = tagsMenu->addAction(i18n(t.name));
        QString tagStr = QString::fromLatin1(t.tag);
        connect(tAction, &QAction::triggered, this, [this, urls, tagStr]() {
            for (const auto &u : urls) {
                setTag(u, tagStr);
            }
        });
    }

    QAction *compressAction = menu.addAction(QIcon::fromTheme(QStringLiteral("archive")), i18n("Comprimir"));
    connect(compressAction, &QAction::triggered, this, [this, urls]() {
        compressItems(urls);
    });

    auto *copyToMenu = new KFileCopyToMenu(&menu);
    copyToMenu->setUrls(urls);
    copyToMenu->setReadOnly(!props.supportsWriting());
    copyToMenu->setAutoErrorHandlingEnabled(true);
    copyToMenu->addActionsTo(&menu);

    menu.addSeparator();

    QAction *propAction = menu.addAction(QIcon::fromTheme(QStringLiteral("document-properties")), i18n("Propiedades"));
    propAction->setShortcut(QKeySequence(Qt::ALT | Qt::Key_Return));
    connect(propAction, &QAction::triggered, this, [this, firstUrl]() {
        showProperties(firstUrl);
    });

    menu.exec(QPoint(globalX, globalY));
}

QVariantMap FileOperations::getStorageInfo(const QUrl &url) const
{
    QString localPath = url.isLocalFile() ? url.toLocalFile() : QDir::homePath();
    QStorageInfo storage(localPath);
    if (!storage.isValid()) {
        storage = QStorageInfo(QDir::homePath());
    }

    qint64 total = storage.bytesTotal();
    qint64 free = storage.bytesAvailable();
    qint64 used = total - free;
    double percent = total > 0 ? static_cast<double>(used) / static_cast<double>(total) : 0.0;

    KFormat format;
    QString freeStr = i18n("%1 libre", format.formatByteSize(free));
    QString totalStr = format.formatByteSize(total);

    QVariantMap res;
    res[QStringLiteral("freeBytes")] = free;
    res[QStringLiteral("totalBytes")] = total;
    res[QStringLiteral("freeString")] = freeStr;
    res[QStringLiteral("totalString")] = totalStr;
    res[QStringLiteral("percentUsed")] = percent;
    res[QStringLiteral("rootPath")] = storage.rootPath();
    res[QStringLiteral("name")] = storage.name().isEmpty() ? storage.displayName() : storage.name();
    return res;
}

QVariantMap FileOperations::getMetadata(const QUrl &url) const
{
    QVariantMap res;
    if (!url.isValid()) return res;

    KFileItem item(url);
    res[QStringLiteral("name")] = item.text();
    res[QStringLiteral("url")] = url.toString();
    res[QStringLiteral("isDir")] = item.isDir();
    res[QStringLiteral("mimeType")] = item.mimetype();
    res[QStringLiteral("mimeComment")] = item.mimeComment();
    res[QStringLiteral("iconName")] = item.iconName();

    KFormat format;
    if (item.isDir()) {
        res[QStringLiteral("type")] = i18n("carpeta");
        if (url.isLocalFile()) {
            QDir dir(url.toLocalFile());
            int count = dir.entryList(QDir::AllEntries | QDir::NoDotAndDotDot).count();
            res[QStringLiteral("size")] = i18np("1 elemento", "%1 elementos", count);
        } else {
            res[QStringLiteral("size")] = QStringLiteral("--");
        }
    } else {
        res[QStringLiteral("type")] = item.mimeComment().isEmpty() ? item.mimetype() : item.mimeComment();
        res[QStringLiteral("size")] = format.formatByteSize(item.size());
        res[QStringLiteral("sizeBytes")] = static_cast<qlonglong>(item.size());
    }

    res[QStringLiteral("modified")] = item.time(KFileItem::ModificationTime).toString(QStringLiteral("dd/MM/yy 'a las' hh:mm"));
    res[QStringLiteral("accessed")] = item.time(KFileItem::AccessTime).toString(QStringLiteral("dd/MM/yy 'a las' hh:mm"));
    res[QStringLiteral("created")] = item.time(KFileItem::CreationTime).toString(QStringLiteral("dd/MM/yy 'a las' hh:mm"));

    if (url.isLocalFile()) {
        QString path = url.toLocalFile();
        KFileMetaData::UserMetaData metaData(path);
        res[QStringLiteral("rating")] = metaData.rating();
        res[QStringLiteral("comment")] = metaData.userComment();
        res[QStringLiteral("tags")] = metaData.tags();

        char val[128];
        ssize_t len = getxattr(path.toUtf8().constData(), "user.cachyos.tag", val, sizeof(val) - 1);
        if (len > 0) {
            val[len] = '\0';
            res[QStringLiteral("tagColor")] = QString::fromUtf8(val);
        }
    }
    return res;
}

void FileOperations::setRating(const QUrl &url, int rating)
{
    if (!url.isLocalFile()) return;
    KFileMetaData::UserMetaData metaData(url.toLocalFile());
    metaData.setRating(rating);
}

void FileOperations::setComment(const QUrl &url, const QString &comment)
{
    if (!url.isLocalFile()) return;
    KFileMetaData::UserMetaData metaData(url.toLocalFile());
    metaData.setUserComment(comment);
}

void FileOperations::setTags(const QUrl &url, const QStringList &tags)
{
    if (!url.isLocalFile()) return;
    KFileMetaData::UserMetaData metaData(url.toLocalFile());
    metaData.setTags(tags);
}

} // namespace KFinder
