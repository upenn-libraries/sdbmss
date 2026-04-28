# frozen_string_literal: true

# OVERRIDE Blacklight 9.0.0 BookmarkComponent to use the app Bookmark model
#   and Entry model_object via bookmarks/_add and bookmarks/_delete partials.

module SDBMSS
  module Document
    class BookmarkComponent < ::Blacklight::Document::BookmarkComponent
      delegate :current_user, to: :helpers

      def render?
        current_user.present?
      end

      def bookmark
        @bookmark ||= current_user.bookmarks.find_by(document: @document.model_object)
      end

      def model_object
        @document.model_object
      end
    end
  end
end
