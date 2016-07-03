# encoding: UTF-8
class UpdateSchemaCategories < ActiveRecord::Migration[5.0]

  def up
    execute <<-SQL
      UPDATE schemas SET schema_category_id = (
        SELECT id FROM schema_categories WHERE name = 'Datos Personales');
      DELETE FROM schema_categories WHERE name <> 'Datos Personales';
      INSERT INTO schema_categories (name, created_at, updated_at)
        VALUES ('Salud', current_timestamp, current_timestamp);
      INSERT INTO schema_categories (name, created_at, updated_at)
        VALUES ('Geográficos', current_timestamp, current_timestamp);
      INSERT INTO schema_categories (name, created_at, updated_at)
        VALUES ('Comunicación', current_timestamp, current_timestamp);
      INSERT INTO schema_categories (name, created_at, updated_at)
        VALUES ('Documentos', current_timestamp, current_timestamp);
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
