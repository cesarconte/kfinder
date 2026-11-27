#include "filelistmodel.h"
#include <QCollator>
#include <QProcess>
#include <QDir>
#include <QFileInfo>
#include <KFormat>
#include <sys/xattr.h>

namespace KFinder {

static QString readTagColor(const QString &localPath)
{
    if (localPath.isEmpty()) return {};
    char buffer[128];
    ssize_t len = getxattr(localPath.toUtf8().constData(), "user.color.tag", buffer, sizeof(buffer) - 1);
    if (len > 0) {
        buffer[len] = '\0';
        return QString::fromUtf8(buffer).trimmed().toLower();
    }
    return {};
}

FileListModel::FileListModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_dirLister(new KCoreDirLister(this))
{
    m_dirLister->setAutoUpdate(true);
    m_dirLister->setDelayedMimeTypes(true);

    connect(m_dirLister, &KCoreDirLister::itemsAdded, this, &FileListModel::slotItemsAdded);
    connect(m_dirLister, &KCoreDirLister::itemsDeleted, this, &FileListModel::slotItemsDeleted);
    connect(m_dirLister, &KCoreDirLister::clear, this, &FileListModel::slotClear);
    connect(m_dirLister, &KCoreDirLister::completed, this, &FileListModel::slotCompleted);
    connect(m_dirLister, &KCoreDirLister::canceled, this, &FileListModel::slotCanceled);
}

FileListModel::~FileListModel()
{
    cancelSearchProcess();
    if (m_dirLister) {
        m_dirLister->stop();
    }
}

int FileListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_entries.size();
}

QVariant FileListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};

    const auto &entry = m_entries.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
    case NameRole:
        return entry.name;
    case UrlRole:
        return entry.item.url().toString();
    case IconNameRole:
        return entry.iconName;
    case SizeStringRole:
        return entry.sizeString;
    case SizeBytesRole:
        return entry.sizeBytes;
    case ModifiedDateRole:
        return entry.modifiedTime;
    case CreatedDateRole:
        return entry.createdTime;
    case IsDirectoryRole:
        return entry.isDirectory;
    case IsHiddenRole:
        return entry.isHidden;
    case IsSymLinkRole:
        return entry.isSymLink;
    case MimeTypeRole:
        return entry.mimeType;
    case TagColorRole:
        return entry.tagColor;
    case TargetPathRole:
        return entry.targetUrl;
    default:
        return {};
    }
}

QHash<int, QByteArray> FileListModel::roleNames() const
{
    return {
        {NameRole, "name"},
        {UrlRole, "url"},
        {IconNameRole, "iconName"},
        {SizeStringRole, "sizeString"},
        {SizeBytesRole, "sizeBytes"},
        {ModifiedDateRole, "modifiedDate"},
        {CreatedDateRole, "createdDate"},
        {IsDirectoryRole, "isDirectory"},
        {IsHiddenRole, "isHidden"},
        {IsSymLinkRole, "isSymLink"},
        {MimeTypeRole, "mimeType"},
        {TagColorRole, "tagColor"},
        {TargetPathRole, "targetPath"}
    };
}

QUrl FileListModel::currentUrl() const
{
    return m_url;
}

void FileListModel::setUrl(const QUrl &url)
{
    if (m_url == url) return;

    cancelSearchProcess();
    if (!m_filterText.isEmpty()) {
        m_filterText.clear();
        Q_EMIT filterTextChanged();
        Q_EMIT isSearchingChanged();
    }

    m_url = url;
    Q_EMIT currentUrlChanged();

    if (!m_loading) {
        m_loading = true;
        Q_EMIT loadingChanged();
    }

    m_dirLister->openUrl(m_url, KCoreDirLister::Reload);
}

int FileListModel::count() const
{
    return m_entries.size();
}

bool FileListModel::loading() const
{
    return m_loading;
}

bool FileListModel::showHiddenFiles() const
{
    return m_showHiddenFiles;
}

void FileListModel::setShowHiddenFiles(bool show)
{
    if (m_showHiddenFiles == show) return;
    m_showHiddenFiles = show;
    m_dirLister->setShowHiddenFiles(m_showHiddenFiles);
    Q_EMIT showHiddenFilesChanged();
    refresh();
}

int FileListModel::sortRole() const
{
    return m_sortRole;
}

void FileListModel::setSortRole(int role)
{
    if (m_sortRole == role) return;
    m_sortRole = role;
    Q_EMIT sortRoleChanged();
    applyFilterAndSort();
}

Qt::SortOrder FileListModel::sortOrder() const
{
    return m_sortOrder;
}

void FileListModel::setSortOrder(Qt::SortOrder order)
{
    if (m_sortOrder == order) return;
    m_sortOrder = order;
    Q_EMIT sortOrderChanged();
    applyFilterAndSort();
}

