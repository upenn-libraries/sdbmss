#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Schoenberg Database of Manuscripts"
    #xml.author "The University of Pennsylvania Libraries"
    xml.description "A History of Manuscript Transmission"
    xml.link "https://www.sdbm.library.upenn.edu", :rel => "nofollow"
    xml.language "en"

    for entry in @entries
      xml.item do

        xml.link entry_url(entry), :rel => "nofollow"
        xml.title entry.public_id
        xml.pubDate entry.created_at.to_s(:rfc822)
        text = ""
        entry.bookmark_details.each do |key, value|
          text += "<b>#{key}</b>: #{value}<br>"
        end
        xml.description "#{text}"
=begin
      source_date: SDBMSS::Util.format_fuzzy_date(source.date),
      source_title: source.title,
      source_agent: source.source_agents.map(&:agent).join("; "),
      titles: ,
      authors: entry_authors.order(:order).map(&:display_value).join("; "),
      dates: entry_dates.order(:order).map(&:display_value).join("; "),
      artists: entry_artists.order(:order).map(&:display_value).join("; "),
      scribes: entry_scribes.order(:order).map(&:display_value).join("; "),
      languages: entry_languages.order(:order).map(&:language).map(&:name).join("; "),
      materials: entry_materials.order(:order).map(&:material).join("; "),
      places: entry_places.order(:order).map(&:display_value).join("; "),
      uses: entry_uses.order(:order).map(&:use).join("; "),
      other_info: other_info,
      provenance: unique_provenance_agents.map { |unique_agent| unique_agent[:name] }.join("; "),


        if article.title
          xml.title article.title
        else
          xml.title ""
        end
        xml.author "Achim Fischer"
        xml.pubDate article.created_at.to_s(:rfc822)
        xml.link "https://www.codingfish.com/blog/" + article.id.to_s + "-" + article.alias
        xml.guid article.id

        text = article.text
    # if you like, do something with your content text here e.g. insert image tags.
    # Optional. I'm doing this on my website.
        if article.image.exists?
            image_url = article.image.url(:large)
            image_caption = article.image_caption
            image_align = ""
            image_tag = "
                <p><img src='" + image_url +  "' alt='" + image_caption + "' title='" + image_caption + "' align='" + image_align  + "' /></p>
              "
            text = text.sub('{image}', image_tag)
        end
        xml.description "<p>" + text + "</p>"
=end
      end
    end
  end
end