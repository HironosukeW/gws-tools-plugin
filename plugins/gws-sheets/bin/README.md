# bin ディレクトリ

ここに置いた実行ファイルは、プラグインが有効なセッションで自動的に PATH へ追加される。

| ファイル | 役割 | リポジトリに含まれるか |
|---|---|---|
| `gws` | ラッパー（Git Bash / macOS / Linux 用） | 含む |
| `gws.cmd` | ラッパー（PowerShell / コマンドプロンプト用） | 含む |
| `gws-bin.exe` | Google Workspace CLI の本体（Windows 版） | **要配置** |

## ラッパーの役割

利用者が `gws` と打つと、まずラッパーが動く。ラッパーはプラグイン設定に入力された OAuth クライアント情報（`CLAUDE_PLUGIN_OPTION_CLIENT_ID` / `CLAUDE_PLUGIN_OPTION_CLIENT_SECRET`）を、`gws` が読む環境変数（`GOOGLE_WORKSPACE_CLI_CLIENT_ID` / `GOOGLE_WORKSPACE_CLI_CLIENT_SECRET`）へ移し替えてから本体を呼ぶ。

これにより、利用者が `client_secret.json` をダウンロードして所定のパスへ置く作業がなくなる。設定が渡っているかどうかは、`gws auth status` の `credential_source` が `environment_variables` になっているかで判別できる。

## 本体の配置

https://github.com/googleworkspace/cli/releases から Windows 用（x86_64-pc-windows-msvc）のアーカイブを取得し、展開して出てくる実行ファイルを **`gws-bin.exe` という名前で**このディレクトリに置く。約 18MB ある。

`gws.exe` のままにしないこと。ラッパーと名前が衝突して、どちらが呼ばれるかが環境によって変わってしまう。

macOS / Linux でも使えるようにする場合は、同じディレクトリに拡張子なしの `gws-bin` として各プラットフォームのバイナリを置く。ラッパーは `gws-bin.exe` を先に探し、なければ `gws-bin` を使う。

本体のバージョンを上げたときは、リポジトリのルートにある README の動作確認手順を通してから公開すること。
