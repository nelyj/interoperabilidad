module ServicesHelper

  def css_class_for_status(status)
    'btn-status ' + ({
      'outdated' => 'static',
      'retired' => 'default',
      'proposed' => 'primary',
      'current' => 'success',
      'retracted' => 'warning',
      'rejected' => 'danger'
    }[status] || '')
  end

  def css_class_for_xml_support(status)
    'btn-status ' + ({
      true => 'success',
      false => 'danger'
    }[status] || '')
  end
end
