# AppleStudio サイトを GitHub で管理する手順

このフォルダ（サイト本体 + Caddy 設定）を GitHub に置き、**毎日 10:00 に自動で最新へ入れ替える**ための手順です。
作業は **このサーバー（Windows）上の PowerShell** で行います。

---

## 0. 事前準備（最初の一度だけ）

1. **Git for Windows** を入れる → https://git-scm.com/download/win
   （インストール後、PowerShell を一度開き直す）
2. **GitHub で空のリポジトリを作成**する
   - https://github.com/new を開く
   - リポジトリ名を入力（例: `applestudio-web`）
   - 公開/非公開はどちらでも可（下の「補足」参照）
   - **README・.gitignore・ライセンスは付けない**（空のまま）で「Create repository」
   - 作成後に表示される `https://github.com/ユーザー名/applestudio-web.git` を控える

---

## 1. GitHub へ初回アップロード

このフォルダで PowerShell を開いて実行（`<URL>` は手順0で控えたもの）:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup-github.ps1 -RepoUrl "https://github.com/ユーザー名/applestudio-web.git"
```

> 補足: 「デジタル署名されていません／実行できません」と出る場合は、上記のように
> `PowerShell -ExecutionPolicy Bypass -File .\スクリプト名` の形で実行してください
> （そのコマンドだけ許可する形で、システム設定は変えません）。
> 普通に `./setup-github.ps1 ...` と書くと Windows の初期設定でブロックされます。

- 認証ウィンドウが出たら GitHub アカウントでログイン
- 完了すると GitHub 上にファイル一式が並びます

---

## 2. 毎日 10:00 の自動更新を登録

**「管理者として実行」した PowerShell** で:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\register-deploy-task.ps1
```

- Windows タスク「AppleStudio-Deploy」が作られ、毎日 10:00 に GitHub から最新を取り込みます
- PC が消えていて時刻を逃しても、次に起動したとき実行されます
- すぐ試す: `Start-ScheduledTask -TaskName "AppleStudio-Deploy"`
- 実行結果は `deploy.log` に記録されます

---

## 普段の使い方

- サイトを直したいとき → **GitHub 側（または手元）でファイルを編集して push**
- サーバーは毎朝 10:00 に自動で GitHub の内容へ入れ替わります（差分が無ければ何もしません）
- Caddy は静的ファイルを自動で読み直すので、再起動は不要です

---

## 補足

- **公開 / 非公開**: このリポジトリにパスワードやトークンは含まれません（ドメイン名 `applestudiogogo.com` は公開情報）。
  非公開でも問題なく動きますが、その場合は Git の認証情報が PC に保存されている必要があります（初回 push 時に保存されます）。
- **管理対象外**（`.gitignore` で除外）: アクセスログ等の `*.log`、`caddy-service.exe`（インストーラで再取得可能）、未使用素材の `GroupIcon-anim.webm/.webp`。
- **deploy.ps1 の挙動**: サーバーは表示専用のため、ローカルの変更は破棄して GitHub に完全に合わせます（`git reset --hard origin/main`）。
  サーバー上で直接ファイルを書き換えても 10:00 に上書きされる点に注意してください（編集は GitHub 側で行う運用）。
