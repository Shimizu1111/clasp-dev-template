# ========== 設定 ==========
# 全てのチェックをスキップするかどうか
ifeq ($(filter help clean version-list,$(MAKECMDGOALS)),)

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
endif

.PHONY: help init build deploy deploy-no-version diff version-list clean

help:
	@echo ""
	@echo "🛠️  利用可能な make コマンド一覧:"
	@echo ""
	@echo "  make init GAS_ENV=xxx                     - build ディレクトリと clasp 設定を初期化"
	@echo "  make build GAS_ENV=xxx                    - src を build にコピーし、env を埋め込み"
	@echo "  make deploy GAS_ENV=xxx VERSION_DESC='...' - バージョン付きで clasp push & deploy"
	@echo "  make deploy-no-version GAS_ENV=xxx        - バージョンを付けずに clasp push & deploy"
	@echo "  make diff VERSION_NUM_FROM=x VERSION_NUM_TO=y - 2バージョンの差分を比較"
	@echo "  make version-list                          - clasp に登録されたバージョン一覧を表示"
	@echo "  make clean                                  - build ディレクトリと .clasp.json を削除"
	@echo "  make help                                   - このヘルプを表示"
	@echo ""
	@echo "例: make deploy GAS_ENV=stg VERSION_DESC='stg用リリース'"
	@echo ""

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
	@if [ -z "$(VERSION_DESC)" ]; then \
		echo "❌ VERSION_DESC が未指定です。例: make deploy GAS_ENV=stg VERSION_DESC='stg用リリース'" >&2; \
		exit 1; \
	fi
	@echo "🚀 デプロイ先環境: $(GAS_ENV)"
	@read -p "$(GAS_ENV) 環境にデプロイしてもよろしいですか？ (y/n): " ans; \
	if [ "$$ans" = "y" ]; then \
		echo "📤 clasp push 実行中..." && \
		clasp push && \
		echo "📌 バージョン作成: $(VERSION_DESC)" && clasp version "$(VERSION_DESC)" && \
		clasp deploy; \
	else \
		echo "⚠️ デプロイをキャンセルしました。"; \
	fi

deploy-no-version: init build
	@echo "🚀 バージョンなしデプロイ: $(GAS_ENV)"
	@read -p "$(GAS_ENV) 環境にデプロイ（バージョンなし）してもよろしいですか？ (y/n): " ans; \
	if [ "$$ans" = "y" ]; then \
		echo "📤 clasp push 実行中..." && \
		clasp push && \
		echo "🚀 デプロイ中..." && \
		clasp deploy; \
	else \
		echo "⚠️ デプロイをキャンセルしました。"; \
	fi

diff:
	@if [ -z "$(VERSION_NUM_FROM)" ] || [ -z "$(VERSION_NUM_TO)" ]; then \
		echo "❌ VERSION_NUM_FROM または VERSION_NUM_TO が未指定です。" >&2; \
		echo "   例: make diff VERSION_NUM_FROM=2 VERSION_NUM_TO=3" >&2; \
		exit 1; \
	fi
	@echo "📥 バージョン $(VERSION_NUM_FROM) と $(VERSION_NUM_TO) を取得します..."
	@rm -rf diff_versions/v$(VERSION_NUM_FROM) diff_versions/v$(VERSION_NUM_TO)
	@mkdir -p diff_versions/v$(VERSION_NUM_FROM) diff_versions/v$(VERSION_NUM_TO)
	@echo '{"scriptId":"$(SCRIPT_ID)", "rootDir": "."}' > diff_versions/v$(VERSION_NUM_FROM)/.clasp.json
	@echo '{"scriptId":"$(SCRIPT_ID)", "rootDir": "."}' > diff_versions/v$(VERSION_NUM_TO)/.clasp.json
	@cd diff_versions/v$(VERSION_NUM_FROM) && clasp pull --versionNumber $(VERSION_NUM_FROM) > /dev/null
	@cd diff_versions/v$(VERSION_NUM_TO) && clasp pull --versionNumber $(VERSION_NUM_TO) > /dev/null
	@echo "🔍 v$(VERSION_NUM_FROM) と v$(VERSION_NUM_TO) の差分を表示します"
	@diff -ru diff_versions/v$(VERSION_NUM_FROM) diff_versions/v$(VERSION_NUM_TO) > .diff_output.tmp 2>&1 || true
	@if [ -s .diff_output.tmp ]; then \
		cat .diff_output.tmp; \
	else \
		echo "✅ 差分はありません"; \
	fi
	@rm -f .diff_output.tmp

color-diff:
	@if [ -z "$(VERSION_NUM_FROM)" ] || [ -z "$(VERSION_NUM_TO)" ]; then \
		echo "❌ VERSION_NUM_FROM または VERSION_NUM_TO が未指定です。" >&2; \
		echo "   例: make diff VERSION_NUM_FROM=2 VERSION_NUM_TO=3" >&2; \
		exit 1; \
	fi
	@echo "📥 バージョン $(VERSION_NUM_FROM) と $(VERSION_NUM_TO) を取得します..."
	@rm -rf diff_versions/v$(VERSION_NUM_FROM) diff_versions/v$(VERSION_NUM_TO)
	@mkdir -p diff_versions/v$(VERSION_NUM_FROM) diff_versions/v$(VERSION_NUM_TO)
	@echo '{"scriptId":"$(SCRIPT_ID)", "rootDir": "."}' > diff_versions/v$(VERSION_NUM_FROM)/.clasp.json
	@echo '{"scriptId":"$(SCRIPT_ID)", "rootDir": "."}' > diff_versions/v$(VERSION_NUM_TO)/.clasp.json
	@cd diff_versions/v$(VERSION_NUM_FROM) && clasp pull --versionNumber $(VERSION_NUM_FROM) > /dev/null
	@cd diff_versions/v$(VERSION_NUM_TO) && clasp pull --versionNumber $(VERSION_NUM_TO) > /dev/null
	@echo "🔍 v$(VERSION_NUM_FROM) と v$(VERSION_NUM_TO) の差分を表示します"
	@diff -ru diff_versions/v$(VERSION_NUM_FROM) diff_versions/v$(VERSION_NUM_TO) > .diff_output.tmp 2>&1 || true
	@if [ -s .diff_output.tmp ]; then \
		rm -rf .diff_output.tmp; \
		colordiff -ru diff_versions/v$(VERSION_NUM_FROM) diff_versions/v$(VERSION_NUM_TO); \
	else \
		echo "✅ 差分はありません"; \
	fi

version-list:
	@clasp versions

clean:
	@rm -rf build .clasp.json diff_versions
	@echo "🧹 クリーン完了"
