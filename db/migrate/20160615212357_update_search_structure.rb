class UpdateSearchStructure < ActiveRecord::Migration[5.0]
  
  def up
    execute <<-SQL
      DROP INDEX tsv_idx;
      DROP INDEX name_idx;
      ALTER TABLE service_versions DROP COLUMN tsv;
      ALTER TABLE services DROP COLUMN tsv;
      ALTER TABLE services ADD COLUMN lexemes tsvector;
      CREATE INDEX lexemes_idx ON services USING gin(lexemes);
      DROP TRIGGER specUpdateSearch ON service_versions;
      DROP TRIGGER nameUpdateSearch ON services;
      DROP FUNCTION spec_search_trigger();
      DROP FUNCTION name_search_trigger();
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX lexemes_idx;
      ALTER TABLE services DROP COLUMN lexemes;
      ALTER TABLE service_versions ADD COLUMN tsv tsvector;
      ALTER TABLE services ADD COLUMN tsv tsvector;
      CREATE INDEX tsv_idx ON service_versions USING gin(tsv);
      CREATE INDEX name_idx ON services USING gin(tsv);
      CREATE OR REPLACE FUNCTION spec_search_trigger() RETURNS trigger AS $$
      begin
        new.tsv :=
          setweight(to_tsvector('es', coalesce(new.spec#>>'{info, title}', ' ')), 'B') ||
            setweight(to_tsvector('es', coalesce(new.spec#>>'{info, description}', ' ')), 'C');
        return new;
      end
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION name_search_trigger() RETURNS trigger AS $$
      begin
        new.tsv :=
          setweight(to_tsvector('es', coalesce(new.name, ' ')), 'A');
        return new;
      end
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER specUpdateSearch BEFORE INSERT
        ON service_versions FOR EACH ROW EXECUTE PROCEDURE spec_search_trigger();

      CREATE TRIGGER nameUpdateSearch BEFORE INSERT
        ON services FOR EACH ROW EXECUTE PROCEDURE name_search_trigger();
    SQL
  end
end
