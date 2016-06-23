class ServiceVersion < ApplicationRecord
  belongs_to :service
  belongs_to :user
  validates :spec, swagger_spec: true
  before_create :set_version_number
  after_save :update_search_metadata
  after_create :retract_proposed

  # proposed: 0, current: 1, rejected: 2, retracted:3 , outdated:4 , retired:5
  #
  # The lifecycle is a follows:
  #
  # A new service version is born "proposed".
  # Until it is approved by GobiernoDigital, where it becomes "current".
  # Unless it is NOT approved, and it turns "rejected".
  # Or, the author decides to upload a new version before the approval or
  # rejection, in which case it becomes "retracted"
  # Also, once a subsequent version is accepted and becomes "current", the
  # previously current version becomes "outdated" if the change is backwards
  # compatible. If the change is NOT backwards compatible, it becomes "retired"
  #
  # ALWAYS add new states at the end.
  enum status: [:proposed, :current, :rejected, :retracted, :outdated, :retired]

  def spec_file
    @spec_file
  end

  def spec_file=(spec_file)
    @spec_file = spec_file
    self.spec = JSON.parse(spec_file.read)
  end

  def to_param
    version_number.to_s
  end

  def set_version_number
    self.version_number = service.last_version_number + 1
  end

  def update_search_metadata
    service.update_search_metadata if status == "current"
  end

  def make_current_version
    self.current!
    update_old_versions_statuses
  end

  def reject_version
    self.rejected!
  end

  def update_old_versions_statuses
    if self.backward_compatibility?
      new_status = ServiceVersion.statuses[:outdated]
    else
      new_status = ServiceVersion.statuses[:retired]
    end
    service.service_versions.current.where(
      "version_number != ?", self.version_number).update_all(
      status: new_status)
  end

  def retract_proposed
    service.service_versions.proposed.where(
      "version_number != ?", self.version_number).update_all(
      status: ServiceVersion.statuses[:retracted])
  end
end
