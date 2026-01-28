# 人生カレンダー (JINSEI Calendar)

人生でやりたいこと・行きたい場所を管理し、カレンダーで期限を可視化するiOSアプリです。

## 機能

### 1. やりたいことリスト

人生の目標をTODOリストとして管理します。

- 目標の追加・削除・完了チェック
- カテゴリ分類（キャリア、健康、趣味、旅行、学び、人間関係、お金、その他）
- 期限の設定（期限超過は赤色で警告表示）
- 完了済み項目の表示/非表示フィルター

### 2. 行きたい場所リスト

訪れたい場所をリストで管理し、地図と連携して確認できます。

- **MapKit検索**: 場所の名前を入力すると候補をリアルタイム検索
- **ミニマップ表示**: リスト上で各場所の位置をマップで確認
- **Google Maps連携**: ワンタップでGoogle Mapsアプリまたはブラウザで場所を表示
  - Google Mapsアプリがインストールされている場合はアプリで開く
  - インストールされていない場合はブラウザで開く
- 訪問済みチェック
- 目標日の設定

### 3. カレンダー

目標の期限や訪問予定を月表示カレンダーで一覧できます。

- 月単位のカレンダー表示（左右ナビゲーション）
- 予定がある日にはカラードットを表示
  - オレンジ: やりたいことの期限
  - ブルー: 行きたい場所の訪問予定
- 日付タップで詳細イベント一覧を表示
- 完了済みイベントはグレー表示＋チェックマーク

## 技術構成

| 項目 | 内容 |
|---|---|
| UI フレームワーク | SwiftUI |
| データ永続化 | SwiftData |
| 地図 | MapKit |
| 外部連携 | Google Maps (URLスキーム / Web URL) |
| 対応OS | iOS 17.0+ |
| 対応デバイス | iPhone / iPad |
| 言語 | Swift 5 |

## プロジェクト構成

```
JINSEIcalendar/
├── JINSEIcalendarApp.swift          # アプリエントリポイント（SwiftData設定）
├── Info.plist                       # Google Maps URLスキーム許可
├── Models/
│   ├── LifeGoal.swift               # やりたいことデータモデル
│   └── PlaceToVisit.swift           # 行きたい場所データモデル（Maps URL生成）
├── Views/
│   ├── MainTabView.swift            # 3タブナビゲーション
│   ├── LifeGoalListView.swift       # やりたいことリスト＋追加画面
│   ├── PlaceListView.swift          # 行きたい場所リスト＋追加画面＋ミニマップ
│   └── CalendarView.swift           # カレンダー表示＋イベント一覧
├── Assets.xcassets/
└── Preview Content/
```

## セットアップ

1. Xcode 15以降でプロジェクトを開く
2. Signing & Capabilities で開発チームを設定
3. ビルド・実行（シミュレータまたは実機）

外部ライブラリの依存はありません。Apple標準フレームワークのみで動作します。

## Google Maps連携について

- Google Mapsアプリがインストールされている端末では、場所の「地図」ボタンをタップするとGoogle Mapsアプリが直接開きます
- インストールされていない場合は、SafariでGoogle Mapsのウェブ版が開きます
- `Info.plist` に `LSApplicationQueriesSchemes` として `comgooglemaps` を登録しています
