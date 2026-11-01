.PHONY: build up down bash

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

bash:
	docker compose exec app bash