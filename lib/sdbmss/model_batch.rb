
module SDBMSS

  # This class provides an implementation of #find_in_batches to
  # partially mimic the behavior of an ActiveRecord query
  # object. These objects store a bunch of IDs and fetches them in
  # batches, using a "id IN (?)" where clause. This is useful for
  # large sets of entry ids that are the result of several different
  # queries for entries.
  class ModelBatch

    attr_reader :count

    def initialize(model_class, ids)
      @model_class = model_class
      @ids = ids
      @count = ids.count
    end

    def find_in_batches(batch_size: 100, &block)
      batches = []
      while @ids.count > 0
        batches << @ids.pop(batch_size)
      end
      batches.each do |batch|
        block.call @model_class.with_associations.where("id IN (?)", batch)
      end
    end

  end

end
