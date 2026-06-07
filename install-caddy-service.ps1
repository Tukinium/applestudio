<#
============================================================
 Caddy を Windows サービスとして登録するスクリプト
 （PC起動時に自動でサイトが立ち上がり、ウィンドウを閉じても動き続けます）
 公式推奨の WinSW を使います。
------------------------------------------------------------
 使い方:
   このファイルを右クリック →「PowerShellで実行」
   （自動で管理者権限に昇格します）
 サービスを後で止めたい/消したいとき:
   powershell -ExecutionPolicy Bypass -File .\install-caddy-service.ps1 -Uninstall
============================================================
#>

param([switch]$Uninstall)

# ---------- 管理者権限へ自動昇格 ----------
$me = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $a = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Uninstall) { $a += " -Uninstall" }
    Start-Process powershell -Verb RunAs -ArgumentList $a
    exit
}

$ErrorActionPreference = "Stop"
# 外部コマンド(caddy等)の終了コードを致命エラー扱いしない（stopで停止対象が無い場合などの誤判定を防ぐ）
$PSNativeCommandUseErrorActionPreference = $false
# エラーが起きてもウィンドウを閉じず、内容を表示して止める
trap { Write-Host "`n[エラー] $($_.Exception.Message)" -ForegroundColor Red; Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray; Read-Host "Enterで終了"; exit 1 }
$SiteDir     = "E:\AppleStudioWebPages\AppleStudioWebPage"
$ServiceExe  = Join-Path $SiteDir "caddy-service.exe"
$ServiceXml  = Join-Path $SiteDir "caddy-service.xml"
$WinswUrl    = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW.NET4.exe"

function Title($t){ Write-Host "`n============================================================" -ForegroundColor Cyan; Write-Host " $t" -ForegroundColor Cyan; Write-Host "============================================================" -ForegroundColor Cyan }

# 外部コマンドを「失敗しても無視・出力も全部捨てる」で安全に呼ぶ
function Quiet([string]$exe, [string[]]$argv){
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try { & $exe @argv *>$null } catch {}
    $ErrorActionPreference = $old
}

# ============================================================
#  アンインストール
# ============================================================
if ($Uninstall) {
    Title "Caddy サービスを削除します"
    if (Test-Path $ServiceExe) {
        Quiet $ServiceExe @('stop')
        Quiet $ServiceExe @('uninstall')
        Write-Host "  サービスを削除しました。" -ForegroundColor Green
    } else {
        Write-Host "  caddy-service.exe が見つかりません（既に削除済み？）" -ForegroundColor Yellow
    }
    Read-Host "Enterで終了"; exit
}

# ============================================================
#  1) caddy.exe の場所を特定
# ============================================================
Title "1) caddy.exe を探しています"
$caddy = $null
$pkg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "caddy*.exe" -ErrorAction SilentlyContinue |
       Where-Object { $_.Length -gt 1mb } | Select-Object -First 1
if ($pkg) { $caddy = $pkg.FullName }
if (-not $caddy) { $caddy = (Get-Command caddy -ErrorAction SilentlyContinue).Source }
if (-not $caddy -or -not (Test-Path $caddy)) {
    Write-Host "  caddy.exe が見つかりませんでした。" -ForegroundColor Red
    Write-Host "  先に  winget install CaddyServer.Caddy  を実行してください。" -ForegroundColor Yellow
    Read-Host "Enterで終了"; exit
}
Write-Host "  ✓ $caddy" -ForegroundColor Green

# ============================================================
#  2) 手動起動中の Caddy を停止（ポート443の衝突を防ぐ）
# ============================================================
Title "2) 手動起動中の Caddy を停止"
Quiet $caddy @('stop')
Start-Sleep -Seconds 2
Write-Host "  ✓ 手動の Caddy を停止しました（動いていなければ無視されます）" -ForegroundColor Green

# ============================================================
#  3) WinSW（サービス化ツール）をダウンロード
# ============================================================
Title "3) サービス化ツール(WinSW)を準備"
if (Test-Path $ServiceExe) {
    Quiet $ServiceExe @('stop'); Quiet $ServiceExe @('uninstall'); Start-Sleep -Seconds 2
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    Invoke-WebRequest -Uri $WinswUrl -OutFile $ServiceExe -UseBasicParsing
    Write-Host "  ✓ ダウンロード完了: $ServiceExe" -ForegroundColor Green
} catch {
    Write-Host "  ダウンロード失敗: $_" -ForegroundColor Red
    Write-Host "  手動で $WinswUrl を取得し、$ServiceExe として保存してください。" -ForegroundColor Yellow
    Read-Host "Enterで終了"; exit
}

# ============================================================
#  4) サービス設定ファイル(XML)を作成
# ============================================================
Title "4) サービス設定を作成"
$xml = @"
<service>
  <id>caddy</id>
  <name>Caddy Web Server (AppleStudio)</name>
  <description>applestudiogogo.com を公開する Caddy サーバー</description>
  <executable>$caddy</executable>
  <arguments>run</arguments>
  <workingdirectory>$SiteDir</workingdirectory>
  <startmode>Automatic</startmode>
  <onfailure action="restart" delay="10 sec"/>
  <log mode="roll-by-time">
    <pattern>yyyyMMdd</pattern>
  </log>
</service>
"@
Set-Content -Path $ServiceXml -Value $xml -Encoding UTF8
Write-Host "  ✓ $ServiceXml" -ForegroundColor Green

# ============================================================
#  5) サービスを登録して起動
# ============================================================
Title "5) サービスを登録して起動"
$ErrorActionPreference = 'Continue'   # WinSWの出力でエラー誤判定しないように
& $ServiceExe install
Start-Sleep -Seconds 2
& $ServiceExe start
Start-Sleep -Seconds 3
$ErrorActionPreference = 'Stop'

$svc = Get-Service -Name caddy -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Host "  ✓ サービス『caddy』が起動しました（状態: $($svc.Status)）" -ForegroundColor Green
} else {
    Write-Host "  サービスの状態: $($svc.Status)" -ForegroundColor Yellow
    Write-Host "  ログ: $SiteDir\caddy-service.*.log を確認してください。" -ForegroundColor Yellow
}

Title "完了"
Write-Host "これで以下が有効になりました:" -ForegroundColor Green
Write-Host "  ・PowerShellウィンドウを閉じてもサイトは動き続けます"
Write-Host "  ・PCを再起動しても自動でサイトが立ち上がります"
Write-Host ""
Write-Host "サービスの管理（管理者PowerShell）:"
Write-Host "  状態確認 : Get-Service caddy"
Write-Host "  停止     : Stop-Service caddy"
Write-Host "  開始     : Start-Service caddy"
Write-Host "  設定変更後の再起動 : Restart-Service caddy"
Write-Host ""
Write-Host "サービスを完全に削除したいとき:"
Write-Host "  このスクリプトを -Uninstall 付きで実行"
Write-Host ""
Write-Host "※ サービスは別アカウントで動くため、初回起動時に証明書を取得し直します（正常です）。"
Write-Host "  数十秒待って https://applestudiogogo.com/ が開けば成功です。"
Write-Host ""
Read-Host "Enterで終了"
