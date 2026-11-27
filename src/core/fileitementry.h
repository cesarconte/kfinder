#pragma once

#include <QString>
#include <QUrl>
#include <QDateTime>
#include <KFileItem>

namespace KFinder {

struct FileItemEntry {
    KFileItem item;
    QString name;
    QString extension;
    QString iconName;
    QString sizeString;
    qint64 sizeBytes{0};
    QDateTime modifiedTime;
    QDateTime createdTime;
    bool isDirectory{false};
    bool isHidden{false};
    bool isSymLink{false};
    QString mimeType;
    QString tagColor;
    QString targetUrl;
};

} // namespace KFinder
