class AddSearchStructureToSchemas < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      DROP INDEX lexemes_idx;
      CREATE INDEX services_lexemes_idx ON services USING gin(lexemes);
      ALTER TABLE schemas ADD COLUMN lexemes tsvector;
      CREATE INDEX schemas_lexemes_idx ON schemas USING gin(lexemes);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX services_lexemes_idx;
      CREATE INDEX lexemes_idx ON services USING gin(lexemes);
      DROP INDEX schemas_lexemes_idx;
      ALTER TABLE schemas DROP COLUMN lexemes;
    SQL
  end
end
