# -*- encoding : utf-8 -*-
class SolrDocument
  include Blacklight::Solr::Document

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  def initialize(*args)
    super
    raise "Error: solr_response doesn't have objects_resultset" if !@response.respond_to? :objects_resultset
    @response.objects_resultset ||= SDBMSS::Blacklight::ResultSet.new
    @response.objects_resultset.add(self[:entry_id])
  end

  # Sunspot indexes records with ids like "Entry 282452", but routes
  # expect the numeric entry_id.  Override to_param so that
  # polymorphic_url(doc) and solr_document_path(doc) produce
  # /catalog/282452 instead of /catalog/Entry%20282452.
  def to_param
    (self["entry_id"] || id.to_s.sub(/\AEntry\s+/, '')).to_s
  end

  # returns the Entry object for this solr document
  def model_object
    object = @response.objects_resultset.get(self[:entry_id])

    if object.blank? || object.id.blank?
      Rails.logger.warn(
        "SolrDocument#model_object missing entry for solr_id=#{self[:id].inspect} entry_id=#{self[:entry_id].inspect}"
      )
    end

    object
  end

end
