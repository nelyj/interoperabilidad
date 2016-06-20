class AddSchemaCategories < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      INSERT INTO schema_categories (name, created_at, updated_at)
        VALUES ('Datos Personales', current_timestamp, current_timestamp);
      INSERT INTO schema_categories (name, created_at, updated_at)
        VALUES ('Patentes', current_timestamp, current_timestamp);
      INSERT INTO schema_categories (name, created_at, updated_at)
        VALUES ('Vehiculos', current_timestamp, current_timestamp);
    SQL
  end

  def down
    execute <<-SQL
      TRUNCATE TABLE schema_categories;
    SQL
  end
end
