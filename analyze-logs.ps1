<#
============================================================
 アクセスログ監視・分析スクリプト
 Caddyのアクセスログ(access.log)を集計し、
 不正アクセスの兆候を表示します。
------------------------------------------------------------
 使い方:
   このフォルダで:
     powershell -ExecutionPolicy Bypass -File .\analyze-logs.ps1
   直近1000件だけ見る:
     powershell -ExecutionPolicy Bypass -File .\analyze-logs.ps1 -Tail 1000
============================================================
#>
param([int]$Tail = 0)

$ErrorActionPreference = "Stop"
$LogFile = Join-Path $PSScriptRoot "access.log"

function Title($t){ Write-Host "`n============================================================" -ForegroundColor Cyan; Write-Host " $t" -ForegroundColor Cyan; Write-Host "============================================================" -ForegroundColor Cyan }

if (-not (Test-Path $LogFile)) {
    Write-Host "access.log が見つかりません: $LogFile" -ForegroundColor Yellow
    Write-Host "Caddyが起動してアクセスがあれば自動で作られます。" -ForegroundColor Yellow
    Read-Host "Enterで終了"; exit
}

Write-Host "ログ読み込み中..." -ForegroundColor Gray
$raw = Get-Content $LogFile -Encoding UTF8
if ($Tail -gt 0 -and $raw.Count -gt $Tail) { $raw = $raw[-$Tail..-1] }

# JSONを解析
$logs = foreach ($line in $raw) {
    if ($line.Trim()) { try { $line | ConvertFrom-Json } catch {} }
}
$total = $logs.Count
if ($total -eq 0) { Write-Host "解析できるログがありません。" -ForegroundColor Yellow; Read-Host "Enterで終了"; exit }

# 期間
$first = ([DateTimeOffset]::FromUnixTimeSeconds([long]($logs[0].ts)).LocalDateTime)
$last  = ([DateTimeOffset]::FromUnixTimeSeconds([long]($logs[-1].ts)).LocalDateTime)

Title "概要"
Write-Host "  解析リクエスト数 : $total"
Write-Host "  期間             : $first  〜  $last"

# ステータスコード別
Title "ステータスコード別"
$logs | Group-Object status | Sort-Object Count -Descending | ForEach-Object {
    $c = $_.Name; $col = if($c -ge 500){'Red'}elseif($c -ge 400){'Yellow'}else{'Green'}
    Write-Host ("  {0,-5} : {1}" -f $c, $_.Count) -ForegroundColor $col
}

# アクセス元IP上位
Title "アクセス元IP 上位15"
$logs | Group-Object { $_.request.client_ip } | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
    Write-Host ("  {0,8}  {1}" -f $_.Count, $_.Name)
}

# 人気ページ上位
Title "リクエストされたパス 上位15"
$logs | Group-Object { $_.request.uri } | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
    Write-Host ("  {0,8}  {1}" -f $_.Count, $_.Name)
}

# ---------- 不正アクセスの兆候 ----------
Title "⚠ 不正アクセスの兆候（攻撃でよく狙われるパス）"
$attackPatterns = @(
    'wp-login','wp-admin','xmlrpc','\.env','\.git','phpmyadmin','phpinfo',
    '/admin','/administrator','\.php','/shell','/config','/backup','/\.aws',
    '/owa/','/vendor/','/cgi-bin','eval\(','base64','/boaform','/solr',
    '\.\./','/etc/passwd','/wp-content','/wordpress'
)
$rx = ($attackPatterns -join '|')
$suspicious = $logs | Where-Object { $_.request.uri -match $rx }
if ($suspicious) {
    Write-Host "  検出: $($suspicious.Count) 件の疑わしいリクエスト`n" -ForegroundColor Red
    Write-Host "  --- 攻撃元IP 上位 ---" -ForegroundColor Yellow
    $suspicious | Group-Object { $_.request.client_ip } | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
        Write-Host ("  {0,6}回  {1}" -f $_.Count, $_.Name) -ForegroundColor Red
    }
    Write-Host "`n  --- 狙われたパス 上位 ---" -ForegroundColor Yellow
    $suspicious | Group-Object { $_.request.uri } | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
        Write-Host ("  {0,6}回  {1}" -f $_.Count, $_.Name) -ForegroundColor DarkYellow
    }
    Write-Host "`n  ※ 静的サイトなので、これらはすべて404で弾かれており実害はありません。" -ForegroundColor Gray
    Write-Host "  ※ 同じIPからの大量試行が続く場合は、後述のIPブロックを検討してください。" -ForegroundColor Gray
} else {
    Write-Host "  疑わしいリクエストは検出されませんでした。" -ForegroundColor Green
}

# 404多発IP（探索行為の可能性）
Title "404が多いIP（探索行為の可能性）上位10"
$logs | Where-Object { $_.status -eq 404 } | Group-Object { $_.request.client_ip } | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host ("  {0,6}回 404  {1}" -f $_.Count, $_.Name) -ForegroundColor Yellow
}

Title "分析完了"
Write-Host "特定IPをブロックしたい場合は、教えてください。" -ForegroundColor Green
Write-Host "Windowsファイアウォールでの遮断、またはCaddyでの拒否設定を用意します。`n"
Read-Host "Enterで終了"
