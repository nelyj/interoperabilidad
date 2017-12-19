class AddExampleDataCategories < ActiveRecord::Migration[5.0]
  def change
    DataCategory.create!(name: 'persona')
    DataCategory.create!(name: 'respuesta-http')
  end
end
