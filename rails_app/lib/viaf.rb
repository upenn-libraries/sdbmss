
require 'cgi'
require 'net/http'
require 'openssl'

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

  def self.sru_search(query, maximumRecords: 10, startRecord: 1, sortKeys: "holdingscount", httpAccept: "application/xml")
    path = "/viaf/search"
    query_string = "query=#{CGI::escape(query)}&maximumRecords=#{CGI::escape(maximumRecords.to_s)}&startRecord=#{CGI::escape(startRecord.to_s)}&sortKeys=#{CGI::escape(sortKeys.to_s)}"
    get_viaf_response(VIAF::Constants::HOST, path, query_string: query_string, httpAccept: httpAccept)
  end

  # we use sru_search, not autosuggest
  def self.autosuggest(query, callback: nil)
    path = "/viaf/AutoSuggest?query=#{CGI::escape(query)}"
    if !callback.nil?
      path += "&callback=#{callback}"
    end
    get_viaf_response(VIAF::Constants::HOST, path)
  end

  def self.get_viaf_response(host, path, query_string: nil, httpAccept: 'application/xml')
    full_path = query_string.present? ? "#{path}?#{query_string.sub(/^\?/, '')}" : path
    url = "https://#{host}#{full_path}"
    Rails.logger.debug "URL is '#{url}'"
    uri = URI.parse(url)
    resp = make_viaf_request(uri)

    count = 0
    while %w{ 301 302 307 }.include? resp.code
      Rails.logger.warn "VIAF response code: #{resp.code} and location: #{resp['location']}"
      url = resp['location'].starts_with?('/') ? "#{host}#{resp['location']}" : resp['location']
      uri = URI.parse(url)
      resp = make_viaf_request(uri)

      count += 1
      if count > 5
        Rails.logger.warn "Redirected more than 5 times!"
        break
      end
    end
    Rails.logger.debug "VIAF response code: #{resp.code} and location: #{resp['location']}"
    resp
  end

  def self.make_viaf_request(uri)
    http_object = Net::HTTP.new(uri.host, uri.port)
    http_object.use_ssl = true  # Enable HTTPS
    http_object.verify_mode = OpenSSL::SSL::VERIFY_PEER  # Verify SSL certificates
    req = Net::HTTP::Get.new(uri.request_uri, 'Accept' => 'application/xml')
    http_object.request(req)
  end

end
