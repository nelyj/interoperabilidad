# Allows to declaratively specify how to extract search vectors
# (as expected by Searchable) from a hash structure.
#
# For example, given this:
#
#       keys = %w(title description name)
#       weights = {
#        /^info > title$/ => 'A',
#        /^info > description$/ => 'B',
#        /^paths > [^>]* > [^>]* > description$/ => 'C',
#        /^paths > [^>]* > [^>]* > responses > [^>]* > description$/ => 'C',
#        /^.*$/ => 'D', # default to D weight
#      }
#
# Then:
#
#      HashSearchVectorExtractor.new(keys, weights).search_vectors(my_hash)
#
# Will recursively search for hash keys 'title', 'description' and 'name'
# and will return a vector with weight 'A' for the value on
# my_hash['info']['title'] (if found), weight 'B' for the value on
# my_hash['info']['description'] (if found), weight 'C' for any value
# within my_hash['paths'][*anything*][*anything*]['description'] or
# within my_hash['paths'][*anything*][*anything*]['responses'][*anything]['description']
# and weight D for any other match on the hash keys
# ('title', 'description', 'name')
#
# [We use this to extract searchable pieces from OpenAPI Specification files
# which have been parsed into Ruby hashes]

class HashSearchVectorExtractor
  def initialize(keys_to_search_for, weights)
    @keys_to_search_for = keys_to_search_for
    @weights = weights
  end

  def search_vectors(hash)
    matches = deep_find_strings(hash, @keys_to_search_for)
    matches.map do |path, text|
      string_path = path.join(" > ")
      match_weight = nil
      @weights.each do |pattern, weight|
        if string_path =~ pattern
          match_weight = weight
          break
        end
      end
      if match_weight.nil?
        raise new ArgumentError(
          "Match on #{string_path} has no weight specified")
      end
      Searchable::SearchVector.new(text, match_weight)
    end
  end

  # Recursively searches for certain keys on a given Hash and any
  # Hash or Array contained on it.
  #
  # returns an array of pairs [path, value] where path is itself
  # an array of the keys traversed to find the match
  # (no additional element is added to the path when traversing arrays)
  def deep_find_strings(hash, keys_to_search_for, current_path = nil)
    current_path ||= []
    results = []
    hash.each do |key, value|
      if value.is_a?(String) && keys_to_search_for.include?(key)
        results << [current_path + [key], value]
      elsif value.is_a? Hash
        results.concat(deep_find_strings(
          value, keys_to_search_for, current_path + [key]
        ))
      elsif value.is_a? Array
        value.select{|e| e.is_a?(Hash)}.each do |subhash|
          results.concat(deep_find_strings(
            subhash, keys_to_search_for, current_path + [key]
          ))
        end
      end
    end
    results
  end
end
