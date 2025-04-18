# ========== 設定 ==========
ifndef GAS_ENV
$(error ❌ GAS_ENV が未指定です。例: make deploy GAS_ENV=stg)
endif

include .env
export

ifeq ($(GAS_ENV),prd)
SCRIPT_ID := $(SCRIPT_ID_PRD)
else ifeq ($(GAS_ENV),stg)
SCRIPT_ID := $(SCRIPT_ID_STG)
else
$(error ❌ GAS_ENV=$(GAS_ENV) は未定義の環境です)
endif

.PHONY: init deploy pull

init:
	@echo "🧹 tmp ディレクトリを初期化します"
	@rm -rf tmp && mkdir -p tmp
	@echo "🧹 .clasp.json と appsscript.json を初期化します"
	@rm -f .clasp.json src/appsscript.json
	@echo "🛠️ $(GAS_ENV) 環境の clasp 設定ファイルを取得します"
	@cd tmp && clasp clone $(SCRIPT_ID)
	@cp tmp/.clasp.json .clasp.json
	@cp tmp/appsscript.json src/appsscript.json
	@rm -rf tmp
	@echo "✅ .clasp.json と appsscript.json を $(GAS_ENV) 環境用にコピーしました"

deploy: 
	@echo "🚀 デプロイ先環境: $(GAS_ENV)"
	@read -p "$(GAS_ENV) 環境にデプロイしてもよろしいですか？ (y/n): " ans; \
	if [ "$$ans" = "y" ]; then \
		clasp push; \
	else \
		echo "⚠️ デプロイをキャンセルしました。"; \
	fi

