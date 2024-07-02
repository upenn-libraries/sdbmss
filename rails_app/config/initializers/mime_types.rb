# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

ActionController::Renderers.add :csv do |obj, options|
  self.headers['Content-Disposition'] = "attachment; filename=#{options[:filename]}"
  self.headers['Content-Type'] = 'text/csv'
  self.content_type ||= Mime::Type.lookup('text/csv')
  self.response_body = SDBMSS::Util.objects_to_csv(options[:headers], obj) do |object|
    options[:format].call(object)
  end
end
