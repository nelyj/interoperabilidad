class AddSearchToServiceVersion < ActiveRecord::Migration[5.0]

  def up
    execute <<-SQL
      CREATE EXTENSION unaccent;
      CREATE TEXT SEARCH CONFIGURATION es ( COPY = spanish );
      ALTER TEXT SEARCH CONFIGURATION es ALTER MAPPING FOR hword, hword_part, word WITH unaccent, spanish_stem;
      ALTER TABLE service_versions ADD COLUMN tsv tsvector;
      ALTER TABLE services ADD COLUMN tsv tsvector;
      CREATE INDEX tsv_idx ON service_versions USING gin(tsv);
      CREATE INDEX name_idx ON services USING gin(tsv);
      UPDATE service_versions
        SET tsv = setweight(to_tsvector('es', coalesce(spec#>>'{info, title}', ' ')), 'B') ||
          setweight(to_tsvector('es', coalesce(spec#>>'{info, description}', ' ')), 'C');
      UPDATE services
        SET tsv = setweight(to_tsvector('es', coalesce(services.name, ' ')), 'A');
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX tsv_idx;
      DROP INDEX name_idx;
      ALTER TABLE service_versions DROP COLUMN tsv;
      ALTER TABLE services DROP COLUMN tsv;
      DROP TEXT SEARCH CONFIGURATION es;
      DROP EXTENSION unaccent;
    SQL
  end
end
