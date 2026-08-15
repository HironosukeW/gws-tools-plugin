---
name: account-switching
description: 会社用アカウントと個人用アカウントを切り替えて使えるようにする。「個人のドライブも触りたい」「会社と私用でアカウントを分けたい」「別のアカウントに切り替えたい」「今どのアカウントで動いているのか」「複数の Google アカウントを使い分けたい」と言われたときに使う。初回の導入そのものは gws-setup と clasp-setup が担当する。Switch between multiple Google accounts for gws and clasp.
---

# アカウントの使い分け

会社用と個人用など、複数の Google アカウントを切り替えて使える。ただし **gws と clasp では仕組みがまったく違う**ので、それぞれ別に切り替える必要がある。

| ツール | 切り替えの仕組み |
|---|---|
| gws | アカウント切り替えの機能を持たない。**設定ディレクトリごと**環境変数で差し替える |
| clasp | 名前付きユーザーを標準で持つ。`-u <名前>` で指定する |

## 先に知っておくこと: 個人用には別の OAuth クライアントが要る

会社の OAuth クライアントは「内部（Internal）」で作られているため、**その組織のアカウントでしか使えない。** 個人の Gmail アカウントで使おうとしても承認が通らない。

個人用に使うには、個人の Google アカウントで別途 Cloud プロジェクトと OAuth クライアントを作る必要がある。手順は `gws-admin-setup` スキルと同じだが、**個人アカウントには組織がないので「内部」を選べない。** 必然的に「外部」になり、次の制約が付く。

- 公開ステータスが「テスト中」のままだと、**ログインが7日で切れる**
- 「本番環境」に切り替えると7日失効はなくなるが、承認画面に「このアプリは確認されていません」の警告が出る（自分だけが使うぶんには、詳細を開いて進めば使える）

個人用を常用するなら「本番環境」に切り替えておくほうが楽である。

## gws を切り替える

`GOOGLE_WORKSPACE_CLI_CONFIG_DIR` で設定ディレクトリを差し替える。このディレクトリには、クライアントのファイルとトークンの保管場所の**両方**が入っているので、これ1つで identity がまるごと入れ替わる。

| 用途 | 設定ディレクトリ |
|---|---|
| 会社用（既定） | `C:\Users\<ユーザー名>\.config\gws` |
| 個人用 | `C:\Users\<ユーザー名>\.config\gws-private` |

### 個人用を用意する

フォルダを作り、個人用の `client_secret.json` を置く。

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\gws-private"
```

```powershell
Copy-Item "$env:USERPROFILE\Downloads\client_secret.json" "$env:USERPROFILE\.config\gws-private\client_secret.json"
```

個人用に切り替えてからログインする。

```powershell
$env:GOOGLE_WORKSPACE_CLI_CONFIG_DIR = "$env:USERPROFILE\.config\gws-private"
```

```powershell
gws auth login -s drive,sheets,docs
```

ブラウザでは**個人の Google アカウント**を選ぶ。

### 以降の切り替え

個人用にする:

```powershell
$env:GOOGLE_WORKSPACE_CLI_CONFIG_DIR = "$env:USERPROFILE\.config\gws-private"
```

会社用（既定）に戻す:

```powershell
$env:GOOGLE_WORKSPACE_CLI_CONFIG_DIR = $null
```

**この環境変数はセッション単位である。** Claude Code を開き直すと会社用（既定）に戻る。切り替えたつもりで会社側を触ってしまう事故を防ぐという意味では、この挙動はむしろ安全側である。

### 今どちらで動いているかを確かめる

作業の前に必ず確認する。**書き込みを伴う作業では、確認せずに実行しない。**

```powershell
gws auth status
```

`client_config` のパスを見る。`\.config\gws\` なら会社用、`\.config\gws-private\` なら個人用である。`config_client_id` の値でも見分けられる。

## clasp を切り替える

clasp は名前付きユーザーを標準で持つので、環境変数はいらない。認証情報は `%USERPROFILE%\.clasprc.json` に名前ごとに保存される。

個人用としてログインする:

```powershell
clasp login -u private --creds "$env:USERPROFILE\.config\gws-private\client_secret.json"
```

以降、個人用で動かすときは毎回 `-u private` を付ける。

```powershell
clasp -u private list-scripts
```

`-u` を省くと `default`（最初にログインしたほう）が使われる。**会社用を `default` にしておき、個人用だけ名前を付ける**のが間違いにくい。

今どのアカウントかを確かめる:

```powershell
clasp -u private show-authorized-user
```

## 切り替えを楽にする

PowerShell のプロファイルに次を書いておくと、1語で切り替えられる。プロファイルの場所は `$PROFILE` で分かる。

```powershell
function gws-private { $env:GOOGLE_WORKSPACE_CLI_CONFIG_DIR = "$env:USERPROFILE\.config\gws-private"; Write-Host "gws: 個人用に切り替えました" }
```

```powershell
function gws-work { $env:GOOGLE_WORKSPACE_CLI_CONFIG_DIR = $null; Write-Host "gws: 会社用（既定）に戻しました" }
```

## 事故を防ぐための約束

- **書き込みの前には必ず `gws auth status` を見て、どちらのアカウントで動いているかを確認する。** 確認せずに書き込まない
- 対象表シート（書き込み可否の一覧）は会社用のものである。個人用に切り替えている間は、対象表の判断はそのまま使えない。**個人用で会社のシートを触らない**
- gws と clasp は別々に切り替わる。片方だけ切り替えて、もう片方が会社用のまま動いている状態になりやすい
- 個人用と会社用で同じ `client_secret.json` を使い回さない。会社のクライアントは個人アカウントでは通らないし、逆をやると会社のデータを会社が把握していないクライアント経由で触ることになる

## つまずいたときの切り分け

| 症状 | 原因と対処 |
|---|---|
| 切り替えたのに前のアカウントのまま | `gws auth status` の `client_config` を見る。環境変数が別のセッションで設定されていた可能性がある |
| 個人用で「アクセスをブロックされました」 | 会社のクライアントを個人アカウントで使おうとしている。個人用の OAuth クライアントを別に作る |
| 個人用が数日おきに切れる | 個人用クライアントの公開ステータスが「テスト中」。Cloud Console で「本番環境」に切り替える |
| clasp で `-u` を付けたのに認証がないと言われる | その名前でまだログインしていない。`clasp login -u <名前> --creds <ファイル>` を実行する |
| 会社のシートが 404 になった | 個人用に切り替わったまま操作している。`gws auth status` で確認して戻す |
