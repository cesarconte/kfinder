#include "settingsmanager.h"

namespace KFinder {

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
    , m_settings(QStringLiteral("kfinder"), QStringLiteral("kfinderrc"))
{
    load();
}

void SettingsManager::load()
{
    m_showFileExtensions = m_settings.value(QStringLiteral("General/ShowFileExtensions"), true).toBool();
    m_confirmEmptyTrash = m_settings.value(QStringLiteral("General/ConfirmEmptyTrash"), true).toBool();
    m_keepFoldersOnTop = m_settings.value(QStringLiteral("General/KeepFoldersOnTop"), true).toBool();
    m_defaultViewMode = m_settings.value(QStringLiteral("General/DefaultViewMode"), 0).toInt();
    m_keyboardProfile = m_settings.value(QStringLiteral("General/KeyboardProfile"), 0).toInt();
    m_showHiddenFiles = m_settings.value(QStringLiteral("General/ShowHiddenFiles"), false).toBool();
    m_showTerminalPanel = m_settings.value(QStringLiteral("General/ShowTerminalPanel"), false).toBool();
}

void SettingsManager::save()
{
    m_settings.setValue(QStringLiteral("General/ShowFileExtensions"), m_showFileExtensions);
    m_settings.setValue(QStringLiteral("General/ConfirmEmptyTrash"), m_confirmEmptyTrash);
    m_settings.setValue(QStringLiteral("General/KeepFoldersOnTop"), m_keepFoldersOnTop);
    m_settings.setValue(QStringLiteral("General/DefaultViewMode"), m_defaultViewMode);
    m_settings.setValue(QStringLiteral("General/KeyboardProfile"), m_keyboardProfile);
    m_settings.setValue(QStringLiteral("General/ShowHiddenFiles"), m_showHiddenFiles);
    m_settings.setValue(QStringLiteral("General/ShowTerminalPanel"), m_showTerminalPanel);
    m_settings.sync();
}

void SettingsManager::restoreDefaults()
{
    setShowFileExtensions(true);
    setConfirmEmptyTrash(true);
    setKeepFoldersOnTop(true);
    setDefaultViewMode(0);
    setKeyboardProfile(0);
    setShowHiddenFiles(false);
    setShowTerminalPanel(false);
    save();
}

bool SettingsManager::showFileExtensions() const
{
    return m_showFileExtensions;
}

void SettingsManager::setShowFileExtensions(bool show)
{
    if (m_showFileExtensions == show) return;
    m_showFileExtensions = show;
    m_settings.setValue(QStringLiteral("General/ShowFileExtensions"), m_showFileExtensions);
    Q_EMIT showFileExtensionsChanged();
}

bool SettingsManager::confirmEmptyTrash() const
{
    return m_confirmEmptyTrash;
}

void SettingsManager::setConfirmEmptyTrash(bool confirm)
{
    if (m_confirmEmptyTrash == confirm) return;
    m_confirmEmptyTrash = confirm;
    m_settings.setValue(QStringLiteral("General/ConfirmEmptyTrash"), m_confirmEmptyTrash);
    Q_EMIT confirmEmptyTrashChanged();
}

bool SettingsManager::keepFoldersOnTop() const
{
    return m_keepFoldersOnTop;
}

void SettingsManager::setKeepFoldersOnTop(bool keep)
{
    if (m_keepFoldersOnTop == keep) return;
    m_keepFoldersOnTop = keep;
    m_settings.setValue(QStringLiteral("General/KeepFoldersOnTop"), m_keepFoldersOnTop);
    Q_EMIT keepFoldersOnTopChanged();
}

int SettingsManager::defaultViewMode() const
{
    return m_defaultViewMode;
}

void SettingsManager::setDefaultViewMode(int mode)
{
    if (m_defaultViewMode == mode) return;
    m_defaultViewMode = mode;
    m_settings.setValue(QStringLiteral("General/DefaultViewMode"), m_defaultViewMode);
    Q_EMIT defaultViewModeChanged();
}

int SettingsManager::keyboardProfile() const
{
    return m_keyboardProfile;
}

void SettingsManager::setKeyboardProfile(int profile)
{
    if (m_keyboardProfile == profile) return;
    m_keyboardProfile = profile;
    m_settings.setValue(QStringLiteral("General/KeyboardProfile"), m_keyboardProfile);
    Q_EMIT keyboardProfileChanged();
}

bool SettingsManager::showHiddenFiles() const
{
    return m_showHiddenFiles;
}

void SettingsManager::setShowHiddenFiles(bool show)
{
    if (m_showHiddenFiles == show) return;
    m_showHiddenFiles = show;
    m_settings.setValue(QStringLiteral("General/ShowHiddenFiles"), m_showHiddenFiles);
    Q_EMIT showHiddenFilesChanged();
}

bool SettingsManager::showTerminalPanel() const
{
    return m_showTerminalPanel;
}

void SettingsManager::setShowTerminalPanel(bool show)
{
    if (m_showTerminalPanel == show) return;
    m_showTerminalPanel = show;
    m_settings.setValue(QStringLiteral("General/ShowTerminalPanel"), m_showTerminalPanel);
    Q_EMIT showTerminalPanelChanged();
}

} // namespace KFinder
