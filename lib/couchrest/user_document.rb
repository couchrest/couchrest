require 'uuid'
require 'digest/sha1'

module CouchRest  
  class UserDocument < Document
    def initialize(username, password, roles = [])
      super(UserDocument.create_user_doc(username, password, roles))
    end
    
    private
    
    def self.create_user_doc(username, password, roles = [])
      doc = {
        :name => username,
        :_id => "org.couchdb.user:" + username,
        :type => "user",
        :roles => (roles || [])
      }
      if !password.nil?
        doc[:salt] = UUID.generate
        doc[:password_sha] = Digest::SHA1.hexdigest(password + doc[:salt])
      end
      return doc
    end
  end
end
