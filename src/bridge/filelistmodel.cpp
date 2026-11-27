#include "filelistmodel.h"
#include <QCollator>
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
    sortEntries();
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
    sortEntries();
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

void FileListModel::slotItemsAdded(const QUrl &/*directoryUrl*/, const KFileItemList &items)
{
    if (items.isEmpty()) return;

    QList<FileItemEntry> newEntries;
    newEntries.reserve(items.size());
    for (const auto &item : items) {
        newEntries.append(createEntry(item));
    }

    beginInsertRows(QModelIndex(), m_entries.size(), m_entries.size() + newEntries.size() - 1);
    m_entries.append(newEntries);
    endInsertRows();

    sortEntries();
    Q_EMIT countChanged();
}

void FileListModel::slotItemsDeleted(const KFileItemList &items)
{
    if (items.isEmpty() || m_entries.isEmpty()) return;

    for (const auto &item : items) {
        for (int i = 0; i < m_entries.size(); ++i) {
            if (m_entries[i].item.url() == item.url()) {
                beginRemoveRows(QModelIndex(), i, i);
                m_entries.removeAt(i);
                endRemoveRows();
                break;
            }
        }
    }
    Q_EMIT countChanged();
}

void FileListModel::slotClear()
{
    if (m_entries.isEmpty()) return;
    beginResetModel();
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

void FileListModel::sortEntries()
{
    if (m_entries.size() <= 1) return;

    beginResetModel();
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

    endResetModel();
}

} // namespace KFinder
