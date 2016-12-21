module SolrSearchable

  # each model that depends on SolrSearchable can add to the searchable fields using these methods
  # 
  # FILTERS: check for exact equality
  # FIELDS: search based on full-text tokenizing
  # DATES: allow for searching based on a date range (i.e. before/after)

  def filters
    ["id"]
  end

  def fields
    ["name", "created_by", "updated_by"]
  end

  def dates
    ["created_at", "updated_at"]
  end

  def search_fields
    self.fields + self.filters + self.dates
  end

  def params_for_search(params)
    permitted = []
    self.fields.each do |field|
      permitted.push(field.to_sym)
      permitted.push({field.to_sym => []})
    end
    params.permit(permitted)
  end

  def filters_for_search(params)
    permitted = []
    self.filters.each do |filter|
      permitted.push(filter.to_sym)
      permitted.push({filter.to_sym => []})
    end
    params.permit(permitted)
  end

  def dates_for_search(params)
    permitted = []
    self.dates.each do |date|
      permitted.push(date.to_sym)
      permitted.push({date.to_sym => []})
    end
    params.permit(permitted)
  end

  def options_for_search(params)
    params.permit(self.search_fields.map do |s| {s + "_option" => []} end, self.search_fields.map do |s| s + "_option" end)
  end

  def do_csv_search(params, download)
    s = do_search(params)
    
    # any possible 'speed up' would need to be done here:
    results = s.results.map do |obj|
      obj.search_result_format
    end

    headers = results.first.keys
    filename = download.filename
    user = download.user
    id = download.id
    path = "/tmp/#{id}_#{user}_#{filename}"
    
    csv_file = CSV.open(path, "wb") do |csv|
      csv << headers
      results.each do |r|
        csv << r.values 
      end
    end

    Zip::File.open("#{path}.zip", Zip::File::CREATE) do |zipfile|
      zipfile.add(filename, path)
    end

    File.delete(path) if File.exist?(path)

    download.update({status: 1, filename: "#{filename}.zip"})
    #download.created_by.notify("Your download '#{download.filename}' is ready.")
  end

  def do_search(params)
    format = params[:format].present? ? params[:format] : 'none'

    order = params[:order].present? ? {field: params[:order].split[0], direction: params[:order].split[1]} : {}
    limit = params[:limit].present? ? params[:limit].to_i : 50
    page = params[:limit] ? (params[:offset].to_i / params[:limit].to_i) + 1 : 1
    s_op = params[:op].present? ? params[:op] : 'AND'

    options = options_for_search(params)

    reviewed = params[:reviewed] && params[:reviewed] == "1" ? false : nil

    filters = filters_for_search(params)
    params = params_for_search(params)
    dates = dates_for_search(params)

    s = self.search do
      
      fulltext_search = lambda { |p, o| 
        if params.present?
          p.each do |field, value|
            value = Array(value)
            if value.kind_of? Array
              value.each do |v|
                op = Array(options[field + "_option"]).shift
                # if searching for this 'without' the term, right now just add a '-' to the beginning of query to negate it
                if op && op == 'does not contain'
                  fulltext "-" + v.gsub(' ', '+'), :fields => [field]
                elsif op && op == 'blank'
                  with field, nil
                elsif op && op == 'not blank'
                  without field, nil
                elsif op && op == 'before'
                  with(field).less_than v
                elsif op && op == 'after'
                  with(field).greater_than v
                else
                  fulltext v, :fields => [field]
               end
              end
           end
          end
        end
      }

      if not reviewed.nil?
        with :reviewed, false
      end

      if filters.present?
        filters.each do |field, value|
          value = Array(value)
          value.each do |v|
            op = Array(options[field + "_option"]).shift
            if op && op == 'blank'
              with field, nil
            elsif op && op == 'not blank'
              without field, nil
            elsif v.blank? # ignore blank
            elsif op && op == 'less than'
              with(field).less_than v
            elsif op && op == 'greater than'
              with(field).greater_than v
            elsif op && op == 'without'
              without field, v
            elsif v.kind_of?(Array) && v.all? { |v2| v2.blank? } # make sure it's not an array of blanks 
            else
              if ['true', 'false'].include? v
                v = (v == 'true')
              end
              with field, v
            end
          end
        end
      end

      if dates.present?
        dates.each do |field, value|
          value = Array(value)
          value.each do |v|
            v = v.split(/[-\/]/).join("").ljust(8, '01')
            op = Array(options[field + "_option"]).shift
            # FIX ME: I used exception handling here because Date parsing for such varied input is awful - probably a better way
            begin
              if op && op == 'before'
                with(field).between(Date.new(0,1,1)..Date.parse(v))
              elsif op && op == 'after'
                with(field).between(Date.parse(v)..Date.today)
              elsif op && op == 'near'
                d = Date.parse(v)
                with(field).between((d - 1.month)..(d + 1.month))
              elsif op && op == 'exact'
                with(field, v)
              end
            rescue ArgumentError
              @error = "Error in Date Search - please use format YYYY/MM/DD or similar"
            end
          end
        end
      end

      # in order to use SUNSPOTS 'and'/'or' options, we create a lambda function for fulltext searching (above)

      if s_op == 'OR'
        any do
          fulltext_search.call(params, options)
        end
      else
        all do
          fulltext_search.call(params, options)
        end
      end

      # unfortunately, sunspot does not natively support MIXING fulltext and exact searches using the "OR" operator - so we do that manually
      # 
      # params[:fq] refer to 'filter queries', or queries that refer to a fixed set of objects (exact strings, numbers, etc.)
      # params[:q] refers to fulltext queries

      adjust_solr_params do |params|
        new_q = []
        p_fq = []
        params[:fq].each do |fq|
          if not fq.include? "type"
            new_q.push('_query_:"{!edismax} ' + fq + '"')
          else
            p_fq.push(fq)
          end
        end
        params[:fq] = p_fq
        if params[:q].blank?
          # nothing here...
        elsif not params[:q].include? s_op
          params[:q] = '(_query_:"{!edismax qf=\'' + params[:qf] + '\'}' + params[:q] + '")'
          params.delete(:qf)
        end
        if params[:q].blank?
          if new_q.length > 0
            params[:q] = new_q.join(" #{s_op} ")
          else
            params[:q] = "*"
          end
        else
          params[:q] = ([params[:q]] + new_q).join(" #{s_op} ")
        end
      end

      # a CSV search is unpaginated, so the entire search results are returned

      if format != 'csv'
        paginate :per_page => limit, :page => page
      else
        paginate :page => 1, :per_page => self.all.count
      end

      order.present? ? order_by(order[:field], order[:direction]) : order_by(:score, :desc)
    end

    return s
  end

end