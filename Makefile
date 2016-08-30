all: lint test

lint:
	docker-compose run --rm app luacheck .

test:
	docker-compose run --rm app resty-busted spec

shell:
	docker-compose run --rm app

repl:
	@docker-compose run --rm app \
		resty        \
			-I lib/    \
			-I vendor/ \
			-e 'require("resty.repl").start()'

.PHONY: lint test shell repl
