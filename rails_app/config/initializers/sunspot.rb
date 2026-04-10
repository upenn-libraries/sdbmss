
# register a custom Adapter for Entry, so that 'id' field in Solr
# document gets the object id, instead of default 'Entry NNN' which
# breaks Blacklight
class EntryAdapter < Sunspot::Adapters::InstanceAdapter
  def index_id
    @instance.id
  end
end

# disabled, seems to have no effect on Blacklight: https://github.com/projectblacklight/blacklight/wiki/Sunspot-for-indexing

#Sunspot::Adapters::InstanceAdapter.register(EntryAdapter, Entry)

# OVERRIDE Sunspot Rails v2.5.0 to read MLT results from the correct location.
module Sunspot
  module Search
    class MoreLikeThisSearch < AbstractSearch
      private

      def solr_response
        @solr_response ||= begin
          mlt = @solr_result['moreLikeThis']
          if mlt.is_a?(Hash) && mlt.any?
            # moreLikeThis is keyed by the source document ID
            mlt.values.first
          else
            super
          end
        end
      end
    end
  end
end
