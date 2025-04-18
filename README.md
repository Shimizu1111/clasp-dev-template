# Google Apps Script 開発テンプレート

このプロジェクトは、Google Apps Script (GAS) の開発環境テンプレートです

1. 環境変数の設定
```bash
cp .env.sample .env
```
`.env`ファイルを編集し、必要な環境変数を設定してください。

1. Google Apps Scriptへのログイン
```bash
clasp login
```

## 開発方法

1. コードの編集
   - `コード.js`ファイルにGASのコードを記述します。
   - 必要に応じて新しいファイルを作成することも可能です。

2. デプロイ
```bash
make deploy
```

## 主要なコマンド

- `clasp login`: Google Apps Scriptにログインします
- `make init`: プロジェクトを初期化します(自動で実行されるため手動実行は不要)
- `make deploy`: プロジェクトをデプロイします

## 注意事項

- デプロイ前に必ず`clasp login`を実行してください
