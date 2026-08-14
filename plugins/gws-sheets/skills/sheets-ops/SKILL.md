---
name: sheets-ops
description: Google スプレッドシートを読み書きする。セルの値を取得する・書き込む・追記する、シートの構造（タブ・フィルタビュー・入力規則・書式）を変更する、といった作業に使う。「スプレッドシートを見て」「シートに書き込んで」「台帳を更新して」「Google Sheets を編集」などの依頼で使用する。Read, write, and update Google Sheets via the gws CLI.
---

# Google スプレッドシートの読み書き

`gws`（Google Workspace CLI）で Sheets API を直接呼んで操作する。`gws` はこのプラグインに同梱されており、PATH に自動で追加されるので、インストールは不要である。

## 作業を始める前に必ずやること

**1. 対象表を読む。** 操作してよいスプレッドシートと、その権限は設定ファイルに書かれている。次の順で探し、最初に見つかったものを使う。

1. `%USERPROFILE%\.claude\gws-targets.json`
2. 作業中のフォルダの `.gws-targets.json`

このファイルが見つからないときは、勝手に ID を推測して操作してはいけない。ユーザーに「対象表が見つからない」と伝え、`gws-setup` スキルの手順で用意してもらう。

**2. 認証を確かめる。** 最初のコマンドが認証エラー（終了コード 2）になったら、`gws-setup` スキルの手順に誘導する。自分で認証を回そうとしない。

```bash
gws auth status
```

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

1. **書き込む前に、同じ範囲を `values get` で読む。** 今そこに何が入っているかを確認する
2. **何をどう変えるのかをユーザーに提示し、承認を得る。** 対象のスプレッドシート名・範囲・変更前後の値を示す。範囲が広いときは件数と代表例を示す
3. 承認を得てから書く
4. 書いたあと、同じ範囲を読み直して結果を報告する

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

- **対象表で `readonly: true` になっているスプレッドシートへの書き込み。** これらは客先の実物や凍結標本であり、書き込むと復旧できない。読み取りだけ行う
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

Git Bash が入っていれば、上の例をそのまま実行できる。PowerShell しかない環境では、JSON 内の二重引用符が壊れることがある。その場合は停止解析トークンを使い、JSON から空白を除いて渡す。

```powershell
gws --% sheets spreadsheets values get --params {"spreadsheetId":"<ID>","range":"台帳!A1:E10"}
```
