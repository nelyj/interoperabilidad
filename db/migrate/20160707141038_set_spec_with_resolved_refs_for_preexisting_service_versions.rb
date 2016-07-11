require 'open3'

class SetSpecWithResolvedRefsForPreexistingServiceVersions < ActiveRecord::Migration[5.0]

  class ServiceVersion < ApplicationRecord
    def update_spec_with_resolved_refs
      output, _ = Open3.capture2("sway-resolve", :stdin_data => spec.to_json)
      # spec_with_resolved_refs will have two keys:
      # - `spec_with_resolved_refs['definition']`, will mirror `self.spec`
      #   but with all $refs replaced by the resolved/expanded content
      # - `spec_with_resolved_refs['references']` will contain a hash with an
      #   entry for every reference that has been resolved. Each entry in the hash
      #   will have the JSON Pointer of the parent element where a $ref was found
      #   as a key. And the value will include 'uri' (with the original ref URI),
      #  'type' (which can take the values 'local', 'remote'), among others. See
      #  the output of the sway-resolve command for more details.
      self.spec_with_resolved_refs = JSON.parse(output)
    end
  end

  def up
    ServiceVersion.all.each do |service_version|
      service_version.update_spec_with_resolved_refs
      service_version.save!
    end
  end

  def down
    execute "UPDATE service_versions SET spec_with_resolved_refs = null;"
  end
end
