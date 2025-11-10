# frozen_string_literal: true
# Patch column dumper for Rails 4.2 with Ruby 2.7
# Addresses:
#   Could not dump table "x" because of following FrozenError
#   can't modify frozen String: "false"

# Fix for FrozenError in schema.rb generation with Ruby 2.7+
if Rails.version.start_with?("4.2")
  require "active_record/schema_dumper"

  module ActiveRecord
    class SchemaDumper
      private

      def default_string(column)
        return unless column.has_default?

        # The issue is that column.default can be a frozen string
        # and the original code tries to modify it in place
        default = column.default

        if default.is_a?(String)
          default = default.dup # Create a mutable copy
        end

        case default
        when BigDecimal
          default.to_s
        when String
          default.inspect
        when Date, DateTime, Time
          "'#{default.to_s(:db)}'"
        else
          default.inspect
        end
      end
    end
  end
end

