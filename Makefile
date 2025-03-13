DB_NAME ?= demo_medium # поменять если нужна другая БД

# Ссылки на бд

# https://edu.postgrespro.ru/demo_small.zip
# https://edu.postgrespro.ru/demo_medium.zip
# https://edu.postgrespro.ru/demo_small.zip

# Скачать базу данных
download-data:
	@if [ ! -f $(DB_NAME).zip ]; then \
		echo "$(DB_NAME).zip not found, downloading..."; \
		wget https://edu.postgrespro.ru/$(DB_NAME).zip; \
	else \
		echo "$(DB_NAME).zip already exists, skipping download"; \
	fi
	unzip -o $(DB_NAME).zip
	mv $(DB_NAME).sql infra/init.sql

# Модифицировать SQL файл init.sql
modify-sql:
	@echo "Modifying SQL file to add IF EXISTS to DROP statements..."
	sed -i 's/DROP \(TABLE\|SCHEMA\|DATABASE\|SEQUENCE\|VIEW\|FUNCTION\|PROCEDURE\|TYPE\|INDEX\)/DROP \1 IF EXISTS/g' infra/init.sql
	
	@echo "Modifying SQL file to add IF NOT EXISTS to CREATE statements (except DATABASE)..."
	sed -i 's/CREATE \(TABLE\|SCHEMA\|SEQUENCE\|TYPE\|INDEX\)/CREATE \1 IF NOT EXISTS/g' infra/init.sql
	
	@echo "SQL file modified successfully."

# Создать базу данных и модифицировать SQL файл
setup-db: download-data modify-sql

# docker compose tasks
compose-up:
	cd infra && docker-compose up -d

compose-down:
	cd infra && docker-compose down