# bin ディレクトリ

ここに置いた実行ファイルは、プラグインが有効なセッションで自動的に PATH へ追加される。

配置するもの:

- `gws.exe` — Google Workspace CLI の Windows 版バイナリ

取得元は https://github.com/googleworkspace/cli/releases で、Windows 用（x86_64-pc-windows-msvc）のアーカイブを展開して `gws.exe` をこのディレクトリに置く。約 18MB ある。

macOS / Linux でも使えるようにする場合は、同じディレクトリに各プラットフォームのバイナリを置く。ただし本プラグインは Windows ネイティブ環境を主対象としている。

バージョンを上げたときは、リポジトリのルートにある README の動作確認手順を通してから公開すること。
