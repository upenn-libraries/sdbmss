
# Treat Admin search screen as a specialized case of a
# CatalogController so we can take advantage of its search
# functionality.
#
# Alternatively, we could tack this functionality directly into
# CatalogController, but AdminSearchController gives us our own view
# directory for overriding partials, which I think is probably useful.
class AdminSearchController < CatalogController

  before_action :authenticate_user!

  # override from superclass to provide search results in JSON format
  # expected by datatables widget
  def render_search_results_as_json
    dateformat = "%Y-%m-%d %I:%M%P"
    retval = {
      draw: params[:draw],
    }
    begin
      pinfo = pagination_info(@response)

      data = @document_list.map do |doc|
        # for performance, we avoid using has_many->through
        # associations because they always hit the db and circumvent
        # the preloading done in load_associations scope.
        entry = doc.get_model_object
        manuscript = entry.get_manuscript
        source = entry.source
        transaction = entry.get_transaction
        transaction_seller_agent = (transaction.get_seller_agent_as_agent.name if transaction && transaction.get_seller_agent_as_agent)
        transaction_seller_or_holder = (transaction.get_seller_or_holder_as_agent.name if transaction && transaction.get_seller_or_holder_as_agent)
        transaction_buyer = (transaction.get_buyer_as_agent.name if transaction && transaction.get_buyer_as_agent)
        created_at = entry.created_at ? entry.created_at.strftime(dateformat) : nil
        created_by = entry.created_by
        updated_at = entry.updated_at ? entry.updated_at.strftime(dateformat) : nil
        updated_by = entry.updated_by
        [
          nil,
          entry.id,
          manuscript ? manuscript.get_public_id : nil,
          source.date,
          source.title,
          entry.catalog_or_lot_number,
          entry.date,
          transaction_seller_agent,
          transaction_seller_or_holder,
          transaction_buyer,
          (transaction.sold if transaction),
          (transaction.get_price_for_display if transaction),
          entry.entry_titles.map(&:title).join("; "),
          entry.entry_authors.map(&:get_display_value).join("; "),
          entry.entry_dates.map(&:get_display_value).join("; "),
          entry.entry_artists.map(&:artist).map(&:name).join("; "),
          entry.entry_scribes.map(&:scribe).map(&:name).join("; "),
          entry.entry_languages.map(&:language).map(&:name).join("; "),
          entry.entry_materials.map(&:material).join("; "),
          entry.entry_uses.map(&:use).join("; "),
          entry.folios,
          entry.num_columns,
          entry.num_lines,
          entry.height,
          entry.width,
          entry.alt_size,
          entry.miniatures_fullpage,
          entry.miniatures_large,
          entry.miniatures_small,
          entry.miniatures_unspec_size,
          entry.initials_historiated,
          entry.initials_decorated,
          entry.manuscript_binding,
          entry.manuscript_link,
          entry.other_info,
          entry.get_provenance.map(&:get_display_value).join("; "),
          created_at,
          (created_by.username if created_by),
          updated_at,
          (updated_by.username if updated_by),
          entry.approved,
        ]
      end

      retval.merge!({
                      recordsTotal: pinfo[:total_count],
                      recordsFiltered: pinfo[:total_count],
                      data: data,
                    })
    rescue Exception => e
      retval.merge!({
                      error: e.to_s
                    })
    end
    retval
  end

end
