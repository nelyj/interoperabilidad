# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
VALID_SCHEMA_OBJECT = '{
  "type": "object",
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

puts 'Creating schema categories...'
SchemaCategory.delete_all
[
  "Datos Personales",
  "Configuracion Regional",
  "Vehiculos",
  "Propiedades"
].each do |category_name|
  SchemaCategory.create!(name: category_name)
end

puts 'Seeding Organizations'
ServiceVersion.delete_all
Service.delete_all
Organization.delete_all
[
  {
    name: 'Servicio de Impuestos Internos',
    initials:'SII'
  },
  {
    name: 'Ministerio de Salud',
    initials: 'MINSAL'
  }
].each do |org|
  Organization.create!(org)
end

puts 'Seeding Schemas'
SchemaVersion.delete_all
Schema.delete_all
[
  {
      schema_category: SchemaCategory.find_by(name: "Datos Personales"),
      name: 'Schema 1',
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT)
  },
  {
      schema_category: SchemaCategory.find_by(name: "Vehiculos"),
      name: 'Schema 2',
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT)
    },
    {
      schema_category: SchemaCategory.find_by(name: "Propiedades"),
      name: 'Schema 3',
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT)
    }
].each do |schema|
  Schema.create!(schema)
end

puts 'Seeding SchemaVersions'
[
  {
    spec_file: StringIO.new(VALID_SCHEMA_OBJECT),
    schema: Schema.find_by(name: 'Schema 1')
  },
  {
    spec_file: StringIO.new(VALID_SCHEMA_OBJECT),
    schema: Schema.find_by(name: 'Schema 1')
  },
  {
    spec_file: StringIO.new(VALID_SCHEMA_OBJECT),
    schema: Schema.find_by(name: 'Schema 3')
  }
]

