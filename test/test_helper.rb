ENV['RAILS_ENV'] ||= 'test'
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

VALID_SCHEMA_OBJECT = '{
  "type": "object",
  "description": "Some object",
  "required": [
    "name"
  ],
  "properties": {
    "name": {
      "type": "string"
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

  # Add more helper methods to be used by all tests here...
end
