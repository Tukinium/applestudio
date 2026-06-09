<#
============================================================
 Windows サーバー堅牢化スクリプト（監査＋安全な自動設定）
 自宅サーバーとして公開しているPCの安全性を高めます。
------------------------------------------------------------
 方針:
  ・安全な設定（ファイアウォール有効化・更新確認など）は自動適用
  ・LANを壊しうる設定（RDP/共有の遮断など）は「監査して警告」のみ
   → 実際に閉じるかは結果を見てから判断します
 使い方:
  右クリック →「PowerShellで実行」（自動で管理者昇格）
============================================================
#>

$me = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
$ErrorActionPreference = "Continue"
function Title($t){ Write-Host "`n============================================================" -ForegroundColor Cyan; Write-Host " $t" -ForegroundColor Cyan; Write-Host "============================================================" -ForegroundColor Cyan }
function OK($t){ Write-Host "  [OK] $t" -ForegroundColor Green }
function WARN($t){ Write-Host "  [注意] $t" -ForegroundColor Yellow }
function FIX($t){ Write-Host "  [修正] $t" -ForegroundColor Magenta }

# ============================================================
#  1) Windows ファイアウォールを全プロファイルで有効化（自動）
# ============================================================
Title "1) ファイアウォール"
foreach ($p in (Get-NetFirewallProfile)) {
    if (-not $p.Enabled) {
        Set-NetFirewallProfile -Name $p.Name -Enabled True
        FIX "$($p.Name) プロファイルのファイアウォールを有効化しました"
    } else { OK "$($p.Name) プロファイル: 有効" }
}
# 受信の既定動作をブロックに（自動。許可した80/443以外は届かない）
Set-NetFirewallProfile -All -DefaultInboundAction Block -ErrorAction SilentlyContinue
OK "許可していない受信通信は既定でブロック"

# ============================================================
#  2) 公開に必要なポートだけ許可されているか確認
# ============================================================
Title "2) 公開ポート(80/443)の許可ルール"
foreach ($p in 80,443) {
    $r = Get-NetFirewallRule -DisplayName "AppleStudio Web (TCP $p)" -ErrorAction SilentlyContinue
    if ($r) { OK "ポート $p の許可ルールあり" } else { WARN "ポート $p の許可ルールが見つかりません（setup-server.ps1 を実行）" }
}

# ============================================================
#  3) 外部からの待ち受けポートを監査（重要）
# ============================================================
Title "3) 待ち受け中のポート一覧（外部公開の危険を確認）"
Write-Host "  0.0.0.0 / :: で待ち受けているTCPポート = 外部から接続されうる入口です。"
Write-Host "  80/443以外がここにあり、かつルーターで転送されていると危険です。`n"
$listen = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalAddress -in '0.0.0.0','::' } |
    Select-Object LocalPort -Unique | Sort-Object LocalPort
$risky = @{3389='リモートデスクトップ(RDP)';445='ファイル共有(SMB)';139='NetBIOS';135='RPC';5985='WinRM';5900='VNC';3306='MySQL';5432='PostgreSQL'}
foreach ($l in $listen) {
    $port = $l.LocalPort
    if ($risky.ContainsKey([int]$port)) {
        WARN "ポート $port が待受中: $($risky[[int]$port]) … ルーターで絶対に転送しないこと"
    } elseif ($port -in 80,443) {
        OK "ポート $port (Webサーバー) … 公開対象。OK"
    } else {
        Write-Host "  ・ポート $port が待受中（内容を確認推奨）" -ForegroundColor Gray
    }
}
Write-Host "`n  ※ ルーターのポート転送は 80 と 443 だけにしてください。" -ForegroundColor Yellow

# ============================================================
#  4) リモートデスクトップ(RDP)の状態確認
# ============================================================
Title "4) リモートデスクトップ(RDP)"
$rdp = (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections
if ($rdp -eq 0) {
    WARN "RDPが有効です。LAN内で使うのは可。ただしルーターで3389を絶対に開けないこと"
    $nla = (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -ErrorAction SilentlyContinue).UserAuthentication
    if ($nla -eq 1) { OK "ネットワークレベル認証(NLA): 有効" } else { WARN "NLAが無効です。RDP設定でNLAを有効にしてください" }
} else { OK "RDPは無効（外部からの侵入経路が1つ少ない）" }

# ============================================================
#  5) Windows Update の確認（自動で有効化）
# ============================================================
Title "5) Windows Update"
$wu = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
if ($wu) {
    if ($wu.StartType -eq 'Disabled') {
        Set-Service -Name wuauserv -StartupType Manual
        FIX "Windows Update サービスを有効化しました"
    } else { OK "Windows Update サービス: 有効 ($($wu.StartType))" }
    WARN "最新の更新が当たっているか、設定→Windows Update で手動確認を推奨"
}

# ============================================================
#  6) Microsoft Defender（ウイルス対策）
# ============================================================
Title "6) ウイルス対策(Defender)"
try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    if ($mp.RealTimeProtectionEnabled) { OK "リアルタイム保護: 有効" } else { WARN "リアルタイム保護が無効です。有効化を推奨" }
    if ($mp.AntivirusSignatureAge -le 3) { OK "定義ファイル: 最新に近い（$($mp.AntivirusSignatureAge)日前）" } else { WARN "定義ファイルが古い($($mp.AntivirusSignatureAge)日前)。更新を推奨" }
} catch { WARN "Defenderの状態を取得できません（別のウイルス対策ソフト使用中かも）" }

# ============================================================
#  7) 共有フォルダの確認
# ============================================================
Title "7) ネットワーク共有"
$shares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '\$$' }
if ($shares) {
    foreach ($s in $shares) { WARN "共有『$($s.Name)』($($s.Path)) が公開中。不要なら停止を検討" }
} else { OK "ユーザー作成の共有なし（管理共有のみ）" }

Title "監査完了"
Write-Host "緑[OK]はそのまま、黄[注意]は内容を確認してください。" -ForegroundColor Green
Write-Host "いちばん大事な原則: ルーターのポート転送は 80 と 443 だけ。" -ForegroundColor Yellow
Write-Host "RDP(3389)やファイル共有(445)は絶対に外向きに開けないこと。`n"
Read-Host "Enterで終了"