QString FileListModel::filterText() const
{
    return m_filterText;
}

void FileListModel::setFilterText(const QString &text)
{
    if (m_filterText == text) return;
    bool wasSearching = isSearching();
    m_filterText = text;
    Q_EMIT filterTextChanged();
    if (wasSearching != isSearching()) {
        Q_EMIT isSearchingChanged();
    }

    if (m_filterText.trimmed().isEmpty()) {
        cancelSearchProcess();
        applyFilterAndSort();
    } else {
        if (m_searchScope == 0) {
            startSearchProcess(QDir::homePath());
        } else {
            cancelSearchProcess();
            applyFilterAndSort();
        }
    }
}

int FileListModel::searchScope() const
{
    return m_searchScope;
}

void FileListModel::setSearchScope(int scope)
{
    if (m_searchScope == scope) return;
    m_searchScope = scope;
    Q_EMIT searchScopeChanged();

    if (isSearching()) {
        if (m_searchScope == 0) {
            startSearchProcess(QDir::homePath());
        } else {
            cancelSearchProcess();
            applyFilterAndSort();
        }
    }
}

bool FileListModel::isSearching() const
{
    return !m_filterText.trimmed().isEmpty();
}

void FileListModel::triggerDeepSearch()
{
    if (m_filterText.trimmed().isEmpty()) return;
    if (m_searchScope == 1 && m_url.isLocalFile()) {
        startSearchProcess(m_url.toLocalFile());
    } else {
        startSearchProcess(QDir::homePath());
    }
}

void FileListModel::refresh()
{
    if (m_url.isValid()) {
        m_loading = true;
        Q_EMIT loadingChanged();
        m_dirLister->openUrl(m_url, KCoreDirLister::Reload);
    }
}

void FileListModel::goUp()
{
    if (!m_url.isValid()) return;
    QUrl parentUrl = KIO::upUrl(m_url);
    if (parentUrl.isValid() && parentUrl != m_url) {
        setUrl(parentUrl);
    }
}

QVariantMap FileListModel::get(int index) const
{
    if (index < 0 || index >= m_entries.size()) return {};
    const auto &e = m_entries.at(index);
    return {
        {QStringLiteral("name"), e.name},
        {QStringLiteral("url"), e.item.url().toString()},
        {QStringLiteral("iconName"), e.iconName},
        {QStringLiteral("sizeString"), e.sizeString},
        {QStringLiteral("sizeBytes"), e.sizeBytes},
        {QStringLiteral("modifiedDate"), e.modifiedTime},
        {QStringLiteral("createdDate"), e.createdTime},
        {QStringLiteral("isDirectory"), e.isDirectory},
        {QStringLiteral("isHidden"), e.isHidden},
        {QStringLiteral("isSymLink"), e.isSymLink},
        {QStringLiteral("mimeType"), e.mimeType},
        {QStringLiteral("tagColor"), e.tagColor},
        {QStringLiteral("targetPath"), e.targetUrl}
    };
}

FileItemEntry FileListModel::createEntry(const KFileItem &item)
{
    FileItemEntry entry;
    entry.item = item;
    entry.name = item.text();
    entry.isDirectory = item.isDir();
    entry.isHidden = item.isHidden();
    entry.isSymLink = item.isLink();
    entry.mimeType = item.mimetype();
    entry.iconName = item.iconName();
    if (entry.isDirectory && (entry.iconName.isEmpty() || entry.iconName == QLatin1String("folder"))) {
        entry.iconName = QStringLiteral("inode-directory");
    }
    entry.modifiedTime = item.time(KFileItem::ModificationTime);
    entry.createdTime = item.time(KFileItem::CreationTime);

    if (entry.isDirectory) {
        entry.sizeString = QStringLiteral("--");
        entry.sizeBytes = 0;
    } else {
        entry.sizeBytes = item.size();
        KFormat format;
        entry.sizeString = format.formatByteSize(entry.sizeBytes);
    }

    if (item.isLocalFile()) {
        entry.tagColor = readTagColor(item.localPath());
        if (entry.isSymLink) {
            entry.targetUrl = item.linkDest();
        }
    }

    return entry;
}

FileItemEntry FileListModel::createEntryFromPath(const QString &filePath)
{
    QUrl url = QUrl::fromLocalFile(filePath);
    KFileItem item(url);
    return createEntry(item);
}

void FileListModel::slotItemsAdded(const QUrl &/*directoryUrl*/, const KFileItemList &items)
{
    if (items.isEmpty()) return;

    for (const auto &item : items) {
        m_rawEntries.append(createEntry(item));
    }

    applyFilterAndSort();
}

void FileListModel::slotItemsDeleted(const KFileItemList &items)
{
    if (items.isEmpty() || m_rawEntries.isEmpty()) return;

    for (const auto &item : items) {
        for (int i = 0; i < m_rawEntries.size(); ++i) {
            if (m_rawEntries[i].item.url() == item.url()) {
                m_rawEntries.removeAt(i);
                break;
            }
        }
    }
    applyFilterAndSort();
}

