<#
============================================================
 AppleStudio 自宅サーバー セットアップスクリプト
 実行する内容:
   手順3) このPCのローカルIPを固定（DHCP→静的）
   手順4) ルーターに入力する値を表示（※設定自体はルーター側で行う）
   手順5) Windowsファイアウォールで 80/443 番を開放
------------------------------------------------------------
 使い方:
   1) このファイルを右クリック →「PowerShellで実行」
      もしくは PowerShell を「管理者として実行」して
        cd "E:\AppleStudioWebPages\AppleStudioWebPage"
        powershell -ExecutionPolicy Bypass -File .\setup-server.ps1
   2) 画面の案内に従う
 元に戻したいとき（IPをDHCPに戻す）:
        powershell -ExecutionPolicy Bypass -File .\setup-server.ps1 -Revert
============================================================
#>

param(
    [switch]$Revert
)

# ---------- 管理者権限へ自動昇格 ----------
$me = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "管理者権限で実行し直します..." -ForegroundColor Yellow
    $argList = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Revert) { $argList += " -Revert" }
    Start-Process powershell -Verb RunAs -ArgumentList $argList
    exit
}

$ErrorActionPreference = "Stop"

function Write-Title($t) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $t" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

# ---------- 利用中のネットワークアダプタを自動検出 ----------
# デフォルトゲートウェイ（インターネット側）を持つアダプタを特定する
$route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
         Sort-Object RouteMetric | Select-Object -First 1
if (-not $route) {
    Write-Host "インターネットに接続中のアダプタが見つかりませんでした。" -ForegroundColor Red
    Write-Host "ネット接続を確認してからもう一度実行してください。" -ForegroundColor Red
    Read-Host "Enterで終了"; exit
}
$ifIndex  = $route.ifIndex
$adapter  = Get-NetAdapter -InterfaceIndex $ifIndex
$ipObj    = Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 |
            Where-Object { $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1
$curIP    = $ipObj.IPAddress
$prefix   = $ipObj.PrefixLength
$gateway  = $route.NextHop
$dns      = (Get-DnsClientServerAddress -InterfaceIndex $ifIndex -AddressFamily IPv4).ServerAddresses

Write-Title "検出した現在のネットワーク設定"
Write-Host "  アダプタ名      : $($adapter.Name)"
Write-Host "  ローカルIP      : $curIP / $prefix"
Write-Host "  ゲートウェイ    : $gateway"
Write-Host "  DNSサーバー     : $($dns -join ', ')"

# ============================================================
#  -Revert : DHCPに戻して終了
# ============================================================
if ($Revert) {
    Write-Title "ネットワーク設定をDHCP（自動取得）に戻します"
    $ans = Read-Host "本当に戻しますか？ (y/n)"
    if ($ans -eq "y") {
        Remove-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
        Set-NetIPInterface -InterfaceIndex $ifIndex -Dhcp Enabled
        Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ResetServerAddresses
        Write-Host "DHCPに戻しました。" -ForegroundColor Green
    } else {
        Write-Host "中止しました。" -ForegroundColor Yellow
    }
    Read-Host "Enterで終了"; exit
}

# ============================================================
#  手順5) ファイアウォール開放（80 / 443 TCP 受信）
# ============================================================
Write-Title "手順5) ファイアウォールで 80 / 443 番を開放"
foreach ($p in 80,443) {
    $name = "AppleStudio Web (TCP $p)"
    Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    New-NetFirewallRule -DisplayName $name -Direction Inbound -Action Allow `
        -Protocol TCP -LocalPort $p -Profile Any | Out-Null
    Write-Host "  ✓ ポート $p を許可しました" -ForegroundColor Green
}

# ============================================================
#  手順3) ローカルIPを固定（静的化）
# ============================================================
Write-Title "手順3) ローカルIPを固定する"
Write-Host "現在の $curIP をそのまま静的IPとして固定します。"
Write-Host "（ルーターのポート開放先が変わらないようにするためです）"
Write-Host ""
Write-Host "※ より安全にするなら、ルーターのDHCP配布範囲の外のIPにするか、" -ForegroundColor DarkYellow
Write-Host "   ルーター側で『DHCP予約(固定割当)』を設定する方法もあります。" -ForegroundColor DarkYellow
Write-Host ""
$ans = Read-Host "現在のIP ($curIP) で固定しますか？ (y/n)"

if ($ans -eq "y") {
    try {
        Remove-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
        Set-NetIPInterface -InterfaceIndex $ifIndex -Dhcp Disabled
        New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $curIP `
            -PrefixLength $prefix -DefaultGateway $gateway | Out-Null
        if ($dns) {
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $dns
        }
        Write-Host "  ✓ ローカルIPを $curIP に固定しました" -ForegroundColor Green
    } catch {
        Write-Host "  固定に失敗しました: $_" -ForegroundColor Red
        Write-Host "  -Revert オプションでDHCPに戻せます。" -ForegroundColor Yellow
    }
} else {
    Write-Host "  固定はスキップしました。" -ForegroundColor Yellow
}

# ============================================================
#  手順4) ルーター設定に必要な情報を表示
# ============================================================
Write-Title "手順4) ルーターのポート開放（※ルーター側で設定してください）"
Write-Host "ルーターの管理画面（ポート開放 / ポートフォワーディング / NAT設定）で"
Write-Host "下記の内容を登録してください。Minecraftの25565を開けたのと同じ画面です。"
Write-Host ""
Write-Host "  転送先（このPC）のローカルIP : $curIP" -ForegroundColor White
Write-Host "  プロトコル                    : TCP" -ForegroundColor White
Write-Host "  開放するポート                : 80  と  443" -ForegroundColor White
Write-Host ""
Write-Host "  外部ポート / 内部ポート は両方とも同じ番号(80→80, 443→443)でOKです。"

# ---------- グローバルIPの確認 ----------
Write-Title "参考) 現在のグローバルIP（さくらのAレコードに設定する値）"
try {
    $gip = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 8)
    Write-Host "  グローバルIP : $gip" -ForegroundColor White
    Write-Host "  → さくらの『ゾーン編集』でAレコードをこのIPに設定してください。"
    Write-Host "    （回線によっては時々変わります。変わったら再設定 or DDNS導入）"
} catch {
    Write-Host "  取得に失敗しました。https://www.cman.jp/network/support/go_access.cgi で確認してください。" -ForegroundColor Yellow
}

Write-Title "完了"
Write-Host "次のステップ:" -ForegroundColor Green
Write-Host "  1) ルーターで上記ポート開放を登録"
Write-Host "  2) さくらでAレコードをグローバルIPに設定"
Write-Host "  3) Caddyfile のドメインを実際の名前に変更"
Write-Host "  4) このフォルダで  caddy run  を実行してサイト公開！"
Write-Host ""
Read-Host "Enterで終了"
