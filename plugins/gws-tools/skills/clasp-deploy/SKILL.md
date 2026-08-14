---
name: clasp-deploy
description: Apps Script のコードを手元からクラウドへ反映し、ウェブアプリとして公開する。「GAS を push して」「スクリプトを更新して」「ウェブアプリを再デプロイして」「Apps Script のコードを取ってきて」「デプロイをやり直したい」と言われたときに使う。clasp の導入と認証がまだなら clasp-setup が先である。Push and deploy Apps Script projects with clasp.
---

# Apps Script の反映とデプロイ

`clasp` で、手元のコードを Apps Script プロジェクトへ反映する。認証が済んでいることが前提である（`clasp show-authorized-user` で確認できる。未認証なら `clasp-setup` スキルへ誘導する）。

**デプロイは公開行為である。`create-deployment` と `update-deployment` を実行する前に、必ずユーザーの明示的な承認を得る。** 何が、どの公開範囲で、誰に見えるようになるのかを示してから尋ねる。

## プロジェクトの構成

Apps Script プロジェクト1つにつき、1つのフォルダを対応させる。

| ファイル | 役割 | git に入れるか |
|---|---|---|
| `.clasp.json` | どのスクリプトへ push するかを示す（`scriptId` を含む） | 入れない |
| `appsscript.json` | マニフェスト。実行環境・タイムゾーン・ウェブアプリ設定 | 入れる |
| `Code.js` など | スクリプト本体 | 入れる |
| `*.html` | HTML サービスで配る画面 | 入れる |

## 既存のプロジェクトを手元に持ってくる

```powershell
clasp clone-script <スクリプトID>
```

スクリプト ID は Apps Script エディタの URL の `/projects/` と `/edit` に挟まれた部分である。手元にあるコードを消してしまわないよう、**空のフォルダで実行する。**

一覧から探すこともできる。

```powershell
clasp list-scripts
```

## 反映する（push）

まず、何が送られるのかを確認する。

```powershell
clasp show-file-status
```

送る。

```powershell
clasp push --force
```

`--force` はリモートのマニフェストを上書きする指定である。`appsscript.json` を手元で変えたときは必要になる。**リモート側で誰かがエディタから直接編集していた場合、その変更は消える。** 共同で触っているプロジェクトでは、push の前に `clasp pull` で差分を確認する。

## デプロイする

ウェブアプリとして公開する場合の流れである。

**同じ URL を保ったまま更新する**（通常はこちら。既存の利用者のブックマークが生きる）:

```powershell
clasp create-deployment -i <既存のデプロイID> -d "更新の内容"
```

デプロイ ID がわからないときは一覧を見る。

```powershell
clasp list-deployments
```

**新しい URL で公開する**（初回のみ）:

```powershell
clasp create-deployment -d "初回公開"
```

**新しいデプロイを作るたびに URL が変わる。** 既存の利用者に配った URL を生かしたいなら、必ず `-i` で既存のデプロイ ID を指定する。

## 落とし穴

### create-script は appsscript.json を上書きする

`clasp create-script` は実行時に、リモートの既定マニフェストを**手元の `appsscript.json` へ上書きする**。これで `webapp` ブロックが消え、既定の設定のまま公開された事故が実際に起きている。

プロジェクトを作り直すときは、次の順で行う。

1. `clasp create-script --type standalone --title "<名前>" --rootDir .`
2. **`appsscript.json` を書き直す**（`webapp` ブロックなど、必要な設定を入れ直す）
3. `clasp push --force`

### ウェブアプリの公開範囲は3択しかない

`appsscript.json` の `webapp.access` に指定できるのは次の3つだけである。Drive のような「この人とこの人だけ」という名指しの許可リストは持てない。

| 値 | 誰が見られるか |
|---|---|
| `MYSELF` | 自分だけ |
| `ANYONE` | Google アカウントを持っていてログインしている人なら誰でも（**社外も含む**） |
| `ANYONE_ANONYMOUS` | ログインなしで誰でも |

`ANYONE` は「社内だけ」という意味ではない。**URL を知っている社外の人にも見える。** 社内限定にしたい資料をここで配ってはいけない。

`executeAs` は `USER_DEPLOYING`（デプロイした人の権限で動く）か `USER_ACCESSING`（見に来た人の権限で動く）を選ぶ。

```json
{
  "timeZone": "Asia/Tokyo",
  "runtimeVersion": "V8",
  "webapp": {
    "executeAs": "USER_DEPLOYING",
    "access": "MYSELF"
  }
}
```

### スプレッドシートに紐づくスクリプトは削除に注意

`clasp delete-script` はスクリプトを消す。コンテナ（スプレッドシートなど）に紐づいたスクリプトを消すと、そのシートのメニューや自動処理がすべて止まる。**実行前に必ず確認を取る。**

## つまずいたときの切り分け

| 症状 | 原因と対処 |
|---|---|
| `User has not enabled the Apps Script API` | [script.google.com/home/usersettings](https://script.google.com/home/usersettings) のトグルがオフ。`clasp-setup` のステップ2へ |
| `Could not read API credentials` | `clasp -A "$env:USERPROFILE\.clasprc.json" <コマンド>` で認証ファイルを明示する |
| push しても内容が変わらない | `.clasp.json` の `scriptId` が別のプロジェクトを指している。`clasp show-file-status` で送り先を確認する |
| デプロイしたのに古い画面が出る | 新しいデプロイを作ると URL が変わる。`-i` で既存のデプロイ ID を指定したか確認する |
| push で一部のファイルが送られない | `.claspignore` の指定を確認する。`clasp show-file-status` に出ないファイルは送られない |