void FileListModel::slotClear()
{
    cancelSearchProcess();
    beginResetModel();
    m_rawEntries.clear();
    m_entries.clear();
    endResetModel();
    Q_EMIT countChanged();
}

void FileListModel::slotCompleted()
{
    m_loading = false;
    Q_EMIT loadingChanged();
    Q_EMIT directoryLoaded();
}

void FileListModel::slotCanceled()
{
    m_loading = false;
    Q_EMIT loadingChanged();
}

void FileListModel::applyFilterAndSort()
{
    beginResetModel();
    if (m_filterText.trimmed().isEmpty()) {
        m_entries = m_rawEntries;
    } else if (m_searchScope == 1 && !m_searchProcess) {
        m_entries.clear();
        const QString term = m_filterText.trimmed();
        for (const auto &entry : m_rawEntries) {
            if (entry.name.contains(term, Qt::CaseInsensitive)) {
                m_entries.append(entry);
            }
        }
    }

    if (m_entries.size() > 1) {
        QCollator collator;
        collator.setNumericMode(true);
        collator.setCaseSensitivity(Qt::CaseInsensitive);

        std::sort(m_entries.begin(), m_entries.end(), [this, &collator](const FileItemEntry &a, const FileItemEntry &b) {
            if (a.isDirectory != b.isDirectory) {
                return a.isDirectory > b.isDirectory;
            }

            int cmp = 0;
            switch (m_sortRole) {
            case SizeBytesRole:
                if (a.sizeBytes != b.sizeBytes) {
                    return m_sortOrder == Qt::AscendingOrder ? (a.sizeBytes < b.sizeBytes) : (a.sizeBytes > b.sizeBytes);
                }
                break;
            case ModifiedDateRole:
                if (a.modifiedTime != b.modifiedTime) {
                    return m_sortOrder == Qt::AscendingOrder ? (a.modifiedTime < b.modifiedTime) : (a.modifiedTime > b.modifiedTime);
                }
                break;
            case CreatedDateRole:
                if (a.createdTime != b.createdTime) {
                    return m_sortOrder == Qt::AscendingOrder ? (a.createdTime < b.createdTime) : (a.createdTime > b.createdTime);
                }
                break;
            case NameRole:
            default:
                cmp = collator.compare(a.name, b.name);
                break;
            }

            if (cmp == 0) {
                cmp = collator.compare(a.name, b.name);
            }

            return m_sortOrder == Qt::AscendingOrder ? (cmp < 0) : (cmp > 0);
        });
    }

    endResetModel();
    Q_EMIT countChanged();
}

void FileListModel::startSearchProcess(const QString &baseDir)
{
    cancelSearchProcess();

    if (m_filterText.trimmed().isEmpty()) return;

    m_searchProcess = new QProcess(this);
    m_loading = true;
    Q_EMIT loadingChanged();

    beginResetModel();
    m_entries.clear();
    endResetModel();
    Q_EMIT countChanged();

    connect(m_searchProcess, &QProcess::readyReadStandardOutput, this, &FileListModel::slotSearchOutput);
    connect(m_searchProcess, &QProcess::finished, this, &FileListModel::slotSearchFinished);

    QStringList args;
    args << QStringLiteral("--hidden")
         << QStringLiteral("-I")
         << QStringLiteral("--max-results") << QStringLiteral("300")
         << m_filterText.trimmed()
         << baseDir;

    m_searchProcess->start(QStringLiteral("fd"), args);
}

void FileListModel::cancelSearchProcess()
{
    if (m_searchProcess) {
        m_searchProcess->disconnect(this);
        m_searchProcess->kill();
        m_searchProcess->deleteLater();
        m_searchProcess = nullptr;
    }
}

void FileListModel::slotSearchOutput()
{
    if (!m_searchProcess) return;

    QByteArray data = m_searchProcess->readAllStandardOutput();
    QList<QByteArray> lines = data.split('\n');
    QList<FileItemEntry> batch;
    batch.reserve(lines.size());

    for (const auto &line : lines) {
        QString path = QString::fromUtf8(line).trimmed();
        if (path.isEmpty()) continue;
        batch.append(createEntryFromPath(path));
    }

    if (!batch.isEmpty()) {
        beginInsertRows(QModelIndex(), m_entries.size(), m_entries.size() + batch.size() - 1);
        m_entries.append(batch);
        endInsertRows();
        Q_EMIT countChanged();
    }
}

void FileListModel::slotSearchFinished()
{
    m_loading = false;
    Q_EMIT loadingChanged();
    if (m_searchProcess) {
        m_searchProcess->deleteLater();
        m_searchProcess = nullptr;
    }
}

} // namespace KFinder
