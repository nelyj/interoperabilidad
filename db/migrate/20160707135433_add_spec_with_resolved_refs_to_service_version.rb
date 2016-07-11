class AddSpecWithResolvedRefsToServiceVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :service_versions, :spec_with_resolved_refs, :jsonb
  end
end
