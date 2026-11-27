#pragma once

#include <QAbstractListModel>
#include <QUrl>
#include <memory>
#include <KFilePlacesModel>

namespace KFinder {

class PlacesModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        UrlRole = Qt::UserRole + 1,
        TextRole,
        IconNameRole,
        IsGroupRole,
        IsDeviceRole,
        IsTeardownAllowedRole,
        IsTeardownOverlayRole
    };
    Q_ENUM(Roles)

    explicit PlacesModel(QObject *parent = nullptr);
    ~PlacesModel() override;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;
    Q_INVOKABLE QUrl urlForIndex(int row) const;
    Q_INVOKABLE void requestTeardown(int row);

Q_SIGNALS:
    void countChanged();

private Q_SLOTS:
    void forwardRowsInserted(const QModelIndex &parent, int start, int end);
    void forwardRowsRemoved(const QModelIndex &parent, int start, int end);
    void forwardDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight, const QList<int> &roles);

private:
    std::unique_ptr<KFilePlacesModel> m_places;
};

} // namespace KFinder
