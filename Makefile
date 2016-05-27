SHELL := /bin/bash

all: build db run open

run: build
	docker-compose up -d

build: .built .bundled

.built: Dockerfile.development
	docker-compose build
	touch .built

.bundled: Gemfile Gemfile.lock
	docker-compose run web bundle
	touch .bundled

stop:
	docker-compose stop

restart: build
	docker-compose restart web

open:
	$(shell \
				IP=`docker-machine ip default` ;\
				PORT=`docker-compose port web 3000 | cut -d: -f2` ;\
				if [ "$$PORT" == "" ] ;\
				then echo "@echo 'App NOT running. Check the logs'" ;\
				else echo "open http://$${IP}:$${PORT}" ;\
				fi)



clean: stop
	rm -f tmp/pids/*
	docker-compose rm -f -v bundle_cache
	rm -f .bundled
	docker-compose rm -f
	rm -f .built

test: build db
	docker-compose up -d postgres
	docker-compose run web rake spec

logs:
	docker-compose logs

db: build
	docker-compose up -d postgres
	docker-compose run web rake db:create db:migrate

production-build: Dockerfile.production
	docker build  -f Dockerfile.production  -t interoperabilidad  .

.PHONY: all run build stop restart open clean test logs db production-build
