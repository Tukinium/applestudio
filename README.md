# 🍎 アップルスタジオ / AppleStudio

VRChatグループ「アップルスタジオ（AppleStudio）」の公式Webページです。

## 内容
- グループ紹介・活動内容
- 告知・お知らせ
- メンバー紹介（全16名）
- イベント・スケジュール
- ギャラリー（写真）
- 公式YouTube・X・VRChatグループへのリンク

## 構成（複数ページ）
| ファイル | 役割 |
|----------|------|
| `index.html`   | ホーム（ヒーロー・紹介・直近イベント・公式リンク） |
| `news.html`    | 告知・お知らせ |
| `about.html`   | アバウト（活動内容の紹介） |
| `members.html` | メンバー紹介（全16名） |
| `events.html`  | イベント・スケジュール |
| `gallery.html` | ギャラリー（写真／クリックで拡大） |
| `style.css`    | 全ページ共通のデザイン（可愛い系・リンゴモチーフ） |
| `script.js`    | 全ページ共通の動き（ナビ開閉・スクロール表示・ライトボックス） |

すべてのページで同じナビゲーション・フッターを使っています。ページを増やすときは、
既存ページをコピーして中身を書き換え、各ページのナビ（`nav-links`）とフッター
（`footer-nav`）にリンクを1行ずつ足してください。

## 編集のしかた
- **メンバーを編集**：`members.html` の `member-card` を編集します。名前（`member-name`）と
  ひとこと（`member-role`）を書き換えます。数を増やす／減らすときはカードごとコピー／削除します。
  - 顔写真を使う場合は `<div class="avatar">🍎</div>` の中身を
    `<img src="images/名前.png" alt="名前" />` に差し替えます。
- **告知を編集**：`news.html` の `news-card` を編集・コピーします。日付（`news-date`）・
  タグ（`news-tag`／`event`・`important` クラスで色が変わります）・タイトル・本文を書き換えます。
- **イベントを編集**：`events.html`（とトップの抜粋）の `event-card` を編集します。
  `day`（日付）・`mon`（月や曜日）・イベント名・説明を書き換えます。
- **ギャラリーに写真を追加**：`gallery.html` の `gallery-item` を
  `<div class="gallery-item"><img src="images/photo1.jpg" alt="説明" /></div>` の形にします。
  写真は `images` フォルダを作ってそこに入れるのがおすすめです（クリックで拡大表示されます）。
- **紹介文を編集**：`about.html` のコメント `▼ ここに〜 ▼` の部分を書き換えます。
- **リンクを編集**：各ページの「公式リンク」内、YouTube・X・VRChatの `href` を差し替えます。

## ロゴについて
- 静止ロゴ：`images/logo.png`（ナビ・ファビコン・トップの初期表示に使用）
- ロゴアニメ：`images/logo-animation.webp`（透過アニメーションWebP。トップの訪問時とロゴクリック時に再生）
  - 元データ `AppleStudio Logo/Logo Animation GB.mp4` のグリーンバック(#13FF06)を
    ffmpeg の colorkey で透過し、512pxのアニメWebPに書き出したものです。
  - 作り直す場合の例（ffmpeg）：
    `ffmpeg -i "AppleStudio Logo/Logo Animation GB.mp4" -vf "fps=24,format=rgba,colorkey=0x13FF06:0.30:0.12,scale=512:512:flags=lanczos" -frames:v 148 -c:v libwebp_anim -pix_fmt yuva420p -q:v 50 -loop 1 -an images/logo-animation.webp`

## 公開・反映について
GitHub Pages で公開しています。
変更は **commit して GitHub に push** すると反映されます。
（サーバー側PCが毎日10時にリポジトリ一式をダウンロードして適用する運用です。）
