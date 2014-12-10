# A secret token used to encrypt user_id's in the Bookmarks#export callback URL
# functionality, for example in Refworks export of Bookmarks. In Rails 4, Blacklight
# will use the application's secret key base instead.
#

# Blacklight.secret_key = '2cd2603b3abf9c54d8e7d6988ffd88778d7e1658826eeec9534de1615258fc4d4a1847981e38cc6828bd4c1e0fe1d2572311d311455c5792fa65485eb476c485'

class Blacklight::SolrResponse

  alias_method :old_documents, :documents

  # override #documents so that the returned list of solr documents
  # has a singleton method called get_model_object. We could avoid
  # monkey patching this class, but I'm not (yet) convinced other ways
  # of doing this are any less invasive.
  #
  # TODO: Oddly, #documents gets called twice on a search, which is
  # inefficient.
  def documents
    retval = old_documents

    # fetch all objects in a single query for efficiency
    entries = Entry.where(id: retval.map { |doc| doc[:entry_id_is] })
    # TODO: preload relevant associations
    entries = entries.includes(:entry_authors, :entry_dates, :entry_titles, :entry_places => [:place], :events => [{:event_agents => [:agent]} ], :source => [{:source_agents => [:agent]}])
    ids_to_entries = Hash[entries.map { |entry| [entry.id, entry] }]

    retval.each do |doc|
      # creates a closure over ids_to_entries
      doc.define_singleton_method(:get_model_object) do
        ids_to_entries[doc[:entry_id_is]]
      end
    end

    retval
  end

end

