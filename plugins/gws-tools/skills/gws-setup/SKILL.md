---
name: gws-setup
description: gws（Google Workspace CLI）の導入と認証を案内する。「セットアップして」「gws を入れたい」「ログインできない」「認証が切れた」「対象表が読めない」「gws が見つからない」と言われたとき、またはスプレッドシート操作で認証エラーが出たときに使う。Apps Script 側の準備は clasp-setup が担当する。Install and authenticate the gws CLI on Windows.
---

# gws の導入と認証（利用者ひとりずつ）

このスキルは、ユーザーが `gws` を使える状態になるまでを案内する。

**ブラウザでの承認はユーザー本人が行う。代行しない。** クライアントシークレットやトークンの中身を表示・複製・送信してもいけない。

事前に、会社の管理者から次の2つを受け取っている必要がある。持っていなければ、管理者に問い合わせるよう案内する。**値を推測させたり、こちらで代わりに用意しようとしたりしない。**

- `client_secret.json`（OAuth クライアントのファイル）
- 対象表のスプレッドシート ID

## ステップ0: 現在地を確認する

```powershell
gws auth status
```

返ってくる JSON の読み方は次のとおりである。

| 出力 | 意味 | 次にやること |
|---|---|---|
| コマンドが見つからない | gws が未導入 | ステップ1へ |
| `client_config_exists: false` | クライアントのファイルが未配置 | ステップ2へ |
| `client_config_exists: true` かつ `token_cache_exists: false` | ファイルは置けたが未ログイン | ステップ3へ |
| `token_cache_exists: true` で `auth_method` と `storage` が埋まっている | 認証済み | ステップ4の動作確認へ |

`credential_source` は「どこからクライアント情報を読んだか」を示すだけで、ログイン済みかどうかは表さない。ファイルを置いた直後は `client_secret.json` になるが、まだログインは済んでいない。**ログインの有無は `token_cache_exists` と `auth_method` で判断する。**

## ステップ1: gws を入れる

**「見つからない」には2種類ある。まだ入っていない場合と、入っているのにこのセッションから見えていない場合である。** 先にどちらかを見分ける。順に試して、最初に成功したところで止める。

1. そのまま呼ぶ

```powershell
gws --version
```

2. 見つからないと言われたら、実体があるかを確かめる

```powershell
& "$env:APPDATA\npm\gws.ps1" --version
```

**ここでバージョンが出たなら、導入は済んでいて PATH が古いだけである。** 入れ直してはいけない。原因は、Claude Code（またはターミナル）を起動したあとに gws を入れたことである。Windows のプロセスは起動時の PATH を持ち続けるため、あとから入れたコマンドが見えない。

- 恒久的な対処: **Claude Code を再起動する**。それだけで直る
- 再起動せずに進めたい場合: このセッションの間だけ、**すべての `gws` を `& "$env:APPDATA\npm\gws.ps1"` に読み替えて実行する**。以降の手順もすべてこの読み替えで通る

3. 実体も無ければ、入っていない。Node.js が要るので、`node --version` が通らなければ先に [nodejs.org](https://nodejs.org/) の LTS 版を入れてもらう。

Node.js があるなら、入れてよいかをユーザーに一言確認してから実行する。

```powershell
npm install -g @googleworkspace/cli
```

入れた直後は、上と同じ理由でこのセッションからは `gws` の名前で呼べないことが多い。確認は実体のパスで行う。

```powershell
& "$env:APPDATA\npm\gws.ps1" --version
```

`gws 0.22.5` のようにバージョンが出れば成功である。**このあとの手順も、Claude Code を再起動するまでは実体のパスで呼ぶ。**

なお gws は Google が公開しているツールだが、正式サポート製品ではない旨を自ら表示する（`This is not an officially supported Google product.`）。仕様である。

## ステップ2: クライアントのファイルを置く

管理者から受け取った `client_secret.json` を、gws が読む場所へ置く。置き場所は `gws auth status` の `client_config` に表示されているパスである。Windows では次になる。

```
C:\Users\<ユーザー名>\.config\gws\client_secret.json
```

フォルダごと作る。

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\gws"
```

ダウンロードフォルダにある場合の例である。ファイル名が `client_secret_〇〇.apps.googleusercontent.com.json` のままなら、**`client_secret.json` に変えて**置く。

```powershell
Copy-Item "$env:USERPROFILE\Downloads\client_secret.json" "$env:USERPROFILE\.config\gws\client_secret.json"
```

置けたことを確かめる。`client_config_exists` が `true` になっていればよい（`credential_source` が `client_secret.json` に変わるが、ログインはまだである）。

```powershell
gws auth status
```

## ステップ3: 自分の Google アカウントで承認する

必要なサービスだけに絞ってログインする。

```powershell
gws auth login -s drive,sheets,docs
```

ブラウザが開くので、**会社の Google アカウント**（普段スプレッドシートを開いているアカウント）で承認する。個人の Gmail アカウントで承認すると、会社のスプレッドシートが見えない。

- **`-s` は必ず付ける。** 省くと既定のスコープ一覧が 85 個以上に膨らみ、承認画面がひどく長くなる
- Apps Script も扱うなら `-s drive,sheets,docs,script` にする
- `--full` は使わない。Cloud Platform や Pub/Sub まで要求してしまう

承認が終わると、トークンは Windows の資格情報マネージャー（キーリング）に保存される。以降は自動で更新されるので、再ログインは基本的に不要である。

## ステップ4: 動作確認

```powershell
gws drive files list --params '{"pageSize":1}'
```

ファイルが1件返れば、gws 自体は使える状態である。

続けて、操作してよいスプレッドシートの一覧（対象表）が読めるかを確かめる。

```powershell
gws sheets spreadsheets values get --params '{"spreadsheetId":"${user_config.registry_spreadsheet_id}","range":"対象表!A:D"}'
```

返ってきた一覧をユーザーに見せて、「この中から選んで指示してください」と伝える。以降の読み書きは `sheets-ops` スキルが担当する。

対象表のスプレッドシート ID が未設定の場合は、`/plugin` を開いて `gws-tools` の設定に入れてもらう。**未設定のままでは、スプレッドシートへの書き込みは一切行わない**（読み取りだけになる）。

## つまずいたときの切り分け

| 症状 | 原因と対処 |
|---|---|
| `gws` がコマンドとして見つからない | まずステップ1の手順2で実体を確かめる。実体があれば入れ直さず、Claude Code を再起動するか実体のパスで呼ぶ |
| `client_config_exists: false` のまま | 置き場所かファイル名の誤り。`gws auth status` の `client_config` が示すパスと1文字ずつ突き合わせる |
| ブラウザで「このアプリは確認されていません」 | 会社の内部アプリとして作られていない。管理者に「同意画面の対象が内部になっているか」を確認してもらう |
| ブラウザで「アクセスをブロック」「admin_policy_enforced」 | 組織のポリシーで弾かれている。管理者に、管理コンソールの API 制御でクライアント ID を信頼済みに登録してもらう |
| 承認したのに 403 が出る | ログインしたアカウントが違う。`gws auth status` を確認し、違えば `gws auth logout` してからやり直す |
| 対象表が 404 | ID が誤っているか、自分に共有されていない。管理者に確認する |
| 数日おきに認証が切れる | OAuth クライアントが「外部・テスト中」になっている疑いが濃い（外部だとリフレッシュトークンが7日で失効する）。管理者に内部アプリへの変更を依頼する |
