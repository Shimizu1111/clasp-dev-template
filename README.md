# Google Apps Script 開発テンプレート

このプロジェクトは、Google Apps Script (GAS) の開発環境テンプレートです。<br>
以下のことができる実践的なGAS開発のための基盤を提供します。
- 環境変数の管理ステージング
- 本番環境の分離
- gasのバージョン管理

## 環境構成

このテンプレートは以下の環境をサポートしています：

- `dev`: 開発環境
- `stg`: ステージング環境
- `prd`: 本番環境

## 初期設定

1. 環境変数ファイルの準備
```bash
# 開発環境
cp .env.prd\|stg\|dev.sample .env.dev
# ステージング環境用
cp .env.prd\|stg\|dev.sample .env.stg
# 本番環境用
cp .env.prd\|stg\|dev.sample .env.prd
```

2. 環境変数の設定
各環境の`.env`ファイルを編集し、必要な環境変数を設定します：
- `SCRIPT_ID_STG`: ステージング環境のスクリプトID
- `SCRIPT_ID_PRD`: 本番環境のスクリプトID

スクリプトIDは[Google Apps Script](https://script.google.com/home)から取得できます。

3. Google Apps Scriptへのログイン
```bash
clasp login
```

## 開発方法

1. コードの編集
   - `src/`ディレクトリ内のファイルを編集します
   - 環境変数は`{{VARIABLE_NAME}}`の形式でプレースホルダとして記述できます
   - サポートされるファイル形式: `.js`、`.ts`、`.gs`

2. デプロイ
```bash
# バージョン名の詳細をつけてデプロイ
make deploy GAS_ENV=stg VERSION_DESC='リリース内容の詳細説明'

# バージョン名の詳細なしでデプロイ
make deploy-no-version GAS_ENV=stg
```

3. 対象のリリースバージョンとの差分を確認
```bash
make version-list GAS_ENV=stg
# version-listで確認したバージョンを比較
make diff GAS_ENV=stg VERSION_NUM_FROM=1 VERSION_NUM_TO=3
```

→GUIでは表示されないのでコマンドで確認する必要がある

## 主要なコマンド

- `clasp login`: Google Apps Script にログインします
- `make deploy GAS_ENV=[stg|prd] VERSION_DESC='説明文'`:  
  指定した環境に、説明付きバージョンを作成してデプロイします  
  - `init`: デプロイ環境用の設定ファイル（`.clasp.json`、`appsscript.json`）を準備  
  - `build`: ソースコードをビルドし、環境変数のプレースホルダを置換  
  - `deploy`: clasp push → version → deploy を実行  
  - 実行前に確認プロンプトが表示されます
- `make deploy-no-version GAS_ENV=[stg|prd]`:  
  バージョンを作成せず、clasp push → deploy だけを実行します（テスト用途に便利）
- `make diff VERSION_NUM_FROM=3 VERSION_NUM_TO=5`:  
  指定した2つのバージョン間のソースコードの差分を比較します（内部的に clasp pull）
- `make version-list GAS_ENV=[stg|prd]`:  
  `clasp versions` を実行し、現在のプロジェクトに登録されたバージョン履歴を一覧表示します
- `make clean`:  
  `build/` ディレクトリと `.clasp.json` を削除してクリーンアップします
- `make help`:  
  各 `make` コマンドの説明を表示します

## プロジェクト構造

```
.
├── src/              # ソースコードディレクトリ
│   └── main.js      # メインスクリプトファイル
├── build/           # ビルド出力ディレクトリ（自動生成）
│   ├── .clasp.json  # clasp設定ファイル（自動生成）
├── .env.stg         # ステージング環境の環境変数
├── .env.prd         # 本番環境の環境変数
├── .env.prd|stg.sample  # 環境変数のサンプル
├── appsscript.json  # GAS設定ファイル（自動生成）
└── Makefile         # デプロイなどの便利なコマンド
```

## ビルドプロセス

1. `init`: 指定された環境のGASプロジェクトから設定ファイルを取得
   - `build`ディレクトリの初期化
   - 環境に応じた`.clasp.json`の生成
   - `appsscript.json`の取得

2. `build`: ソースコードのビルド
   - `src`ディレクトリのファイルを`build`ディレクトリにコピー
   - 環境変数のプレースホルダを実際の値に置換
   - 対象ファイル: `.js`、`.ts`、`.gs`
