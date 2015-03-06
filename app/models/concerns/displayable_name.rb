
# Provides a #display_value method to models that have an optional
# association to a Name and an observed_name field.
module DisplayableName

  extend ActiveSupport::Concern

  def display_value(name_obj)
    case
    when name_obj && observed_name
      "#{name_obj.name} (#{observed_name})"
    when name_obj
      "#{name_obj.name}"
    when observed_name
      "#{observed_name}"
    else
      ""
    end
  end

end
