# gws-tools プラグイン

Claude Code から Google スプレッドシートを読み書きし、Apps Script を配置するためのプラグインである。Windows ネイティブ環境（WSL なし）を主対象とする。

会社で **OAuth クライアントを1つだけ**作り、それを全員で共有する設計になっている。管理者の作業は一度きりで、利用者が増えても追加の作業はいらない。

## 全体像

| 誰が | 何を | 頻度 |
|---|---|---|
| 管理者 | Cloud プロジェクトと OAuth クライアントを作り、`client_secret.json` と対象表シートを配る | 一度だけ |
| 利用者 | プラグインを入れ、CLI を入れ、自分のアカウントで承認する | ひとりにつき一度 |

## 管理者の準備

詳しい手順は [docs/admin-setup.md](docs/admin-setup.md) にある。Claude に「管理者側の準備をしたい」と言えば、`gws-admin-setup` スキルが同じ内容を対話で案内する。

要点は次の4つである。

1. 会社の**組織の下に** Cloud プロジェクトを作る（組織なしで作ると、次の「内部」が選べない）
2. Drive / Sheets / Docs / Apps Script / Service Usage の各 API を有効にする
3. 同意画面の対象を **内部（Internal）** にする
4. **デスクトップアプリ**の OAuth クライアントを作り、JSON を `client_secret.json` として利用者へ配る

**「内部」にすることが最も重要である。** 外部かつ「テスト中」のままだと、リフレッシュトークンが7日で失効して利用者が毎週ログインし直すことになり、テストユーザーは 100 人まで、承認画面には「確認されていないアプリ」の警告が出る。内部ならこれらがすべてなくなり、Google の審査も不要である。

## 利用者の導入

### 1. プラグインを入れる

Claude Code で次を実行する。

```
/plugin marketplace add https://github.com/HironosukeW/gws-tools-plugin.git
```

```
/plugin install gws-tools@gws-tools
```

**マーケットプレイスの指定は、`オーナー名/リポジトリ名` の短縮形ではなく `https://` で始まるフル URL を使う。** 短縮形は SSH 接続を試みるため、SSH 鍵を設定していないパソコンでは失敗する。

インストール時に設定画面が開くので、管理者から渡された**対象表のスプレッドシート ID** を貼り付ける。

### 2. セットアップする

Claude に「セットアップして」と伝える。`gws-setup` スキルが、CLI の導入から承認までを案内する。Apps Script も使うなら「clasp のセットアップもして」と続ける。

やることは3つだけである。

```powershell
npm install -g @googleworkspace/cli
```

管理者から受け取った `client_secret.json` を `C:\Users\<ユーザー名>\.config\gws\` に置く。

```powershell
gws auth login -s drive,sheets,docs
```

ブラウザが開くので、**会社の Google アカウント**で承認する。

以降は「台帳のA列を見せて」「この行を追記して」のように日本語で頼めば動く。

## 中身

| スキル | 役割 |
|---|---|
| `gws-admin-setup` | 管理者の準備（一度だけ） |
| `gws-setup` | gws の導入と認証 |
| `sheets-ops` | スプレッドシートの読み書き |
| `clasp-setup` | clasp の導入と認証 |
| `clasp-deploy` | Apps Script の反映とデプロイ |
| `windows-troubleshooting` | Windows 固有の詰まりどころ |

`plugins/gws-tools/config/registry-sheet-format.md` に、対象表シートの作り方がある。

## 事故を防ぐ仕組み

書き込んでよいスプレッドシートは、**対象表シート**（Google スプレッドシート1枚）で管理する。C 列が「はい」のものだけが書き込み対象で、それ以外は読み取り専用として扱う。対象表を直せば全員に反映されるので、プラグインを配り直す必要はない。

ただし、**対象表はスキルへの指示にすぎず、仕組みとしての防波堤ではない。** 読ませるだけの相手には、そのスプレッドシート自体の Drive 共有権限を閲覧者にすること。権限で止まっていれば、何が起きても書き込みは失敗する。

対象表のスプレッドシート ID が未設定の場合、スキルは書き込みを一切行わない（読み取りのみになる）。

## 公開リポジトリとして運用する

このリポジトリは**公開**で運用する。利用者のパソコンで Git の認証設定が不要になり、プラグインの自動更新も安定するためである。

秘密（クライアントシークレット）も会社固有の情報（対象シートの一覧）もリポジトリに入らない設計になっている。`client_secret.json` は管理者が社内の経路で配り、対象表は Google スプレッドシートに置く。

## 更新の配り方

このリポジトリに push すれば、利用者は次回起動時に更新を受け取る。すぐ反映させたい場合は利用者側で次を実行する。

```
/plugin marketplace update gws-tools
```

対象シートの追加・変更は対象表シートを直すだけでよく、リポジトリの更新は要らない。

## 開発時の動作確認

```bash
claude plugin validate ./plugins/gws-tools
```

```bash
claude --plugin-dir ./plugins/gws-tools
```

## 前提と断り

- 利用者それぞれに、Claude Code を実行できる Claude のプラン契約が必要である
- Node.js（LTS 版）が必要である
- `gws`（Google Workspace CLI）は Google が公開しているツールだが、正式サポート製品ではない旨を自ら表示する。このプラグインは gws を同梱せず、npm から導入する
