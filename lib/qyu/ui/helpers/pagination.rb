# frozen_string_literal: true

module Qyu
  module Helpers
    module Pagination
      class PaginatableArray < Array
        attr_accessor :limit, :offset, :total_count, :page

        def initialize(collection, limit:, offset:, total_count:, page:)
          @limit = limit
          @offset = offset
          @total_count = total_count
          @page = page
          super(collection)
        end

        def total_pages
          @total_pages ||= total_count / limit
        end
      end

      def previous_pages_for(collection)
        return [] if collection.page < 2
        start_page = [collection.page - 3, 1].max
        start_page.upto(collection.page - 1)
      end

      def next_pages_for(collection)
        return [] if collection.page == collection.total_pages
        end_page = [collection.total_pages, collection.page + 3].min
        (collection.page + 1).upto(end_page)
      end
    end
  end
end
