SHELL := /bin/bash

all: build db run

run: build
	docker-compose up -d sidekiq
	docker-compose run --service-ports web
	docker-compose stop sidekiq

build: .built .bundled

.built: Dockerfile.development docker-compose.yml
	docker-compose build
	touch .built

.bundled: Gemfile Gemfile.lock
	docker-compose run web bundle
	touch .bundled

stop:
	docker-compose stop && if [ $( ls ./tmp/pids/server.pid ) ]; then rm ./tmp/pids/server.pid; fi

restart: build
	docker-compose restart web

clean: stop
	rm -f tmp/pids/*
	docker-compose rm -f -v bundle_cache
	rm -f .bundled
	docker-compose rm -f
	rm -f .built

test: build db
	docker-compose run web rails test

# Fail fast when testing
fftest:
	docker-compose run web rails test -f

ptest: build db
	docker-compose run -e RAILS_ENV=test web parallel_test -e "rake db:create && bin/rails db:environment:set RAILS_ENV=test"
	docker-compose run web rake parallel:prepare
	docker-compose run -e RECORD_RUNTIME=true web rake parallel:test

# Run under knapsack using Semaphoreapp's env variables
ktest: build db
	docker-compose run \
	  -e ENABLE_KNAPSACK=true \
	  -e SEMAPHORE_THREAD_COUNT=${SEMAPHORE_JOB_COUNT} \
	  -e SEMAPHORE_CURRENT_THREAD=${SEMAPHORE_CURRENT_JOB} \
	  web rake knapsack:minitest

# Create/Update the knapsack report to balance tests in CI
knapsack: build db
	docker-compose run web rake test KNAPSACK_GENERATE_REPORT=true

logs:
	docker-compose logs

db: build
	docker-compose run web rake db:create db:migrate

production-build: Dockerfile.production
	docker build  -f Dockerfile.production  -t egob/interoperabilidad  .

.PHONY: all run build stop restart clean test ptest fftest knapsack logs db production-build
