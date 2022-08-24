
require 'cgi'
require 'net/http'

# https://www.oclc.org/developer/develop/web-services/viaf/authority-cluster.en.html
module VIAF

  # Namespaces found in VIAF XML
  module NS
    LC = "http://www.loc.gov/zing/srw/"
    VIAF = "http://viaf.org/viaf/terms#"
  end

  module Constants
    HOST = "viaf.org"

    FORMATS = [
      {
        name: "HTML",
        mime_type: "application/xhtml+xml",
        url_suffix: "",
      },
      {
        name: "VIAF XML",
        mime_type: "application/xml",
        url_suffix: "viaf.xml",
      },
      {
        name: "JSON",
        mime_type: "application/json+links",
        url_suffix: "justlinks.json",
      },
      {
        name: "RDF XML",
        mime_type: "application/rdf+xml",
        url_suffix: "rdf.xml",
      },
      {
        name: "RSS XML",
        mime_type: "application/rss+xml",
        url_suffix: "rss.xml",
      },
      {
        name: "MARC21 XML",
        mime_type: "application/marc21+xml",
        url_suffix: "marc21.xml",
      },
      {
        name: "MARC21 HTML",
        mime_type: "application/marc21+html",
        url_suffix: "marc21.html",
      },
      {
        name: "UNIMARC XML",
        mime_type: "application/unimarc+xml",
        url_suffix: "unimarc.xml",
      },
      {
        name: "UNIMARC HTML",
        mime_type: "application/unimarc+html",
        url_suffix: "unimarc.html",
      },
    ]
  end

  def self.get_data(id, format: "JSON")
    format = VIAF::Constants::FORMATS.select { |f| f[:name] == format || f[:mime_type] == format }.first
    url_suffix = format[:url_suffix]
    path = "/viaf/#{id}/#{url_suffix}"
    get_viaf_response(VIAF::Constants::HOST, path)
  end

  def self.sru_search(query, maximumRecords: 10, startRecord: 1, sortKeys: "holdingscount", httpAccept: "text/xml")
    path = "/viaf/search?query=#{CGI::escape(query)}&maximumRecords=#{CGI::escape(maximumRecords.to_s)}&startRecord=#{CGI::escape(startRecord.to_s)}&sortKeys=#{CGI::escape(sortKeys.to_s)}&httpAccept=#{CGI::escape(httpAccept.to_s)}"
    get_viaf_response(VIAF::Constants::HOST, path)
  end

  # we use sru_search, not autosuggest
  def self.autosuggest(query, callback: nil)
    path = "/viaf/AutoSuggest?query=#{CGI::escape(query)}"
    if !callback.nil?
      path += "&callback=#{callback}"
    end
    get_viaf_response(VIAF::Constants::HOST, path)
  end

  def self.get_viaf_response(host, path)
    resp = Net::HTTP.get_response(host, path)
    if %w{ 301 302 }.include? r.code
      resp = Net::HTTP.get_response(URI.parse(r['location']))
    end
    resp
  end

end
