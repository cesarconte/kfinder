#pragma once

#include <QAbstractListModel>
#include <QUrl>
#include <QList>
#include <KCoreDirLister>
#include <KFileItem>
#include "core/fileitementry.h"

namespace KFinder {

class FileListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QUrl currentUrl READ currentUrl WRITE setUrl NOTIFY currentUrlChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool showHiddenFiles READ showHiddenFiles WRITE setShowHiddenFiles NOTIFY showHiddenFilesChanged)
    Q_PROPERTY(int sortRole READ sortRole WRITE setSortRole NOTIFY sortRoleChanged)
    Q_PROPERTY(Qt::SortOrder sortOrder READ sortOrder WRITE setSortOrder NOTIFY sortOrderChanged)

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        UrlRole,
        IconNameRole,
        SizeStringRole,
        SizeBytesRole,
        ModifiedDateRole,
        CreatedDateRole,
        IsDirectoryRole,
        IsHiddenRole,
        IsSymLinkRole,
        MimeTypeRole,
        TagColorRole,
        TargetPathRole
    };
    Q_ENUM(Roles)

    explicit FileListModel(QObject *parent = nullptr);
    ~FileListModel() override;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QUrl currentUrl() const;
    Q_INVOKABLE void setUrl(const QUrl &url);

    int count() const;
    bool loading() const;

    bool showHiddenFiles() const;
    void setShowHiddenFiles(bool show);

    int sortRole() const;
    void setSortRole(int role);

    Qt::SortOrder sortOrder() const;
    void setSortOrder(Qt::SortOrder order);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void goUp();
    Q_INVOKABLE QVariantMap get(int index) const;

Q_SIGNALS:
    void currentUrlChanged();
    void countChanged();
    void loadingChanged();
    void showHiddenFilesChanged();
    void sortRoleChanged();
    void sortOrderChanged();
    void directoryLoaded();

private Q_SLOTS:
    void slotItemsAdded(const QUrl &directoryUrl, const KFileItemList &items);
    void slotItemsDeleted(const KFileItemList &items);
    void slotClear();
    void slotCompleted();
    void slotCanceled();

private:
    void sortEntries();
    static FileItemEntry createEntry(const KFileItem &item);

    QUrl m_url;
    KCoreDirLister *m_dirLister{nullptr};
    QList<FileItemEntry> m_entries;
    bool m_loading{false};
    bool m_showHiddenFiles{false};
    int m_sortRole{NameRole};
    Qt::SortOrder m_sortOrder{Qt::AscendingOrder};
};

} // namespace KFinder
