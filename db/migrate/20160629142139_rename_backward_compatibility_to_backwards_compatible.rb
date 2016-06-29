class RenameBackwardCompatibilityToBackwardsCompatible < ActiveRecord::Migration[5.0]
  def change
    rename_column :service_versions, :backward_compatibility, :backwards_compatible
  end
end
