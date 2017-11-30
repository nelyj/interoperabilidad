ENV['RAILS_ENV'] ||= 'test'
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'parallel_tests/test/runtime_logger' if ENV['RECORD_RUNTIME']
require "minitest/rails/capybara"
require 'capybara/poltergeist'
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    window_size: [1200, 700],
    screen_size: [1280, 768],
    js_errors: true
  )
end
Capybara.default_driver = :poltergeist
require 'capybara-screenshot/minitest'
Capybara.default_max_wait_time = 4

require 'knapsack'
if ENV['ENABLE_KNAPSACK']
  knapsack_adapter = Knapsack::Adapters::MinitestAdapter.bind
  knapsack_adapter.set_test_helper_path(__FILE__)
end

require 'sidekiq/testing'

VALID_SCHEMA_OBJECT = '{
  "type": "object",
  "title": "Valid",
  "description": "Some object",
  "required": [
    "name"
  ],
  "properties": {
    "name": {
      "type": "string",
      "description": "Second description"
    },
    "age": {
      "type": "integer",
      "format": "int32",
      "minimum": 0
    }
  }
}'

INVALID_SCHEMA_OBJECT = '{
  "type": "object",
  "required": [
    "name"
  ],
  "properties": {
    "address": {
      "$ref": "#/definitions/Address"
    },
    "age": {
      "type": "integer",
      "format": "int32",
      "minimum": 0
    }
  }
}'

VALID_SPEC = '{
    "swagger": "2.0",
    "info": {
        "version": "0.0.0",
        "title": "Swagger Test",
        "description": "A short test description"
    },
    "paths": {
        "/persons": {
            "get": {
                "description": "Gets `Person` objects.\nOptional query param of **size** determines\nsize of returned array\n",
                "parameters": [
                    {
                        "name": "size",
                        "in": "query",
                        "description": "Size of array",
                        "required": true,
                        "type": "number",
                        "format": "double"
                    }
                ],
                "responses": {
                    "200": {
                        "description": "Successful response",
                        "schema": {
                            "title": "ArrayOfPersons",
                            "type": "array",
                            "description": "Some description for this array",
                            "items": {
                                "title": "Person",
                                "type": "object",
                                "properties": {
                                    "name": {
                                        "type": "string",
                                        "description": "this is a property description"
                                    },
                                    "single": {
                                        "type": "boolean"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}'

INVALID_SPEC ='{
    "swagger": "2.0",
    "inffo": {
        "version": "0.0.0",
        "title": "Swagger Test"
    },
    "paths": {
        "/persons": {
            "get": {
                "description": "Gets `Person` objects.\nOptional query param of **size** determines\nsize of returned array\n",
                "responses": {
                    "200": {
                        "description": "Successful response",
                        "schema": {
                            "title": "ArrayOfPersons",
                            "type": "array",
                            "items": {
                                "title": "Person",
                                "type": "object",
                                "properties": {
                                    "name": {
                                        "type": "string"
                                    },
                                    "single": {
                                        "type": "boolean"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  self.use_transactional_tests = false

  DatabaseCleaner.strategy = :truncation

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end
