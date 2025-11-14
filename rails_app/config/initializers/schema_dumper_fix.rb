# config/initializers/schema_dumper_thaw.rb
ActiveSupport.on_load(:active_record) do
  module ColumnDumperThaw
    def prepare_column_options(column, types)
      spec = super
      if spec.key?(:default) && spec[:default].is_a?(String)
        spec = spec.dup
        spec[:default] = spec[:default].dup
      end
      spec
    end
  end

  ActiveRecord::ConnectionAdapters::ColumnDumper.prepend ColumnDumperThaw
end
