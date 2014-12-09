
# register a custom Adapter for Entry, so that 'id' field in Solr
# document gets the object id, instead of default 'Entry NNN' which
# breaks Blacklight
class EntryAdapter < Sunspot::Adapters::InstanceAdapter
  def index_id
    @instance.id
  end
end

Sunspot::Adapters::InstanceAdapter.register(EntryAdapter, Entry)
