SHELL := /bin/bash

all: build db run

run: build
	voltos use gobdigital-interoperabilidad
	voltos run 'docker-compose up -d sidekiq'
	voltos run 'docker-compose run --service-ports web'
	docker-compose stop sidekiq

build: .built .bundled

.built: Dockerfile.development
	docker-compose build
	touch .built

.bundled: Gemfile Gemfile.lock
	voltos run 'docker-compose run web bundle'
	touch .bundled

stop:
	docker-compose stop && if [ $( ls ./tmp/pids/server.pid ) ]; then rm ./tmp/pids/server.pid; fi

restart: build
	voltos run 'docker-compose restart web'

clean: stop
	rm -f tmp/pids/*
	docker-compose rm -f -v bundle_cache
	rm -f .bundled
	docker-compose rm -f
	rm -f .built

vtest: build db
	voltos run 'docker-compose run web rails test'

test: build db
	docker-compose run web rails test

ptest: build db
	docker-compose run -e RAILS_ENV=test web parallel_test -e "rake db:create && bin/rails db:environment:set RAILS_ENV=test"
	docker-compose run web rake parallel:prepare
	docker-compose run -e RECORD_RUNTIME=true web rake parallel:test

logs:
	docker-compose logs

db: build
	docker-compose run web rake db:create db:migrate

production-build: Dockerfile.production
	docker build  -f Dockerfile.production  -t egob/interoperabilidad  .

.PHONY: all run build stop restart clean test ptest logs db production-build
