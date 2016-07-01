class AddSpecWithResolvedRefsToSchemaVersions < ActiveRecord::Migration[5.0]
  def change
    add_column :schema_versions, :spec_with_resolved_refs, :jsonb
  end
end
