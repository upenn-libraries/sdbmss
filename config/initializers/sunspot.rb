
# register a custom Adapter for Entry, so that 'id' field in Solr
# document gets the object id, instead of default 'Entry NNN' which
# breaks Blacklight
class EntryAdapter < Sunspot::Adapters::InstanceAdapter
  def index_id
    @instance.id
  end
end

# FIX ME: I disabled this, does it break blacklight, as claimed? so far it doesn't seem to
# see more: https://github.com/projectblacklight/blacklight/wiki/Sunspot-for-indexing 

#Sunspot::Adapters::InstanceAdapter.register(EntryAdapter, Entry)