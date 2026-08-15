---
name: sheets-ops
description: Google スプレッドシートを読み書きする。セルの値を取得する・書き込む・追記する、シートの構造（タブ・フィルタビュー・入力規則・書式）を変更する、といった作業に使う。「スプレッドシートを見て」「シートに書き込んで」「台帳を更新して」「Google Sheets を編集」などの依頼で使用する。Read, write, and update Google Sheets via the gws CLI.
---

# Google スプレッドシートの読み書き

`gws`（Google Workspace CLI）で Sheets API を直接呼んで操作する。`gws` の導入と認証が済んでいることが前提である。`gws auth status` が認証済みを示さない場合は、自分で認証を回そうとせず `gws-setup` スキルの手順へ誘導する。

## 作業を始める前に必ずやること

**対象表を読む。** 操作してよいスプレッドシートは、次の対象表シートに列挙されている。作業の最初に必ず読み、対象とその書き込み可否を確認する。

```bash
gws sheets spreadsheets values get --params '{"spreadsheetId":"${user_config.registry_spreadsheet_id}","range":"対象表!A:D"}'
```

返ってくる表の見方は次のとおりである。

| 列 | 内容 |
|---|---|
| A | 名前（ユーザーとの会話ではこの名前で呼ぶ） |
| B | スプレッドシートID |
| C | 書き込み可。`はい` のときだけ書き込んでよい |
| D | 備考 |

**C列が `はい` 以外（`いいえ`・空欄・その他）のものは、読み取り専用として扱う。** 判断に迷ったら書き込まない。

対象表に載っていないスプレッドシートは操作しない。ユーザーが対象表にない ID を指定してきたら、対象表に見当たらないことを伝え、管理者に追加してもらうよう案内する。

対象表そのものが読めない場合（認証エラー・404）は、`gws-setup` スキルの手順へ誘導する。自分で認証を回そうとしない。

**対象表のスプレッドシート ID がプラグイン設定に入っていない場合は、書き込みを一切行わない。** 読み取りだけを行い、書き込みを頼まれたら「対象表が未設定なので書き込めない」と伝えて、`/plugin` から設定するよう案内する。対象表がなければ、どのシートが書き込み可なのかを判断する根拠がないためである。

## 読む

値の取得は `values get` を使う。**日付を含む範囲を読むときは必ず `UNFORMATTED_VALUE` を指定する**。

```bash
gws sheets spreadsheets values get --params '{"spreadsheetId":"<ID>","range":"台帳!A1:E10","valueRenderOption":"UNFORMATTED_VALUE"}'
```

タブの一覧と `sheetId`（gid）を調べるとき:

```bash
gws sheets spreadsheets get --params '{"spreadsheetId":"<ID>","fields":"sheets(properties(sheetId,title))"}'
```

## 書く

**書き込みは取り返しがつかない。次の順序を必ず守る。**

1. 複数のアカウントを使い分けている場合は、`gws auth status` で今どちらのアカウントで動いているかを確かめる（`account-switching` スキルを参照）
2. 対象表でそのスプレッドシートが**書き込み可**であることを確かめる
3. **書き込む前に、同じ範囲を `values get` で読む。** 今そこに何が入っているかを確認する
4. **何をどう変えるのかをユーザーに提示し、承認を得る。** スプレッドシート名・範囲・変更前後の値を示す。範囲が広いときは件数と代表例を示す
5. 承認を得てから書く
6. 書いたあと、同じ範囲を読み直して結果を報告する

範囲を指定して上書きする:

```bash
gws sheets spreadsheets values update --params '{"spreadsheetId":"<ID>","range":"台帳!F2:F5","valueInputOption":"RAW"}' --json '{"values":[["済"],["済"],["未"],["済"]]}'
```

表の末尾に行を追加する（既存行を壊さないので、追記で済むならこちらを優先する）:

```bash
gws sheets spreadsheets values append --params '{"spreadsheetId":"<ID>","range":"台帳!A:E","valueInputOption":"RAW","insertDataOption":"INSERT_ROWS"}' --json '{"values":[["A-00123","2026/08/14","AU","090-0000-0000","山田太郎"]]}'
```

### 書き込みの鉄則

- **`valueInputOption` は `RAW` を使う。** `USER_ENTERED` は入力値を Google が解釈するため、`=` で始まる文字列が数式になったり、電話番号の先頭 0 が消えたりする。意図して数式を書き込むときだけ `USER_ENTERED` にする
- **日付はシリアル値（数値）のまま扱う。** 読むときに `UNFORMATTED_VALUE` で取り、書くときもそのまま数値で戻す。途中で文字列に変換すると、そのシートの `COUNTIFS` や日付比較の数式がすべて壊れる
- **`values update` は指定した範囲だけを上書きする。** 範囲を実際のデータより短く指定すると、はみ出した古い行が残って混ざる。行数が変わる更新では、範囲の取り方を先に確認する
- **列を1つだけ更新するつもりで行全体の範囲を渡さない。** 空配列を渡した列が消える

## 構造を変える

タブの追加、フィルタビュー、入力規則（プルダウン）、書式、行列の挿入削除は `batchUpdate` で行う。

```bash
gws sheets spreadsheets batchUpdate --params '{"spreadsheetId":"<ID>"}' --json '{"requests":[{"addSheet":{"properties":{"title":"新しいタブ"}}}]}'
```

リクエストが複雑になるときは、JSON を手で書かずにスクリプトで組み立ててから渡す。**`deleteSheet`・`deleteDimension`・`deleteRange` は復旧できない。** 実行前に必ずユーザーの明示的な承認を取る。

## 絶対にやってはいけないこと

- **対象表で書き込み可になっていないスプレッドシートへの書き込み。** 客先の実物や、自動集計されるダッシュボードが含まれる
- **対象表に載っていない ID への操作。** ID を推測して叩かない
- **xlsx ファイルの再アップロードによるシート差し替え。** フィルタビュー・入力規則・タブ名など Sheets API 側の設定がすべて消える

## うまくいかないとき

| 症状 | 見るところ |
|---|---|
| 終了コード 2（認証エラー） | `gws auth status`。`gws-setup` スキルへ |
| 403 / 権限エラー | ログイン中のアカウントにそのシートが共有されているか。`gws auth status` の `user` を確認する |
| 404 | スプレッドシート ID かタブ名の誤り。`fields` 指定の `spreadsheets get` でタブ名を確認する |
| 日付が 45000 のような数字で返る | 正常。シリアル値なので、そのまま書き戻す。表示用に変換するのは報告時だけ |

## Windows でのコマンドの書き方

このプラグインは Windows ネイティブ環境（WSL なし）を主対象としている。上の例は PowerShell でそのまま実行できる。`--params` に渡す JSON は単一引用符でくくること。二重引用符でくくると、中の二重引用符が PowerShell に食われる。

複数のコマンドを1行につなげない。**PowerShell 5.1 は `&&` と `||` を解釈できない**ので、1行に1コマンドずつ実行する。

JSON が長くなるときは、いったん変数に入れてから渡すと崩れにくい。

```powershell
$body = '{"values":[["A-00123","AU","山田太郎"]]}'
```

```powershell
gws sheets spreadsheets values append --params '{"spreadsheetId":"<ID>","range":"台帳!A:C","valueInputOption":"RAW","insertDataOption":"INSERT_ROWS"}' --json $body
```

Git Bash が入っている環境なら、上の例をそのまま bash でも実行できる。
