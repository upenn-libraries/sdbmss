module SampleIndexer
  class << self
    def clear!
      SolrTools.clear!
    end

    def index_records!(*records)
      SolrTools.index_records!(*records)
    end
  end
end
