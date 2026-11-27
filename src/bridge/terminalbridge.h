#pragma once

#include <QObject>
#include <QProcess>

namespace KFinder {

class TerminalBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString workingDirectory READ workingDirectory WRITE setWorkingDirectory NOTIFY workingDirectoryChanged)
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
    explicit TerminalBridge(QObject *parent = nullptr);
    ~TerminalBridge() override;

    QString workingDirectory() const;
    void setWorkingDirectory(const QString &dir);

    QString output() const;
    bool running() const;

    Q_INVOKABLE void sendCommand(const QString &cmd);
    Q_INVOKABLE void clear();
    Q_INVOKABLE void interrupt();
    Q_INVOKABLE void startShell();

Q_SIGNALS:
    void workingDirectoryChanged();
    void outputChanged();
    void runningChanged();
    void commandExecuted(const QString &cmd);

private Q_SLOTS:
    void handleReadyRead();
    void handleProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    void appendOutput(const QString &text);

    QProcess *m_process{nullptr};
    QString m_workingDir;
    QString m_output;
    bool m_running{false};
};

} // namespace KFinder
