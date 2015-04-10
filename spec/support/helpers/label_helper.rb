module LabelHelper
  def label_outside_function(label)
    label_inside_function label, nil
  end

  def label_inside_function(label, function_name)
    [function_name, label].join('$')
  end

  def fresh_label
    next_label 'label'
  end

  def next_label(prefix)
    [prefix, @label_number ||= 0].join.tap { @label_number += 1 }
  end
end
