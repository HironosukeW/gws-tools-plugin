---
name: windows-troubleshooting
description: Windows で gws や clasp が動かないときの原因を切り分ける。「コマンドが見つからない」「npm が変」「PATH が通らない」「認証情報が読めない」「WSL では動くのに Windows で動かない」「JSON の引用符でエラーになる」と言われたときに使う。認証そのものの手順は gws-setup と clasp-setup が担当する。Diagnose gws and clasp failures specific to Windows.
---

# Windows で動かないときの切り分け

このプラグインは Windows ネイティブ環境（WSL なし）を主対象としている。ここでは、Windows でだけ起きる詰まり方をまとめる。認証の手順そのものは `gws-setup` と `clasp-setup` にある。

## gws や clasp が見つからない

**最も多い原因は PATH の設定漏れではなく、起動順である。** Claude Code やターミナルを起動したあとにコマンドを入れると、そのプロセスは起動時の PATH を持ち続けるため、あとから入れたコマンドが見えない。**入れ直しても直らない。**

最初に、入っているかどうかを実体のパスで確かめる。

```powershell
& "$env:APPDATA\npm\gws.ps1" --version
```

```powershell
& "$env:APPDATA\npm\clasp.ps1" --version
```

**ここでバージョンが出たなら、導入は成功していて、見えていないだけである。**

- 直し方: **Claude Code を再起動する。** ターミナルだけの問題なら、そのターミナルを閉じて開き直す
- 再起動せずに進めたいなら、そのセッションの間は上の書き方（実体のパス）で呼ぶ

実体も無い場合だけ、本当に入っていない。`npm install -g @googleworkspace/cli` または `npm install -g @google/clasp` で入れる。

## PATH そのものが通っていないとき

上の実体パスでも見つからず、導入もしたはずなのに動かない場合は、置き場所を確かめる。

```powershell
npm prefix -g
```

そのフォルダの中身を見る。`gws.cmd` や `clasp.cmd` があれば、導入自体は成功している。

```powershell
Get-ChildItem (npm prefix -g) -Name
```

PATH に載っているかを確かめる。

```powershell
$env:Path -split ';' | Select-String 'npm'
```

載っていなければ、そのセッションだけ通して動作を確認する。

```powershell
$env:Path = "$env:APPDATA\npm;$env:Path"
```

これで動くなら原因は PATH である。恒久的に直すには、Windows の「システム環境変数の編集」→「環境変数」→ ユーザーの `Path` に `%APPDATA%\npm` を追加し、**Claude Code を再起動する**。

## npm ls -g が ENOENT で落ちる

```
ENOENT: no such file or directory, lstat 'C:\Users\<名前>\AppData\Roaming\npm'
```

グローバル用のフォルダがまだ作られていないだけである。異常ではない。何か1つグローバルに入れれば自然に解消する。

```powershell
npm install -g @googleworkspace/cli
```

## Node.js が入っていない

`npm` 自体が見つからない場合は、[nodejs.org](https://nodejs.org/) の LTS 版を入れる。入れたあとは Claude Code を再起動する。

```powershell
node --version
```

```powershell
npm --version
```

## 認証情報の置き場所

gws と clasp は別々の場所に認証情報を持つ。片方が通っていても、もう片方は別に認証が要る。

| ツール | 何が | どこに |
|---|---|---|
| gws | OAuth クライアント | `C:\Users\<名前>\.config\gws\client_secret.json` |
| gws | トークン | Windows の資格情報マネージャー（キーリング） |
| clasp | トークン | `C:\Users\<名前>\.clasprc.json` |

gws の実際のパスは、次のコマンドの `client_config` に出る。推測せず、これを見る。

```powershell
gws auth status
```

`keyring_backend` が `keyring` なら資格情報マネージャーを使っている。使えない環境では `.config\gws\.encryption_key` によるファイル方式へ自動的に切り替わる。どちらでも動作に違いはない。

## clasp が「Could not read API credentials」と言う

`clasp login` は済んでいるのに、別のコマンドで認証情報が見つからないと言われることがある。Windows で起きやすい。認証ファイルを明示的に渡すと通る。

```powershell
clasp -A "$env:USERPROFILE\.clasprc.json" list-scripts
```

毎回付けるのが面倒なら、環境変数でも指定できる。

```powershell
$env:clasp_config_auth = "$env:USERPROFILE\.clasprc.json"
```

## 作業フォルダがネットワークパスのとき（`\\wsl.localhost` など）

Windows から WSL のファイルを直接編集していると、作業フォルダが `\\wsl.localhost\ubuntu\home\...` のようなネットワークパス（UNC パス）になる。**この状態では `.cmd` で終わる実行ファイルが正しく動かない。** CMD.EXE はネットワークパスを作業フォルダにできず、警告を出して Windows フォルダへ移動してしまうため、出力が混ざったり失敗したりする。

```
CMD.EXE was started with the above path as the current directory.
UNC paths are not supported.  Defaulting to Windows directory.
```

npm で入れたコマンドは `.cmd` と `.ps1` の両方が用意されている。**PowerShell では `.ps1` のほうを使う。** こちらは CMD.EXE を通さないので、ネットワークパスでも問題なく動く。

```powershell
& "$env:APPDATA\npm\gws.ps1" --version
```

`gws` と名前だけで呼んだ場合、PowerShell は `.ps1` を優先するので通常は問題にならない。**問題になるのは、実体のパスを明示するときに `.cmd` を選んだ場合である。**

それでも動かないときは、実バイナリを直接呼ぶ。

```powershell
& "$env:APPDATA\npm\node_modules\@googleworkspace\cli\bin\gws.exe" --version
```

## WSL では動くのに Windows で動かない

**WSL と Windows は別の環境である。** 認証情報もインストール済みのコマンドも共有されない。

- WSL 側の `~/.config/gws/` と Windows 側の `C:\Users\<名前>\.config\gws\` は別のフォルダである
- WSL 側に入れた Linux 用のバイナリは Windows では動かない
- 両方で使いたい場合は、両方でそれぞれ導入と認証を行う。`client_secret.json` は同じものを両方に置いてよい

## JSON の引用符でエラーになる

PowerShell では、`--params` に渡す JSON を**単一引用符**でくくる。二重引用符でくくると、中の二重引用符が PowerShell に食われて壊れる。

```powershell
gws sheets spreadsheets values get --params '{"spreadsheetId":"<ID>","range":"台帳!A1:C5"}'
```

それでも壊れる場合は、停止解析トークン `--%` を使い、JSON から空白を取り除いて渡す。

```powershell
gws --% sheets spreadsheets values get --params {"spreadsheetId":"<ID>","range":"台帳!A1:C5"}
```

## コマンドを1行につなげられない

**PowerShell 5.1 は `&&` と `||` を解釈できない**（構文エラーになる）。1行に1コマンドずつ実行する。どうしても続けたいときは `;` で区切るか、`if ($?) { ... }` を使う。

## 文字化けする

日本語のタブ名やセルの値が化ける場合は、コンソールの文字コードを UTF-8 にする。

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

ファイルへ書き出すときは、エンコーディングを明示する。`Set-Content` と `Add-Content` は既定でシステムのコードページを使うため、`-Encoding utf8` を付けないと他のツールが読めないファイルができる。

## それでも直らないとき

次の3つをまとめてユーザーに出してもらうと、原因の切り分けが速い。**トークンやクライアントシークレットの中身そのものは出させない。**

```powershell
node --version; npm --version; npm prefix -g
```

```powershell
gws --version; gws auth status
```

```powershell
clasp --version; clasp show-authorized-user
```
