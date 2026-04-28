# frozen_string_literal: true

# SDBMSS advanced search form component.
#
# Standalone component (not a subclass of BL9's AdvancedSearchFormComponent)
# because the SDBMSS form layout is fundamentally different: generic text rows
# with field-selector dropdowns + separate numeric range section, vs. BL9's
# one-labeled-row-per-field design. Inheriting from Blacklight::Component gives
# us ViewComponent::Base plus BL's sidecar template resolution.
#
# Replaces these three partials:
#   catalog/_advanced_search_form.html.erb  (form wrapper)
#   catalog/_advanced_search_fields.html.erb (text + numeric field rows + JS)
#   catalog/_advanced_search_submit_btns.html.erb (sort + submit buttons)
#
# And absorbs helpers from:
#   SdbmssAdvancedSearchHelper (select_menu_for_field_operator, advanced_search_context,
#     search_fields_for_advanced_search)
#   ApplicationHelper#prepopulated_search_fields_for_advanced_search

require 'ostruct'

module SDBMSS
  class AdvancedSearchFormComponent < ::Blacklight::Component
    NUM_TEXT_ROWS = 5

    delegate :search_action_url, :search_state, :blacklight_config,
             :sort_field_label, :active_sort_fields, :current_sort_field,
             to: :helpers

    def initialize(url:, params:, response: nil, classes: ['advanced'], method: 'GET')
      @url = url
      @params = params
      @response = response
      @classes = Array(classes)
      @method = method
    end

    def text_field_rows
      prepopulated_rows(is_numeric: false)
    end

    def numeric_field_rows
      prepopulated_rows(is_numeric: true)
    end

    def hidden_search_state_params
      keys_to_strip = advanced_search_fields.keys.map(&:to_sym) +
                       %i[clause f_inclusive op sort page q search_field index]
      @params.except(*keys_to_strip)
    end

    def default_operator_menu
      options = {
        t('blacklight_advanced_search.all') => 'must',
        t('blacklight_advanced_search.any') => 'should'
      }.sort
      select_tag(:op, options_for_select(options, helpers.params[:op]), class: 'input-small')
    end

    def sort_fields_select
      options = active_sort_fields.values.map { |field_config| [sort_field_label(field_config.key), field_config.key] }
      return unless options.any?

      select_tag(:sort, options_for_select(options, helpers.params[:sort]),
                 class: 'form-control sort-select')
    end

    private

    def advanced_search_fields
      @advanced_search_fields ||= blacklight_config.search_fields.select do |_k, v|
        v.include_in_advanced_search || v.include_in_advanced_search.nil?
      end
    end

    def text_search_fields
      @text_search_fields ||= advanced_search_fields.select { |_k, v| !v.is_numeric_field }
    end

    def numeric_search_fields
      @numeric_search_fields ||= advanced_search_fields.select { |_k, v| v.is_numeric_field }
    end

    def prepopulated_rows(is_numeric:)
      fields = is_numeric ? numeric_search_fields : text_search_fields
      fieldnames = fields.keys

      queried_fields = search_state.to_h.dup
      if queried_fields["search_field"].present?
        queried_fields[queried_fields["search_field"]] = queried_fields["q"]
      end
      queried_fields = queried_fields.select { |k, _v| fieldnames.member?(k) }
      queried_fields.sort

      limit = NUM_TEXT_ROWS
      i = 0
      result = []
      while i < limit
        value = value2 = nil
        selected_field = fields.keys.first
        if queried_fields.length > 0
          fieldname = queried_fields.keys.first
          selected_field = fieldname
          if queried_fields[fieldname].kind_of?(Array)
            range_str = queried_fields[fieldname].first
            if !fields[fieldname].is_numeric_field
              value = range_str
            else
              match = /\[(\d+)\s+TO\s+(\d+)\]/.match(range_str)
              if match
                value, value2 = match[1], match[2]
              end
            end
            i += 1
            queried_fields[fieldname].delete(range_str)
            if queried_fields[fieldname].length <= 0
              queried_fields.delete(fieldname)
            end
          elsif !fields[fieldname].is_numeric_field
            value = queried_fields[fieldname]
            queried_fields.delete(fieldname)
            i += 1
          else
            range_str = queried_fields[fieldname]
            match = /\[(\d+)\s+TO\s+(\d+)\]/.match(range_str)
            if match
              value, value2 = match[1], match[2]
            end
            queried_fields.delete(fieldname)
            i += 1
          end
        else
          i += 1
        end
        result << OpenStruct.new(
          index: i - 1,
          fields: fields,
          selected_field: selected_field,
          value: value,
          value2: value2,
        )
      end
      result
    end
  end
end
