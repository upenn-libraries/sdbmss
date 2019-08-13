# This module is included in any model that has a searchable datatable (Name, Entry, Place, Language, Comment, EntryManuscript, 
# Manuscript, Source, User) and includes the do_search and do_csv_search methods (which handle search logic and results) and
# a number of helper functions for generating and filtering search parameters.

module SolrSearchable

  require 'csv'

  # each model that depends on SolrSearchable can add to the searchable fields using these methods
  # 
  # FILTERS: check for exact equality
  # FIELDS: search based on full-text tokenizing
  # DATES: allow for searching based on a date range (i.e. before/after)

  def filters
    [
      ["Id", "id"],
      ["Added By", "created_by"], 
      ["Updated By",  "updated_by"]
    ]
  end

  def fields
    [
      ["Name", "name"]
    ]
  end

  def dates
    [
      ["Added on", "created_at"], 
      ["Updated on", "updated_at"]
    ]
  end

  def search_fields
    self.fields + self.filters + self.dates
  end

  def params_for_search(params)
    permitted = []
    self.fields.each do |field|
      permitted.push(field[1].to_sym)
      permitted.push({field[1].to_sym => []})
    end
    params.permit(permitted)
  end

  def filters_for_search(params)
    permitted = []
    self.filters.each do |filter|
      permitted.push(filter[1].to_sym)
      permitted.push({filter[1].to_sym => []})
    end
    params.permit(permitted)
  end

  def dates_for_search(params)
    permitted = []
    self.dates.each do |date|
      permitted.push(date[1].to_sym)
      permitted.push({date[1].to_sym => []})
    end
    params.permit(permitted)
  end

  def options_for_search(params)
    params.permit(self.search_fields.map do |s|  {s[1] + "_option" => []} end, self.search_fields.map do |s| s[1] + "_option" end)
  end

  def do_csv_dump
    s = do_search(ActionController::Parameters.new.merge({:limit => self.count, :offset => 0}))
    
    results = s.results.map do |obj|
      obj.search_result_format
    end

    headers = results.first.keys
    filename = "#{self.model_name.to_s.pluralize.underscore}.csv"
    path = "public/static/docs/#{filename}"
    
    File.delete("#{path}.zip") if File.exist?("#{path}.zip")

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

  end

  # CSV searching is the same as usual, but without pagination, and written to file instead of returned to
  # DataTables as JSON

  def do_csv_search(params, download)
    s = do_search(params.merge({:limit => self.count, :offset => 0}))
    
    # any possible 'speed up' would need to be done here:
    results = s.results.map do |obj|
      obj.search_result_format
    end

    headers = results.first.keys
    filename = download.filename
    user = download.user
    id = download.id
    path = "tmp/#{id}_#{user}_#{filename}"
    
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

  # This function defines all advanced (and simple) search functionality everywhere except the public catalog view
  # for Entries, which is handled by Blacklight.

  def do_search(params)

  # This first section sets up basic search parameters based on what was requested.

    format = params[:format].present? ? params[:format] : 'none'

    order = params[:order].present? ? {field: params[:order].split[0], direction: params[:order].split[1]} : {}
    limit = params[:limit].present? ? params[:limit].to_i : 50
    page = params[:limit] ? (params[:offset].to_i / params[:limit].to_i) + 1 : 1
    s_op = params[:op].present? ? params[:op] : 'AND'
    role = params[:role].present? ? params[:role] : 'guest'

    linking_tool = params[:linking_tool].present?

    options = options_for_search(params)

    reviewed = params[:reviewed] && params[:reviewed] == "1" ? false : nil

  # Each model has a custom version of these functions (and a list of valid fields) to permit only the
  # appropriate search fields for each model. 

  # "Params" are any fulltext fields
  # "Filters" are all non-fulltext fields (numbers, booleans, exact string matches)
  # "Dates" are specifically for fields that need to allow date comparison

    filters = filters_for_search(params)
    dates = dates_for_search(params)
    params = params_for_search(params)
    
    s = self.search do
  
  # Fulltext search is defined as a lambda function, since it needs to be able to be combined with non-fulltext
  # search options as the user decides.

      fulltext_search = lambda { |p, o| 
        if params.present?
          p.each do |field, value|

            # Since there are unlimited rows for the advanced search, the user can submit multiple values for the same field
            # i.e. "Title" for an Entry could be "Bible" and "Book" separately.  So, they are iterated over:

            value = Array(value)
            if value.kind_of? Array
              value.each do |v|

                # Each search field can also be qualified in various ways

                op = Array(options[field + "_option"]).shift
                
                # If searching for this 'without' the term, right now just add a '-' to the beginning of query to negate it
                
                if op && op == 'does not contain'
                  fulltext "-" + v.gsub(' ', '+'), :fields => [field]
                elsif op && op == 'blank'
                  with field.gsub('_search', ''), nil
                elsif op && op == 'not blank'
                  without field.gsub('_search', ''), nil
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

      # The same process for exact-match fields, but this time the search is being run and narrowed (i.e. it is not
      # using a lambda function)

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

      # The same process for Dates, but with different interpretations of the search field options to correspond
      # with date-based searching

      if dates.present?
        dates.each do |field, value|
          value = Array(value)
          value.each do |v|
            v = v.split(/[-\/]/).join("").ljust(8, '01')
            op = Array(options[field + "_option"]).shift
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

      # In order to use SUNSPOT'S 'and'/'or' options together with non-fulltext fields,
      # we create a lambda function for fulltext searching (above)

      # ( This may be an idiosycracy of Sunspot only, but that is the reason for this roundabout approach ) 

      if s_op == 'OR'
        any do
          fulltext_search.call(params, options)
        end
      else
        all do
          fulltext_search.call(params, options)
        end
      end

      # Unfortunately, sunspot does not natively support MIXING fulltext and exact searches using the "OR" operator 
      # - so we do that manually
      # 
      # params[:fq] refer to 'filter queries', or queries that refer to a fixed set of objects (exact strings, numbers, etc.)
      # params[:q] refers to fulltext queries

      # What this block of code does is check whether the 'OR' operator is used, and if it has been added by sunspot correctly
      # to the Solr query - if not, it is added in the proper place

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
          params[:q] = '(_query_:"{!edismax qf=\'' + params[:qf] + '\'}' + params[:q].gsub('"', '\"') + '")'
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
        if linking_tool
          # NOTE: remove 'approved' thing here to make unapproved records show up in linking tool...
          params[:q] = '(' + params[:q] + ') AND (_query_:"{!edismax qf=\'deprecated\'}false") AND (_query_:"{!edismax qf=\'draft\'}false")'
        elsif role != "admin" && self.model_name.to_s == 'Entry'
          params[:q] = '(' + params[:q] + ') AND (_query_:"{!edismax qf=\'draft\'}false")'
        end
      end

      # Finally, page number, count and order_by field are accounted for, and the search results are returned

      paginate :per_page => limit, :page => page

      order.present? ? order_by(order[:field], order[:direction]) : order_by(:score, :desc)

    end

    return s
  end

end