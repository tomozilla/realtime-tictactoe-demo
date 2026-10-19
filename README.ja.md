# realtime-tictactoe-demo

[English](README.md) | 日本語

> コードのコメントを日本語にしたもの（画面も日本語）は [`ja/`](ja/) にあります。本体（ルートの `index.html`、`app/`、`sql/` など）は英語です。ファイルのパスは英語版のものを指しています。

ブラウザのタブを複数開いて遊べる三目並べで、Supabase Realtimeの **Broadcast（出来事を全員に伝える）** と **Presence（今だれがいるか）** を試す、小さな学習用デモです。

> **個人の学習記録として作ったサンプルです。** 特定の会社の公式サンプルではなく、対戦ゲームの実装として十分なものでもありません。
> English summary: a single-file tic-tac-toe page to try Supabase Realtime Broadcast + Presence with several browser tabs, including a "late joiner asks for the current state" fix. Demo only: the channel is public and game rules are checked only in the browser.

この記事のコードです:
- 手順編: Qiita「Supabase Realtime入門：BroadcastとPresenceで、ゲームの状態や「今だれがいるか」を共有する」（ルートの `index.html`）
- アプリ編: Qiita「「みんなで同時に見る」ライブ注文ボードをつくってみた：誰が見ていて、誰が操作中かが分かる」（`app/` と `sql/app/`）

## 中身

| ファイル | 役割 |
|---|---|
| `index.html` | 三目並べ本体（HTMLとJavaScriptが1ファイル。supabase-jsはCDN（`esm.sh`）から読み込みます） |
| `config.example.js` | 設定のひな形。`config.js` という名前でコピーして使います（`config.js` は `.gitignore` 済み） |

## ライブ注文ボード（`app/`）

受付 / 調理中 / 完了の3列に注文カードが並び、誰かが動かすと全員の画面がすぐ変わる、小さな画面です。「いま見ている人」と「誰がどのカードを見ているか」も出ます（HTML 1枚、ビルド不要）。「いまの状態」はデータベースが持ち、Realtimeは変更の通知（Postgres Changes）と名簿（Presence）を運びます。

```bash
# 1. SQL Editorで sql/app/01_orders.sql を実行（テーブル・デモ用ポリシー・Realtimeの配信対象・サンプル4件）
cd app
cp config.example.js config.js     # URL と publishable キーを入れる（config.js は .gitignore 済み）
python3 -m http.server 8765 --bind 127.0.0.1
# http://127.0.0.1:8765/index.html?name=Alice  /  ?name=Bob  のように、タブごとに名前を変える
```

- 切れたら、画面を灰色にして「古い情報かもしれません」と出し、自動でつなぎ直して、データベースから全件を読み直します。`?debug=1` を付けると、`window.__rt.disconnect()` でわざと切断を試せます。
- 動作確認（2026年10月）: Alice・Bob・Carol（途中参加）の3タブで、更新の反映・追加・名簿・「見ています」の札・切断からの復帰を確かめました。BobのクリックからAliceの画面が変わるまでは、5回で369〜745ミリ秒でした（同じパソコン、データベースへの書き込みを含みます）。
- 費用: Freeは、Realtimeのメッセージ月200万・同時接続200（ドキュメントより）。メッセージの数え方の細かい規則は確かめていません。
- **セキュリティ（デモ用の構成です）**: ログインなしで、誰でも注文を読める・追加できる・更新できるポリシーです（`sql/app/01_orders.sql`）。本物のアプリでは、ログインした人だけにして、更新できる列・行を絞ってください。`updated_by` は画面が送る名前なので、なりすませます。
- 後片付け: `sql/app/99_cleanup.sql`。やり直しは `sql/app/02_reset_seed.sql`。

## 必要なもの

- Supabaseのプロジェクト（Freeプランのデモで確認しました）。**テーブルやSQLの準備は要りません**（Realtimeだけを使います）
- ブラウザ、`python3`（ローカルで配信するだけ）
- **publishable（anon）キー**: Project Settings → API Keys にあります。公開前提のキーですが、画像や記事には載せないでください。**service_role / secret キーは、絶対に入れないでください**

## 使い方

```bash
cp config.example.js config.js     # 開いて、URLとpublishableキーを入れる
python3 -m http.server 8765 --bind 127.0.0.1
```

ブラウザで、タブを複数開きます。

- `http://127.0.0.1:8765/index.html?name=Alice&mark=X`
- `http://127.0.0.1:8765/index.html?name=Bob&mark=O`
- `http://127.0.0.1:8765/index.html?name=Carol`（観戦）
- 途中から入るタブには `&resync=1` を付けると、入室時に「今の盤面を教えて」と放送します

AliceがマスをクリックするとBobの盤面にも出て、「オンライン◯人」の名簿が更新されます。`config.js` がないときは、画面に案内が出ます。

私は、クリーンなコピー（`config.js` だけ作った状態）で、Alice と Bob の2タブを開いて、入室の名簿と1手の反映を確認しました（2026年10月）。

## しくみ（要点）

- `supabase.channel('game-room-1')` に全員が入る
- 手を打つ → `room.send({ type: 'broadcast', event: 'move', ... })`
- 入退室 → `presence` の `sync` で名簿を更新
- Broadcastは**過去を覚えていません**。途中から入った人は盤面が空になるので、入室時に `state-request` を放送して、プレイヤーが `state` で今の盤面を返します

## 費用

ドキュメントの料金表（2026年10月時点）より:

| | Free | Pro |
|---|---|---|
| Realtimeのメッセージ数 | 月200万 | 500万まで含まれ、超えた分は100万ごとに2.5ドル |
| 同時接続（ピーク） | 200 | 500まで含まれ、超えた分は1000ごとに10ドル |

三目並べは、Freeの範囲で十分でした。**マウスの動きを全員に流す、のような使い方は、すぐ上限に近づくと思います**（私は試していません）。有料プランでの動きは未検証です。

## 注意（デモ用の構成です）

- **チャンネルが公開（誰でも入れる）設定です。** 仕組みを知っている人は、入室して偽のメッセージを送れます。「ログインした人だけ」の非公開チャンネルにする方法は、私は試していません。
- **勝敗の判定は、ブラウザ側だけです。** 不正な操作は止められません。お金やポイントが絡む場合は、サーバー側で判定してください。
- supabase-jsは `@2`（メジャーバージョン指定）で、CDNから読み込んでいます。本番では、バージョンを固定して自前で配信するほうが安全です。

## 確かめられていないこと

- 別の端末・別のネットワークからの接続（1台のパソコンのタブで確認しました）
- 人数が増えたときの速度や安定性
- 非公開チャンネルの設定

## ライセンス

MIT（`LICENSE` を参照）
