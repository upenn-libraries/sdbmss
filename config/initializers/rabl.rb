# We use rabl to serialize ActiveModel objects because:
#
# 1) JSON serialization that comes with Rails isn't as flexible. It's
# awkward to filter out attributes, add additional arbitrary
# attributes, filter out nils, etc
#
# 2) rabl treats json at the level of the view (it can also work other
# ways) which is nice because it separates serialization as a concern
# from the ActiveModel object code. This lets us easily serialize in
# diff ways: for ex: a 'brief' view of Entries and a complete view.

Rabl.configure do |config|
  config.include_json_root = false
  config.exclude_nil_values = true
  config.exclude_empty_values_in_collections = true
  config.raise_on_missing_attribute = true
end
