# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

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
Organization.delete_all
[
  {
    name: 'Secretaría General de la Presidencia',
    initials: 'SEGPRES'
  },
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
