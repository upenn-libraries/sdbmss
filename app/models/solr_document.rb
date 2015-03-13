# -*- encoding : utf-8 -*-
class SolrDocument 

  include Blacklight::Solr::Document    

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  def initialize(*args)
    super
    raise "Error: solr_response doesn't have objects_resultset" if !@response.respond_to? :objects_resultset
    @response.objects_resultset ||= SDBMSS::Blacklight::ResultSet.new
    @response.objects_resultset.add(self[:entry_id])
  end

  # returns the Entry object for this solr document
  def model_object
    @response.objects_resultset.get(self[:entry_id])
  end

end
