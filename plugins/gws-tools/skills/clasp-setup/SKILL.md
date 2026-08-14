---
name: clasp-setup
description: clasp（Apps Script CLI）の導入と認証を案内する。「clasp を入れたい」「Apps Script をコマンドから触りたい」「GAS を push したい」「clasp login が通らない」「Apps Script API を有効にしたい」と言われたときに使う。実際の push とデプロイは clasp-deploy が担当し、スプレッドシート側の準備は gws-setup が担当する。Install and authenticate the clasp CLI on Windows.
---

# clasp の導入と認証（利用者ひとりずつ）

`clasp` は Apps Script のコードを手元とクラウドの間でやりとりする Google 公式のツールである。**gws と同じ `client_secret.json` をそのまま使える**ので、管理者に追加で何かを作ってもらう必要はない。

**ブラウザでの承認はユーザー本人が行う。代行しない。** トークンやクライアントシークレットの中身を表示・複製・送信してもいけない。

## ステップ0: 現在地を確認する

```powershell
clasp show-authorized-user
```

認証済みならアカウント情報が返る。コマンドが見つからなければステップ1、認証情報がないと言われればステップ2へ進む。

## ステップ1: clasp を入れる

```powershell
npm install -g @google/clasp
```

```powershell
clasp --version
```

`3.3.0` のようにバージョンが出れば成功である。コマンドが見つからない場合は `windows-troubleshooting` スキルの「gws や clasp が見つからない」を見る。

## ステップ2: Apps Script API を自分の設定でオンにする

**これは既定でオフになっている。飛ばすと、このあとの操作がすべて失敗する。**

ユーザーに [script.google.com/home/usersettings](https://script.google.com/home/usersettings) を開いてもらい、「Google Apps Script API」のトグルをオンにする。会社のアカウントで開くこと。

この設定は Cloud プロジェクト側の API 有効化とは別物である。**利用者ひとりずつが自分で行う必要がある。**

トグルが灰色で押せない場合は、組織の管理者が Apps Script を制限している。管理者に確認するよう案内する。

## ステップ3: 承認する

管理者から受け取った `client_secret.json` を使う。gws のセットアップ済みなら、同じファイルが `%USERPROFILE%\.config\gws\client_secret.json` に置いてある。

```powershell
clasp login --creds "$env:USERPROFILE\.config\gws\client_secret.json"
```

ブラウザが開くので、**会社の Google アカウント**で承認する。

- **`--creds` を付ける。** 付けずに `clasp login` だけを実行すると clasp 内蔵の共用クライアントが使われる。組織が未設定のサードパーティアプリをブロックしていると弾かれるうえ、会社が把握していないアプリに権限を渡すことになる
- `--creds` を使うと、必要な API（Apps Script API など）の有効化まで clasp が面倒を見る
- clasp のヘルプは `--creds` を「相対パス」と説明しているが、絶対パスでも動く。うまくいかないときは、そのファイルがあるフォルダへ移動してからファイル名だけで指定する

承認後、認証情報は `C:\Users\<ユーザー名>\.clasprc.json` に保存される。**このファイルは共有しない。** git 管理下に置かない。

## ステップ4: 動作確認

```powershell
clasp list-scripts
```

自分の Apps Script プロジェクトの一覧が返れば完了である。1つも作っていなければ、空の一覧が返るのが正常である。

以降の push とデプロイは `clasp-deploy` スキルが担当する。

## つまずいたときの切り分け

| 症状 | 原因と対処 |
|---|---|
| `clasp` がコマンドとして見つからない | PATH の問題。`windows-troubleshooting` スキルへ |
| `User has not enabled the Apps Script API` | ステップ2をやっていない。ユーザー設定のトグルをオンにする |
| `Could not read API credentials` | Windows 特有の癖。`clasp -A "$env:USERPROFILE\.clasprc.json" <コマンド>` のように認証ファイルを明示する |
| ブラウザで「アクセスをブロック」「admin_policy_enforced」 | 組織のポリシー。管理者にクライアント ID の信頼済み登録を依頼する |
| ブラウザで「このアプリは確認されていません」 | OAuth クライアントが内部アプリになっていない。管理者に確認する |
| 数日おきに認証が切れる | OAuth クライアントが「外部・テスト中」の疑い。管理者に内部アプリへの変更を依頼する |
