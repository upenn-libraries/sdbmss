# OVERRIDE Blacklight 8.12.3: append ?search_field=all_fields to the
# Start Over URL so it doesn't return to the bare root page.
module SDBMSS
  class StartOverButtonComponent < ::Blacklight::StartOverButtonComponent
    def call
      link_to t('blacklight.search.start_over'),
              start_over_path + "?search_field=all_fields",
              class: 'catalog_startOverLink btn btn-primary'
    end
  end
end
