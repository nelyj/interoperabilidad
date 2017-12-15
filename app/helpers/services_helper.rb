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
end
