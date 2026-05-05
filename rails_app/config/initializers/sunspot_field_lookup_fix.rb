# Sunspot 2.5.0 bug: add_text_field_factory() (setup.rb:65) also writes the
# text factory into @field_factories_cache, overwriting any attribute factory
# (string, integer, etc.) already registered under the same name.  When a
# searchable block declares both
#
#   string :foo { ... }
#   text   :foo { ... }
#
# the text factory wins in @field_factories_cache, so Setup#field(:foo)
# returns the FulltextField factory (multiple: true).  order_by(:foo) then
# raises ArgumentError: "foo cannot be used for ordering because it is a
# multiple-value field".
#
# Fix: before delegating to the original method, capture any existing entry
# in @field_factories_cache; restore it afterwards so that the string/integer
# factory retains precedence for sorting and filtering.  The text factory
# remains correctly registered in @text_field_factories_cache, so fulltext
# search is unaffected.
Sunspot::Setup.prepend(Module.new do
  def add_text_field_factory(name, options = {}, &block)
    existing = @field_factories_cache[name.to_sym]
    super
    @field_factories_cache[name.to_sym] = existing if existing
  end
end)
