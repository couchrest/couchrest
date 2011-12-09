module CouchRest
  class Design < Document

    def view_by *keys
      opts = keys.pop if keys.last.is_a?(Hash)
      opts ||= {}
      self['views'] ||= {}
      self['language'] ||= 'javascript'
      method_name = "by_#{keys.join('_and_')}"

      if opts[:map]
        view = {}
        view['map'] = opts.delete(:map)
        view['reduce'] = opts.delete(:reduce) if opts[:reduce]
        self['views'][method_name] = view
      else
        key_data = create_key_data keys
        doc_keys = key_data[:keys]
        key_emit = doc_keys.length == 1 ? "#{doc_keys.first}" : "[#{doc_keys.join(', ')}]"
        guards = opts.delete(:guards) || []
        guards += null_check(doc_keys) unless opts.delete(:allow_nil)
        guards << 'true' if guards.empty?
        self['views'][method_name] = {
          'map' => map_function(guards, key_data[:declarations], key_emit)
        }
      end
      self['views'][method_name]['couchrest-defaults'] = opts unless opts.empty?
      method_name
    end

    # Dispatches to any named view.
    # (using the database where this design doc was saved)
    def view view_name, query={}, &block
      view_on database, view_name, query, &block
    end

    # Dispatches to any named view in a specific database
    def view_on db, view_name, query = {}, &block
      raise ArgumentError, "View query options must be set as symbols!" if query.keys.find{|k| k.is_a?(String)}
      view_name = view_name.to_s
      view_slug = "#{name}/#{view_name}"
      # Set the default query options
      query = view_defaults(view_name).merge(query)
      # Ensure reduce is set if dealing with a reduceable view
      # This is a requirement of CouchDB.
      query[:reduce] ||= false if can_reduce_view?(view_name)
      db.view(view_slug, query, &block)
    end

    def name
      id.sub('_design/','') if id
    end

    def name= newname
      self['_id'] = "_design/#{newname}"
    end

    def save
      raise ArgumentError, "_design docs require a name" unless name && name.length > 0
      super
    end

    # Return the hash of default values to include in all queries sent
    # to a view from couchrest.
    def view_defaults(name)
      (self['views'][name.to_s] && self['views'][name.to_s]["couchrest-defaults"]) || {}
    end

    # Returns true or false if the view is available.
    def has_view?(name)
      !self['views'][name.to_s].nil?
    end

    # Check if the view has a reduce method defined.
    def can_reduce_view?(name)
      has_view?(name) && !self['views'][name.to_s]['reduce'].to_s.empty?
    end

    private

    def fetch_view view_name, opts, &block
      database.view(view_name, opts, &block)
    end
    
    def map_function guards, declarations, key_emit
      case self['language']
        when 'javascript'
          <<-JAVASCRIPT
function(doc) {
  if (#{guards.join(' && ')}) {
    emit(#{key_emit}, null);
  }
}
JAVASCRIPT
        when 'erlang'
          <<-ERLANG
fun({Doc}) ->
  #{declarations.join(', ')},
  if
    (#{guards.join(' and ')}) ->
      Emit(#{key_emit}, null);
    true ->
      ok
  end
end.
ERLANG
      end
    end
    
    def create_key_data keys
      case self['language']
        when 'javascript'
          {:keys => keys.map{|k| "doc['#{k}']"}}
        when 'erlang'
          declarations = keys.map{|k| "#{k.capitalize} = couch_util:get_value(<<\"#{k}\">>, Doc)"}
          keys = keys.map{|k| k.capitalize}
          {:keys => keys, :declarations => declarations}
      end
    end
    
    def null_check doc_keys
      case self['language']
        when 'javascript'
          doc_keys.map{|k| "(#{k} != null)"}
        when 'erlang'
          doc_keys.map{|k| "(#{k} /= null)"}
      end
    end
    
  end
end
