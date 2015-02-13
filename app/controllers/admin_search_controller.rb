
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
    row_error = ([nil] * 41).tap { |a| a[1]="Error loading" }
    retval = {
      draw: params[:draw],
    }
    begin
      pinfo = pagination_info(@response)

      data = @document_list.map do |doc|
        as_array = nil

        # for performance, we avoid using has_many->through
        # associations because they always hit the db and circumvent
        # the preloading done in load_associations scope.
        entry = doc.get_model_object
        if !entry.nil?
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
          as_array = [
            entry.id,
            manuscript ? manuscript.id : nil,
            SDBMSS::Util.format_fuzzy_date(source.date),
            source.title,
            entry.catalog_or_lot_number,
            transaction_seller_agent,
            transaction_seller_or_holder,
            transaction_buyer,
            (transaction.sold if transaction),
            (transaction.get_price_for_display if transaction),
            entry.entry_titles.map(&:title).join("; "),
            entry.entry_authors.map(&:display_value).join("; "),
            entry.entry_dates.map(&:display_value).join("; "),
            entry.entry_artists.map(&:artist).map(&:name).join("; "),
            entry.entry_scribes.map(&:scribe).map(&:name).join("; "),
            entry.entry_languages.map(&:language).map(&:name).join("; "),
            entry.entry_materials.map(&:material).join("; "),
            entry.entry_places.map(&:place).map(&:name).join("; "),
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
            entry.get_provenance.map(&:display_value).join("; "),
            created_at,
            (created_by.username if created_by),
            updated_at,
            (updated_by.username if updated_by),
            entry.approved,
          ]
        else
          # TODO: how to more elegantly handle errors finding entries
          # from db?
          as_array = ([nil] * 41).tap { |a| a[1] = doc.id; a[4] = "Error loading this record from the database" }
        end
        as_array
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

  # This is an AJAX endpoint to calculates the lower and upper bounds
  # (inclusive) on entry_id for a "Jump To" search.
  def calculate_bounds
    per_page = params['per_page'].to_i
    entry_id = params['entry_id'].to_i
    if per_page.present? && entry_id.present?

      offset = per_page / 2

      lower = Entry.where("id < ? ", entry_id).order(id: :desc).offset(offset - 1).limit(1).first
      lower_id = lower.present? ? lower.id : 1
      upper = Entry.where("id > ? ", entry_id).order(id: :asc).offset(offset - 2).limit(1).first
      upper_id = upper.present? ? upper.id : Entry.maximum(:id)

      respond_to do |format|
        format.json { render :json => { 'lower_bound' => lower_id, 'upper_bound' => upper_id }, :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { 'error' => 'per_page, entry_id required' }, :status => 500 }
      end
    end
  end

end
