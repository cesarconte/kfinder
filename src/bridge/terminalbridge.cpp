#include "terminalbridge.h"
#include <QDir>
#include <QProcessEnvironment>

namespace KFinder {

TerminalBridge::TerminalBridge(QObject *parent)
    : QObject(parent)
{
    m_workingDir = QDir::homePath();
}

TerminalBridge::~TerminalBridge()
{
    if (m_process) {
        m_process->disconnect(this);
        m_process->terminate();
        if (!m_process->waitForFinished(500)) {
            m_process->kill();
        }
        delete m_process;
        m_process = nullptr;
    }
}

QString TerminalBridge::workingDirectory() const
{
    return m_workingDir;
}

void TerminalBridge::setWorkingDirectory(const QString &dir)
{
    if (dir.isEmpty() || m_workingDir == dir) return;

    m_workingDir = dir;
    Q_EMIT workingDirectoryChanged();

    if (m_process && m_process->state() == QProcess::Running) {
        sendCommand(QStringLiteral("cd \"%1\"").arg(m_workingDir));
    }
}

QString TerminalBridge::output() const
{
    return m_output;
}

bool TerminalBridge::running() const
{
    return m_running;
}

void TerminalBridge::startShell()
{
    if (m_process && m_process->state() == QProcess::Running) return;

    if (m_process) {
        m_process->deleteLater();
    }

    m_process = new QProcess(this);
    m_process->setWorkingDirectory(m_workingDir);
    m_process->setProcessChannelMode(QProcess::MergedChannels);

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("TERM"), QStringLiteral("xterm-256color"));
    m_process->setProcessEnvironment(env);

    connect(m_process, &QProcess::readyRead, this, &TerminalBridge::handleReadyRead);
    connect(m_process, &QProcess::finished, this, &TerminalBridge::handleProcessFinished);

    m_process->start(QStringLiteral("/bin/bash"), QStringList() << QStringLiteral("--norc") << QStringLiteral("-i"));
    m_running = true;
    Q_EMIT runningChanged();

    appendOutput(QStringLiteral("Terminal iniciada en: %1\n").arg(m_workingDir));
}

void TerminalBridge::sendCommand(const QString &cmd)
{
    if (!m_process || m_process->state() != QProcess::Running) {
        startShell();
    }

    if (m_process && m_process->state() == QProcess::Running) {
        appendOutput(QStringLiteral("$ %1\n").arg(cmd));
        QByteArray data = cmd.toUtf8() + '\n';
        m_process->write(data);
        Q_EMIT commandExecuted(cmd);
    }
}

void TerminalBridge::clear()
{
    m_output.clear();
    Q_EMIT outputChanged();
}

void TerminalBridge::interrupt()
{
    if (m_process && m_process->state() == QProcess::Running) {
        // Send SIGINT / Ctrl+C
        m_process->write("\x03");
    }
}

void TerminalBridge::handleReadyRead()
{
    if (!m_process) return;
    QByteArray data = m_process->readAll();
    appendOutput(QString::fromUtf8(data));
}

void TerminalBridge::handleProcessFinished(int /*exitCode*/, QProcess::ExitStatus /*exitStatus*/)
{
    m_running = false;
    Q_EMIT runningChanged();
    appendOutput(QStringLiteral("\n[Proceso terminado]\n"));
}

void TerminalBridge::appendOutput(const QString &text)
{
    m_output.append(text);
    // Keep max ~50,000 characters in scrollback to preserve memory
    if (m_output.length() > 60000) {
        m_output = m_output.right(40000);
    }
    Q_EMIT outputChanged();
}

} // namespace KFinder
