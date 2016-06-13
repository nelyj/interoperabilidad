class AddTriggerToUpdateSearchColumns < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE FUNCTION spec_search_trigger() RETURNS trigger AS $$
      begin
        new.tsv :=
          setweight(to_tsvector('es', coalesce(new.spec#>>'{info, title}', ' ')), 'B') ||
            setweight(to_tsvector('es', coalesce(new.spec#>>'{info, description}', ' ')), 'C');
        return new;
      end
      $$ LANGUAGE plpgsql;

      CREATE FUNCTION name_search_trigger() RETURNS trigger AS $$
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

  def down
    execute <<-SQL
      DROP TRIGGER specUpdateSearch ON service_versions;
      DROP TRIGGER nameUpdateSearch ON services;
      DROP FUNCTION spec_search_trigger();
      DROP FUNCTION name_search_trigger();
    SQL
  end
end
