# This file contains various hacks for Rails compatibility.
class Hash
  # Hack so that CouchRest::Document, which descends from Hash,
  # doesn't appear to Rails routing as a Hash of options
  def self.===(other)
    return false if self == Hash && other.is_a?(CouchRest::Document)
    super
  end
end

CouchRest::Document.class_eval do
  # Need this when passing doc to a resourceful route
  alias_method :to_param, :id

  # Hack so that CouchRest::Document, which descends from Hash,
  # doesn't appear to Rails routing as a Hash of options
  def is_a?(o)
    return false if o == Hash
    super
  end
  alias_method :kind_of?, :is_a?
end

CouchRest::CastedModel.class_eval do
  # The to_param method is needed for rails to generate resourceful routes.
  # In your controller, remember that it's actually the id of the document.
  def id
    return nil if base_doc.nil?
    base_doc.id
  end
  alias_method :to_param, :id
end

require Pathname.new(File.dirname(__FILE__)).join('..', 'validation', 'validation_errors')

CouchRest::Validation::ValidationErrors.class_eval do
  # Returns the total number of errors added. Two errors added to the same attribute will be counted as such.
  # This method is called by error_messages_for
  def count
    errors.values.inject(0) { |error_count, errors_for_attribute| error_count + errors_for_attribute.size }
  end
end
