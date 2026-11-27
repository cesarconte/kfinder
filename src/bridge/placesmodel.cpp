#include <QIcon>
#include "placesmodel.h"

namespace KFinder {

PlacesModel::PlacesModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_places(std::make_unique<KFilePlacesModel>())
{
    connect(m_places.get(), &QAbstractItemModel::rowsInserted, this, &PlacesModel::forwardRowsInserted);
    connect(m_places.get(), &QAbstractItemModel::rowsRemoved, this, &PlacesModel::forwardRowsRemoved);
    connect(m_places.get(), &QAbstractItemModel::dataChanged, this, &PlacesModel::forwardDataChanged);
}

PlacesModel::~PlacesModel() = default;

int PlacesModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_places->rowCount();
}

QVariant PlacesModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_places->rowCount())
        return {};

    const QModelIndex srcIdx = m_places->index(index.row(), 0);

    switch (role) {
    case Qt::DisplayRole:
    case TextRole:
        return m_places->data(srcIdx, Qt::DisplayRole);
    case UrlRole:
        return m_places->url(srcIdx).toString();
    case IconNameRole:
        return m_places->icon(srcIdx).name();
    case GroupRole:
        return m_places->data(srcIdx, KFilePlacesModel::GroupRole);
    case IsGroupRole:
        return m_places->isGroupHidden(srcIdx);
    case IsDeviceRole:
        return m_places->isDevice(srcIdx);
    case IsTeardownAllowedRole:
        return m_places->isTeardownAllowed(srcIdx);
    case IsTeardownOverlayRole:
        return m_places->isTeardownOverlayRecommended(srcIdx);
    default:
        return {};
    }
}

QHash<int, QByteArray> PlacesModel::roleNames() const
{
    return {
        {UrlRole, "url"},
        {TextRole, "text"},
        {IconNameRole, "iconName"},
        {GroupRole, "group"},
        {IsGroupRole, "isGroup"},
        {IsDeviceRole, "isDevice"},
        {IsTeardownAllowedRole, "isTeardownAllowed"},
        {IsTeardownOverlayRole, "isTeardownOverlay"}
    };
}

int PlacesModel::count() const
{
    return m_places->rowCount();
}

QUrl PlacesModel::urlForIndex(int row) const
{
    if (row < 0 || row >= m_places->rowCount()) return {};
    return m_places->url(m_places->index(row, 0));
}

void PlacesModel::requestTeardown(int row)
{
    if (row < 0 || row >= m_places->rowCount()) return;
    m_places->requestTeardown(m_places->index(row, 0));
}

void PlacesModel::forwardRowsInserted(const QModelIndex &, int start, int end)
{
    beginInsertRows(QModelIndex(), start, end);
    endInsertRows();
    Q_EMIT countChanged();
}

void PlacesModel::forwardRowsRemoved(const QModelIndex &, int start, int end)
{
    beginRemoveRows(QModelIndex(), start, end);
    endRemoveRows();
    Q_EMIT countChanged();
}

void PlacesModel::forwardDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight, const QList<int> &)
{
    Q_EMIT dataChanged(index(topLeft.row(), 0), index(bottomRight.row(), 0));
}

} // namespace KFinder
