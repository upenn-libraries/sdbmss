# OVERRIDE Blacklight Advanced Search v8.0.0 to convert legacy params in-place
#   (no redirect) with support for array values, custom operators (_option params),
#   and date field preservation for SearchBuilder processors
# @see https://github.com/projectblacklight/blacklight_advanced_search/blob/0e22b8e5/lib/blacklight_advanced_search/redirect_legacy_params_filter.rb
module SDBMSS
  module BlacklightAdvancedSearch
    class RedirectLegacyParamsFilter
      # Convert a legacy params hash (e.g. all_fields[]=maggs) to BL8 clause
      # format. Returns a new hash — does not mutate the input. Used by the
      # search history / saved searches views to render constraints for
      # searches that were stored before the before_action converted them.
      def self.normalize(params, config)
        params = params.to_h.with_indifferent_access
        return params unless params[:search_field] == 'advanced' && params[:clause].blank?

        normalized = params.dup
        i = 0
        config.search_fields.each do |_key, field|
          next unless normalized[field.key].present?
          normalized[:clause] ||= {}
          Array(normalized[field.key]).each do |val|
            next if val.blank?
            normalized[:clause][i.to_s] = { field: field.key, query: val }
            i += 1
          end
          normalized.delete(field.key)
        end
        normalized
      end

      def self.before(controller)
        params = controller.send(:params)
        config = controller.blacklight_config

        # If the request already has clause params, this is a BL8-style URL
        # (e.g. from a remove-constraint link). Check for orphaned date raw params
        # whose clause was removed — strip them so the filter doesn't persist.
        if params[:clause].present?
          clause_fields = params[:clause].values.map { |c| c[:field] || c['field'] }.compact
          SDBMSS::DATE_FIELDS.each do |date_field|
            if params[date_field].present? && !clause_fields.include?(date_field)
              params.delete(date_field)
            end
          end
        end

        i = 0
        converted = false
        config.search_fields.each do |_key, field|
          next unless params[field.key].present?

          converted = true
          params[:clause] ||= {}
          values = params[field.key]
          options = params["#{field.key}_option"]

          if values.is_a?(Array)
            values.each_with_index do |val, idx|
              next if val.blank?
              clause = { field: field.key, query: val }
              clause[:op] = options[idx] if options.is_a?(Array) && options[idx].present?
              params[:clause][i.to_s] = clause
              i += 1
            end
          else
            clause = { field: field.key, query: values }
            clause[:op] = options if options.present? && !options.is_a?(Array)
            params[:clause][i.to_s] = clause
            i += 1
          end

          # Keep date field raw params for SearchBuilder processors;
          # delete all others since they're now in clause params.
          unless SDBMSS::DATE_FIELDS.include?(field.key)
            params.delete(field.key)
            params.delete("#{field.key}_option")
          end
        end

        if converted || params[:clause].present?
          params[:search_field] = 'advanced' if params[:search_field].blank?
          controller.instance_variable_set(:@search_state, nil)
        end
      end
    end
  end
end
