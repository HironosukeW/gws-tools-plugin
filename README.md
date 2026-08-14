# gws-sheets プラグイン

Claude Code から Google スプレッドシートを読み書きするためのプラグインである。Windows ネイティブ環境（WSL なし）を主対象とし、必要な CLI（`gws`）を同梱しているのでインストール作業がいらない。

利用者がやることは**2つだけ**である。ファイルのダウンロードも配置も要らない。

## 利用者の導入手順

### 1. プラグインを入れる

Claude Code を起動して、次の2つを実行する。

```
/plugin marketplace add https://github.com/<オーナー>/gws-sheets-plugin.git
```

```
/plugin install gws-sheets@gws-tools
```

インストール時に設定画面が開くので、管理者から渡された3つの値を貼り付ける。

| 設定項目 | 何を入れるか |
|---|---|
| OAuth クライアント ID | 末尾が `.apps.googleusercontent.com` の文字列 |
| OAuth クライアントシークレット | 伏せ字で入力される。安全な保管領域に保存される |
| 対象表のスプレッドシート ID | 操作してよいシートの一覧が書かれたシートの ID |

**マーケットプレイスの URL は `オーナー名/リポジトリ名` の短縮形ではなく、上のように `https://` で始まるフル URL を使う。** 短縮形は SSH 接続を試みるため、SSH 鍵を設定していないパソコンでは失敗する。

### 2. 自分の Google アカウントで承認する

Claude に「セットアップして」と伝えると `gws-setup` スキルが案内する。ブラウザが開くので、**普段スプレッドシートを開いている会社のアカウント**で承認する。

これで完了である。以降は「台帳のA列を見せて」「この行を追記して」のように日本語で頼めば動く。

## 配布側（管理者）の準備

### 1. OAuth クライアントを作る

会社の Google Workspace の GCP プロジェクトで、OAuth クライアントを1つ作る。

- 種類: **デスクトップアプリ**
- ユーザーの種類: **内部（Internal）**
- スコープ: `https://www.googleapis.com/auth/spreadsheets` と `https://www.googleapis.com/auth/drive` のみ

「内部」にすることが重要である。外部ユーザー種別かつ「テスト中」のままだと、リフレッシュトークンが7日で失効し、利用者が毎週ログインし直すことになる。内部アプリならこの制限がなく、テストユーザーの登録も Google の審査も不要である。

作成後に表示されるクライアント ID とクライアントシークレットを控える。**このリポジトリには置かない。** 利用者へは、プラグイン設定に貼り付けてもらう値として渡す。

### 2. 対象表シートを作る

操作してよいスプレッドシートの一覧を、Google スプレッドシート1枚で管理する。作り方は `plugins/gws-sheets/config/registry-sheet-format.md` を参照する。

このシートを直せば全員に反映されるので、対象の追加や書き込み可否の変更でプラグインを配り直す必要はない。利用者には**閲覧者**として共有する。

書き込ませたくないシートは、対象表で「いいえ」にするだけでなく、**そのシート自体の Drive 共有権限も閲覧者にする**こと。対象表の記述はスキルへの指示にすぎないが、Drive の権限は仕組みとして書き込みを止める。事故を防ぐのは後者である。

### 3. バイナリを入れる

`plugins/gws-sheets/bin/` に `gws-bin.exe` を配置する。手順は同ディレクトリの README を参照する。

### 4. 公開する

このリポジトリは**公開リポジトリ**として運用する。利用者のパソコンで Git の認証設定が不要になり、プラグインの自動更新も安定するためである。秘密（クライアントシークレット）も会社固有の情報（対象シートの一覧）もリポジトリに入らない設計なので、公開して差し支えない。

### 5. 動作確認

公開前に、手元で読み込んで確かめる。

```bash
claude --plugin-dir ./plugins/gws-sheets
```

```bash
claude plugin validate ./plugins/gws-sheets
```

## 更新の配り方

このリポジトリに push すれば、利用者は次回起動時に更新を受け取る。すぐ反映させたい場合は利用者側で次を実行する。

```
/plugin marketplace update gws-tools
```

対象シートの追加・変更は対象表シートを直すだけでよく、リポジトリの更新は要らない。

## 中身

| パス | 役割 |
|---|---|
| `plugins/gws-sheets/skills/sheets-ops/` | 読み書きの手順と事故防止の作法 |
| `plugins/gws-sheets/skills/gws-setup/` | 初回セットアップの案内 |
| `plugins/gws-sheets/bin/` | `gws` ラッパーと同梱バイナリ（PATH に自動追加される） |
| `plugins/gws-sheets/config/` | 対象表シートの作り方 |

## 仕組み

プラグイン設定に入力された値は、`CLAUDE_PLUGIN_OPTION_*` という環境変数として各コンポーネントに渡る。`bin/gws` ラッパーがこれを `gws` の読む `GOOGLE_WORKSPACE_CLI_*` へ移し替えてから本体を呼ぶため、利用者が `client_secret.json` を配置する必要がない。

渡っているかどうかは `gws auth status` の `credential_source` で判別できる。`environment_variables` なら成功、`none` なら設定が未入力である。

## 前提

利用者それぞれに、Claude Code を実行できる Claude のプラン契約が必要である。
