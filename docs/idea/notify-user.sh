#!/bin/bash
# Claude Code Notification Hook
# stdin으로 전달받은 JSON을 읽어 Windows 토스트 알림을 표시합니다.

INPUT=$(cat)

# 임시 파일에 JSON 저장 (인코딩 문제 방지)
TMPFILE=$(mktemp /tmp/claude-notify-XXXXXX.json)
printf '%s\n' "$INPUT" > "$TMPFILE"
TMPFILE_WIN=$(cygpath -w "$TMPFILE" 2>/dev/null || echo "$TMPFILE")

powershell.exe -NoProfile -Command "
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

\$json = Get-Content -Path '$TMPFILE_WIN' -Raw -Encoding UTF8 | ConvertFrom-Json
\$type = \$json.notification_type
\$title = switch (\$type) {
    'permission_prompt' { 'Claude Code - 승인 요청' }
    'elicitation_dialog' { 'Claude Code - 확인 필요' }
    'idle_prompt' { 'Claude Code - 작업 완료' }
    default { 'Claude Code' }
}
\$message = \$json.message

Remove-Item -Path '$TMPFILE_WIN' -Force -ErrorAction SilentlyContinue

if (-not \$message) { exit 0 }

Add-Type -AssemblyName System.Windows.Forms
\$notify = New-Object System.Windows.Forms.NotifyIcon
\$notify.Icon = [System.Drawing.SystemIcons]::Information
\$notify.Visible = \$true
\$notify.ShowBalloonTip(5000, \$title, \$message, 'Info')
Start-Sleep -Milliseconds 500
\$notify.Dispose()
"

# 혹시 남아있을 경우 정리
rm -f "$TMPFILE" 2>/dev/null

exit 0
