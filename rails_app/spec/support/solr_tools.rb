module SolrTools
  extend self

  SOLR_TEST_MODELS = [Entry, Name, Source, Manuscript, Language, Place].freeze

  def solr_test_uri
    @solr_test_uri ||= URI(ENV['SOLR_TEST_URL'] || 'http://localhost:8983/solr/test')
  end

  def solr_http
    http = Net::HTTP.new(solr_test_uri.host, solr_test_uri.port)
    http.read_timeout = 30
    http
  end

  def clear!
    solr_http.post(
      "#{solr_test_uri.path}/update?commit=true",
      '<delete><query>*:*</query></delete>',
      'Content-Type' => 'application/xml'
    )
  end

  def index_records!(*records)
    flattened_records = records.flatten.compact
    Sunspot.index(flattened_records)
    Sunspot.commit
  end

  def optimize!
    solr_http.post(
      "#{solr_test_uri.path}/update?optimize=true&waitFlush=false&waitSearcher=false",
      '<optimize/>',
      'Content-Type' => 'application/xml'
    )
  end

  def reindex_models!(models = SOLR_TEST_MODELS, per_model_logging: false)
    models.each do |model|
      begin
        Sunspot.index(model.all)
      rescue => e
        raise unless per_model_logging

        Rails.logger.warn("Solr index #{model} after JS test failed: #{e.message}")
      end
    end
    Sunspot.commit
  end

  def flush_and_reindex_after_js!
    clear!
    reindex_models!(SOLR_TEST_MODELS, per_model_logging: true)
  rescue StandardError => e
    Rails.logger.warn("Solr flush after JS test failed: #{e.message}")
  end
end
