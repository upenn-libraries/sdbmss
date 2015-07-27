
module SDBMSS

  # (Re)indexes Solr documents based on the database changes
  # represented by model_class_str and ids. If model_class_str is
  # 'Entry', we index entries with the specified ids. If
  # model_class_str is an associated model (like 'Name', for example),
  # we find the relevant Entries and index those.
  class IndexJob < ActiveJob::Base

    queue_as :reindex

    def self.has_entries_to_index_on_update?(model_class)
      model_class.method_defined? :entries_to_index_on_update
    end

    def perform(model_class_str, ids)
      logger = Delayed::Worker.logger

      model_class = model_class_str.constantize
      if model_class_str == 'Entry'
        logger.info "Starting reindex of Entry records..."
        entries = Entry.where("id IN (?)", ids)
        entries_count = entries.count
        index_entries(entries)
        logger.info "Finished reindex of #{entries_count} entries"
      elsif self.class.has_entries_to_index_on_update?(model_class)
        logger.info "Starting reindex of #{model_class_str} records..."
        query = model_class.where("id IN (?)", ids)
        count = query.count
        entries_count = 0
        query.each do |model_object|
          entries = model_object.send(:entries_to_index_on_update)
          entries_count += entries.count
          index_entries(entries)
        end
        logger.info "Finished reindex of #{entries_count} entries, as result of updating #{count} #{model_class_str} records"
      else
        logger.error "class #{model_class.to_s} isn't indexable because it isn't an Entry and doesn't provide an #entries_to_index_on_update method"
      end
    end

    def index_entries(entries)
      # we might get a Relation or an Array. if it's a Relation,
      # try to batch it so we don't use up a lot of memory.
      if entries.respond_to?(:find_in_batches)
        entries.find_in_batches(batch_size: 100) do |batch|
          Sunspot.index batch
        end
      else
        Sunspot.index entries
      end
    end

  end

end
