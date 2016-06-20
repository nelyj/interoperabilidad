# Implements a .search class method on the class which includes
# this method, using PostgreSQL full text search capabilities
#
# It requires the corresponding table to have a `lexemes` column of
# type `tsvector`. It also needs a `#text_search_vectors` method to be
# implemented on the including class and to return an array of
# `Searchable::SearchVector` with the texts to index and their weight
# ('A', 'B', 'C' or 'D'; 'A' is the highest weight).
#
# Searchable automatically rebuilds the index after the record is saved.
# But if you need to rebuild it because another (related) record changed,
# you should manually call the `#update_search_metadata` method.
#
#
module Searchable
  extend ActiveSupport::Concern

  class SearchVector < Struct.new(:document, :weight)
  end

  def self.search_configuration
   if Rails.env.test? # Migrations don't run on test database :(
     "spanish"
   else
     "es"
   end
  end

  included do
    after_save :update_search_metadata
  end

  class_methods do
    def search(text)
      query = <<-SQL
       SELECT #{table_name}.*
       FROM #{table_name}, plainto_tsquery(?, ?) as search_text
       WHERE (lexemes @@ search_text)
       ORDER BY ts_rank(lexemes, search_text) DESC;
      SQL
      find_by_sql [query, Searchable.search_configuration, text]
    end
  end

  def update_search_metadata
    search_vector_sql = text_search_vectors.map do |search_vector|
      "setweight(to_tsvector(
       #{ActiveRecord::Base.sanitize(Searchable.search_configuration)},
       #{ActiveRecord::Base.sanitize(search_vector.document)}),
       #{ActiveRecord::Base.sanitize(search_vector.weight)}
      )"
    end.join("||")

    ActiveRecord::Base.connection.execute <<-SQL
     UPDATE #{self.class.table_name}
     SET lexemes = #{search_vector_sql}
     WHERE #{self.class.table_name}.id = #{ActiveRecord::Base.sanitize(self.id)}
    SQL
  end
end
