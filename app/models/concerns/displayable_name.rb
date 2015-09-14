
# Provides a #display_value method to models that have an optional
# association to a Name and an observed_name field.
module DisplayableName

  extend ActiveSupport::Concern

  # 'obj' arg should be a Model object with a 'name' property
  def display_value(obj)
    case
    when obj && observed_name
      "#{obj.name} (#{observed_name})"
    when obj
      "#{obj.name}"
    when observed_name
      "#{observed_name}"
    else
      ""
    end
  end

end
