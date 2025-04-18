# ========== 設定 ==========
ifndef GAS_ENV
$(error ❌ GAS_ENV が未指定です。例: make deploy GAS_ENV=stg)
endif

ifneq ($(filter $(GAS_ENV), prd stg dev),$(GAS_ENV))
$(error ❌ GAS_ENV=$(GAS_ENV) は未定義の環境です。prd / stg / dev のいずれかを指定してください)
endif

ENV_FILE := .env.$(GAS_ENV)

ifneq ($(wildcard $(ENV_FILE)), $(ENV_FILE))
$(error ❌ $(ENV_FILE) が存在しません。環境変数ファイルが不足しています)
endif

# 環境変数の読み込み
include $(ENV_FILE)
export

# 環境変数ファイル
ENV_FILE := .env.$(GAS_ENV)

# 存在確認
ifneq ($(wildcard $(ENV_FILE)), $(ENV_FILE))
$(error ❌ $(ENV_FILE) が存在しません。)
endif

# 読み込み
include $(ENV_FILE)
export

# .env内のキー一覧を取得
ENV_VARS := $(shell awk -F= '/^[A-Z_][A-Z0-9_]*=.*/ { print $$1 }' $(ENV_FILE))

# # 各変数が未定義 or 空なら error を発行するように個別に評価
$(foreach var,$(ENV_VARS),\
  $(eval $(if $(value $(var)),,$(error ❌ $(var) が未定義または空です。全ての環境変数を埋めてください))))


.PHONY: init build deploy clean

init:
	@echo "🧹 build ディレクトリを初期化します"
	@rm -rf build && mkdir -p build
	@rm -f .clasp.json build/appsscript.json
	@echo "🛠️ $(GAS_ENV) 環境の clasp 設定ファイルを取得します"
	@mkdir -p tmp && cd tmp && clasp clone $(SCRIPT_ID)
	@cp tmp/.clasp.json .clasp.json
	@sed -i '' 's|"rootDir": *"[^"]*"|"rootDir": "build"|' .clasp.json
	@cp tmp/appsscript.json build/appsscript.json
	@rm -rf tmp
	@echo "✅ .clasp.json と appsscript.json を $(GAS_ENV) 環境用にコピーしました"

build:
	@echo "🔧 $(GAS_ENV) 環境のビルドを開始します"
	@cp -r src/* build/
	@echo "📦 .env ファイルからプレースホルダを置換中: $(ENV_FILE)"
	@cat $(ENV_FILE) | while read line; do \
		key=$$(echo $$line | cut -d= -f1); \
		value=$$(echo $$line | cut -d= -f2-); \
		find build -type f \( -name "*.js" -o -name "*.ts" -o -name "*.gs" \) \
			-exec sed -i '' "s|{{$${key}}}|$${value}|g" {} +; \
	done
	@echo "✅ ビルド完了"

deploy: init build
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ VERSION が未指定です。例: make deploy GAS_ENV=stg VERSION='stg用リリース'" >&2; \
		exit 1; \
	fi
	@echo "🚀 デプロイ先環境: $(GAS_ENV)"
	@read -p "$(GAS_ENV) 環境にデプロイしてもよろしいですか？ (y/n): " ans; \
	if [ "$$ans" = "y" ]; then \
		echo "📤 clasp push 実行中..." && \
		clasp push && \
		echo "📌 バージョン作成: $(VERSION)" && clasp version "$(VERSION)" && \
		clasp deploy; \
	else \
		echo "⚠️ デプロイをキャンセルしました。"; \
	fi

clean:
	@rm -rf build .clasp.json
	@echo "🧹 クリーン完了"
