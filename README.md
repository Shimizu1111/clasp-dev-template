# Google Apps Script 開発テンプレート

このプロジェクトは、Google Apps Script (GAS) の開発環境テンプレートです。<br>
環境変数の管理や、ステージング・本番環境の分離など、実践的なGAS開発のための基盤を提供します。

## 前提条件

- Node.js
- [clasp](https://github.com/google/clasp) (Google Apps Script CLI)
- Google アカウント

## 環境構成

このテンプレートは以下の環境をサポートしています：

- `stg`: ステージング環境
- `prd`: 本番環境

## 初期設定

1. 環境変数ファイルの準備
```bash
# ステージング環境用
cp .env.prd\|stg.sample .env.stg
# 本番環境用
cp .env.prd\|stg.sample .env.prd
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
# ステージング環境へのデプロイ
make deploy GAS_ENV=stg

# 本番環境へのデプロイ
make deploy GAS_ENV=prd
```

## 主要なコマンド

- `clasp login`: Google Apps Scriptにログインします
- `make deploy GAS_ENV=[stg|prd]`: 指定した環境にプロジェクトをデプロイします
  - `init`: デプロイ環境用の設定ファイル（`.clasp.json`、`appsscript.json`）を準備
  - `build`: ソースコードをビルドし、環境変数のプレースホルダを置換
  - デプロイ前に確認プロンプトが表示されます
- `make clean`: ビルドファイルとclasp設定をクリーンアップします

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
