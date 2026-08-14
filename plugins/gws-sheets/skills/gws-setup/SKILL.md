---
name: gws-setup
description: gws の初回セットアップを案内する。Google スプレッドシート操作で認証エラーが出たとき、まだログインしていないとき、「セットアップしたい」「ログインできない」「認証が切れた」「対象表がない」と言われたときに使う。Set up gws authentication for Google Sheets access.
---

# 初回セットアップの案内

このスキルは、ユーザーが `gws` を使える状態になるまでを案内する。**認証の作業はユーザー本人がブラウザで行う。代行しない。** また、client_secret.json やトークンの中身を表示・複製・送信してはいけない。

## 進め方

現在地を確認してから、足りないステップだけ案内する。

```bash
gws auth status
```

- `user` にメールアドレスが出て `token_valid: true` なら、認証は完了している。ステップ3へ
- `client_config_exists: false` またはエラーが出たら、ステップ1から

## ステップ1: OAuth クライアントの設定ファイルを置く

会社の Google Workspace 管理者が作った `client_secret.json` を、共有された Google Drive のフォルダから各自ダウンロードして配置する。

置き場所は環境によって変わるが、覚える必要はない。次を実行すると、そのパソコンでの**正確な配置先パスがエラーメッセージに表示される**。

```bash
gws auth login
```

表示された `client_secret.json` のパスに、ダウンロードしたファイルをそのままの名前で置く。フォルダがなければ作る。

配置したら、ステップ2へ進む。

## ステップ2: 自分の Google アカウントでログインする

```bash
gws auth login
```

ブラウザが開くので、**会社の Google アカウント**（普段スプレッドシートを開いているアカウント）で承認する。個人の Gmail アカウントで承認すると、会社のスプレッドシートが見えない。

スコープの選択を求められたら、`spreadsheets` と `drive` を選ぶ。それ以外（Gmail・カレンダーなど）は不要なので選ばない。

承認後、次で `user` に自分のメールアドレスが出れば成功である。

```bash
gws auth status
```

## ステップ3: 対象表を用意する

操作してよいスプレッドシートの一覧を、次のどちらかの場所に `gws-targets.json` として置く。これも共有 Drive フォルダから配布されている。

1. `%USERPROFILE%\.claude\gws-targets.json`（推奨。どのフォルダで作業しても効く）
2. 作業するフォルダの `.gws-targets.json`

書式はプラグイン同梱の `config/gws-targets.example.json` を参照する。

## ステップ4: 動作確認

対象表に載っている読み取り可のシートを1つ選び、値が返ることを確かめる。

```bash
gws sheets spreadsheets values get --params '{"spreadsheetId":"<対象表のID>","range":"A1:C3"}'
```

値が返れば、セットアップは完了である。以降は `sheets-ops` スキルが使える。

## つまずいたときの切り分け

| 症状 | 原因と対処 |
|---|---|
| `No OAuth client configured` | ステップ1が未完了。表示されたパスに `client_secret.json` を置く |
| ブラウザで「このアプリは確認されていません」 | 会社の Workspace 内部アプリとして作られていない可能性がある。管理者に確認する |
| 承認したのに 403 が出る | ログインしたアカウントが違う。`gws auth status` の `user` を確認し、違えば `gws auth logout` してやり直す |
| しばらく使っていたら認証が切れた | 通常は再ログインで直る。**数日おきに切れる場合**は OAuth クライアントが「テスト中」の外部アプリになっている疑いがあるため、管理者に「内部アプリになっているか」を確認してもらう |
| 対象表が見つからない | ステップ3が未完了。配布元の Drive フォルダから取得する |
