
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
    pinfo = pagination_info(@response)

    data = @document_list.map do |doc|
      entry = doc.get_model_object
      source = entry.source
      transaction = entry.get_transaction
      [
        nil,
        entry.id,
        source.get_display_value,
        entry.catalog_or_lot_number,
        transaction ? transaction.price : nil,
        entry.folios,
        entry.num_columns,
        entry.num_lines,
      ]
    end

    {
      draw: params[:draw],
      recordsTotal: pinfo[:total_count],
      recordsFiltered: pinfo[:total_count],
      data: data,
    }
  end

end
