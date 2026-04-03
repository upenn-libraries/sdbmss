# Psych 3.1+ restricts YAML deserialization to safe classes by default.
# The ActiveRecord session store and Blacklight save Ruby objects (like
# HashWithIndifferentAccess) into YAML-serialized session data.
# This allows those classes to be deserialized.
Rails.application.config.active_record.yaml_column_permitted_classes = [
  ActiveSupport::HashWithIndifferentAccess,
  Symbol
]
