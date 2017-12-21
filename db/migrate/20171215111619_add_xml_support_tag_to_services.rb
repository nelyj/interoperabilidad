class AddXmlSupportTagToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :support_xml, :boolean, default: false
  end
end
