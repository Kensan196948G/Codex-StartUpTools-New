# 元リポジトリ棚卸し

対象:

- `D:\ClaudeCode-StartUpTools-New`

## 初期観察

- ドキュメント比重が高い
- 再利用可能なロジックは主に `scripts/lib` と `scripts/main` に集中している
- Claude 固有のテンプレートと指示文ツリーが大きい
- 既存テストがあるため、選択移植の判断材料として使いやすい

## 初期監査時の概数

- `node_modules` を除くファイル数: 約 382
- Markdown ファイル数: 263
- PowerShell ファイル数: 86
- 設定系ファイル数: 17

## 直近の重点項目

1. ルート文書を Codex 向けに対応付ける
2. `scripts/lib` を分類する
3. `tests` を分類する
4. `Claude/templates` から何を除外するか決める
