class Article < CouchRest::ExtendedDocument
  use_database DB
  unique_id :slug
  
  provides_collection :article_details, 'Article', 'by_date', :descending => true, :include_docs => true
  view_by :date, :descending => true
  view_by :user_id, :date
    
  view_by :tags,
    :map => 
      "function(doc) {
        if (doc['couchrest-type'] == 'Article' && doc.tags) {
          doc.tags.forEach(function(tag){
            emit(tag, 1);
          });
        }
      }",
    :reduce => 
      "function(keys, values, rereduce) {
        return sum(values);
      }"  

  property :date
  property :slug, :read_only => true
  property :title
  property :tags

  timestamps!
  
  before_save :generate_slug_from_title
  
  def generate_slug_from_title
    self['slug'] = title.downcase.gsub(/[^a-z0-9]/,'-').squeeze('-').gsub(/^\-|\-$/,'') if new?
  end
end
