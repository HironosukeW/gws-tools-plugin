# gws-sheets プラグイン

Claude Code から Google スプレッドシートを読み書きするためのプラグインである。Windows ネイティブ環境（WSL なし）を主対象とし、必要な CLI（`gws`）を同梱しているのでインストール作業がいらない。

## 利用者の導入手順

Claude Code を起動して、次の2つを実行する。

```
/plugin marketplace add https://github.com/<オーナー>/gws-sheets-plugin.git
```

```
/plugin install gws-sheets@gws-tools
```

**URL は `オーナー名/リポジトリ名` の短縮形ではなく、上のように `https://` で始まるフル URL を使う。** 短縮形は SSH 接続を試みるため、SSH 鍵を設定していないパソコンでは失敗する。

インストール後、Claude に「セットアップして」と伝えると、`gws-setup` スキルが認証の手順を案内する。所要はおおむね5分で、やることは次の3つである。

1. 共有された Google Drive フォルダから `client_secret.json` をダウンロードして所定の場所に置く
2. `gws auth login` で自分の会社アカウントを承認する
3. 同じ Drive フォルダから `gws-targets.json`（操作してよいシートの一覧）を取得して置く

以降は「台帳のA列を見せて」「この行を追記して」のように日本語で頼めば動く。

## 配布側（管理者）の準備

### 1. OAuth クライアントを作る

会社の Google Workspace の GCP プロジェクトで、OAuth クライアントを1つ作る。

- 種類: **デスクトップアプリ**
- ユーザーの種類: **内部（Internal）**
- スコープ: `https://www.googleapis.com/auth/spreadsheets` と `https://www.googleapis.com/auth/drive` のみ

「内部」にすることが重要である。外部ユーザー種別かつ「テスト中」のままだと、リフレッシュトークンが7日で失効し、利用者が毎週ログインし直すことになる。内部アプリならこの制限がなく、テストユーザーの登録も Google の審査も不要である。

ダウンロードした `client_secret.json` は、**このリポジトリには置かない**。利用者だけに限定共有した Drive フォルダへ入れる。

### 2. 対象表を作る

`plugins/gws-sheets/config/gws-targets.example.json` を雛形として、実際のスプレッドシート ID を入れた `gws-targets.json` を作り、同じ Drive フォルダへ置く。

書き込ませたくないシートは必ず `"readonly": true` にする。あわせて、**Drive 側の共有権限も閲覧者にしておく**こと。設定ファイルの記述はスキルへの指示にすぎないが、Drive の権限は仕組みとして書き込みを止める。事故を防ぐのは後者である。

### 3. バイナリを入れる

`plugins/gws-sheets/bin/` に `gws.exe` を配置する。手順は同ディレクトリの README を参照する。

### 4. 公開する

このリポジトリは**公開リポジトリ**として運用する。利用者のパソコンで Git の認証設定が不要になり、プラグインの自動更新も安定するためである。秘密（`client_secret.json`）と会社固有の情報（`gws-targets.json`）はリポジトリに入れず Drive で配るので、公開して差し支えない。`.gitignore` でこれらを除外してある。

## 更新の配り方

このリポジトリに push すれば、利用者は次回起動時に更新を受け取る。すぐ反映させたい場合は利用者側で次を実行する。

```
/plugin marketplace update gws-tools
```

## 中身

| パス | 役割 |
|---|---|
| `plugins/gws-sheets/skills/sheets-ops/` | 読み書きの手順と事故防止の作法 |
| `plugins/gws-sheets/skills/gws-setup/` | 初回セットアップの案内 |
| `plugins/gws-sheets/bin/` | 同梱する `gws.exe`（PATH に自動追加される） |
| `plugins/gws-sheets/config/` | 対象表の雛形 |

## 前提

利用者それぞれに、Claude Code を実行できる Claude のプラン契約が必要である。
