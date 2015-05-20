
module SDBMSS

  class IndexJob < ActiveJob::Base

    queue_as :reindex

    def self.has_entries_to_index_on_update?(model_class)
      model_class.method_defined? :entries_to_index_on_update
    end

    def perform(model_class_str, ids)
      logger = Delayed::Worker.logger

      model_class = model_class_str.constantize
      if self.class.has_entries_to_index_on_update?(model_class)
        logger.info "Starting reindex of #{model_class_str} records..."
        query = model_class.where("id IN (?)", ids)
        count = query.count
        entries_count = 0
        query.each do |model_object|
          entries = model_object.send(:entries_to_index_on_update)
          entries_count += entries.count
          # we might get a Relation or an Array. if it's a Relation,
          # try to batch it so we don't use up a lot of memory.
          if entries.respond_to?(:find_in_batches)
            entries.find_in_batches(batch_size: 500) do |batch|
              Sunspot.index batch
            end
          else
            Sunspot.index entries
          end
        end
        logger.info "Finished reindex of #{entries_count} entries, as result of updating #{count} #{model_class_str} records"
      else
        logger.error "class #{model_class.to_s} isn't indexable because it doesn't provide an #entries_to_index_on_update method"
      end
    end

  end

end
