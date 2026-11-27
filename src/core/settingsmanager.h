#pragma once

#include <QObject>
#include <QSettings>

namespace KFinder {

class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool showFileExtensions READ showFileExtensions WRITE setShowFileExtensions NOTIFY showFileExtensionsChanged)
    Q_PROPERTY(bool confirmEmptyTrash READ confirmEmptyTrash WRITE setConfirmEmptyTrash NOTIFY confirmEmptyTrashChanged)
    Q_PROPERTY(bool keepFoldersOnTop READ keepFoldersOnTop WRITE setKeepFoldersOnTop NOTIFY keepFoldersOnTopChanged)
    Q_PROPERTY(int defaultViewMode READ defaultViewMode WRITE setDefaultViewMode NOTIFY defaultViewModeChanged)
    Q_PROPERTY(int keyboardProfile READ keyboardProfile WRITE setKeyboardProfile NOTIFY keyboardProfileChanged) // 0: Finder, 1: Dolphin
    Q_PROPERTY(bool showHiddenFiles READ showHiddenFiles WRITE setShowHiddenFiles NOTIFY showHiddenFilesChanged)
    Q_PROPERTY(bool showTerminalPanel READ showTerminalPanel WRITE setShowTerminalPanel NOTIFY showTerminalPanelChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);
    ~SettingsManager() override = default;

    bool showFileExtensions() const;
    void setShowFileExtensions(bool show);

    bool confirmEmptyTrash() const;
    void setConfirmEmptyTrash(bool confirm);

    bool keepFoldersOnTop() const;
    void setKeepFoldersOnTop(bool keep);

    int defaultViewMode() const;
    void setDefaultViewMode(int mode);

    int keyboardProfile() const;
    void setKeyboardProfile(int profile);

    bool showHiddenFiles() const;
    void setShowHiddenFiles(bool show);

    bool showTerminalPanel() const;
    void setShowTerminalPanel(bool show);

    Q_INVOKABLE void save();
    Q_INVOKABLE void restoreDefaults();

Q_SIGNALS:
    void showFileExtensionsChanged();
    void confirmEmptyTrashChanged();
    void keepFoldersOnTopChanged();
    void defaultViewModeChanged();
    void keyboardProfileChanged();
    void showHiddenFilesChanged();
    void showTerminalPanelChanged();

private:
    void load();

    QSettings m_settings;
    bool m_showFileExtensions{true};
    bool m_confirmEmptyTrash{true};
    bool m_keepFoldersOnTop{true};
    int m_defaultViewMode{0}; // 0: Icons
    int m_keyboardProfile{0}; // 0: Finder
    bool m_showHiddenFiles{false};
    bool m_showTerminalPanel{false};
};

} // namespace KFinder
