module CouchRest  
  class Design < Document
    def view_by *keys
      # @stale = true
      opts = keys.pop if keys.last.is_a?(Hash)
      opts ||= {}
      self['views'] ||= {}
      method_name = "by_#{keys.join('_and_')}"
      
      if opts[:map]
        view = {}
        view['map'] = opts.delete(:map)
        if opts[:reduce]
          view['reduce'] = opts.delete(:reduce)
          opts[:reduce] = false
        end
        self['views'][method_name] = view
      else
        doc_keys = keys.collect{|k|"doc['#{k}']"} # this is where :require => 'doc.x == true' would show up
        key_emit = doc_keys.length == 1 ? "#{doc_keys.first}" : "[#{doc_keys.join(', ')}]"
        guards = doc_keys
        map_function = <<-JAVASCRIPT
        function(doc) {
          if (#{guards.join(' && ')}) {
            emit(#{key_emit}, null);
          }
        }
        JAVASCRIPT
        self['views'][method_name] = {
          'map' => map_function
        }
        method_name
      end
    end

    # def method_missing m, *args
    #   if opts = has_view?(m)
    #     query = args.shift || {}
    #     view(m, opts.merge(query), *args)
    #   else
    #     super
    #   end
    # end

    # Dispatches to any named view.
    def view name, query={}, &block
      # if @stale
      #   self.save
      # end
      view_name = "#{slug}/#{name}"
      fetch_view(view_name, query, &block)
    end

    def slug
      id.sub('_design/','')
    end

    def slug= newslug
      self['_id'] = "_design/#{newslug}"
    end

    def save
      raise ArgumentError, "_design" unless slug && slug.length > 0
      super
    end

    private

    # returns stored defaults if the there is a view named this in the design doc
    def has_view?(view)
      view = view.to_s
      self['views'][view] &&
        (self['views'][view]["couchrest-defaults"]||{})
    end

    # def fetch_view_with_docs name, opts, raw=false, &block
    #   if raw
    #     fetch_view name, opts, &block
    #   else
    #     begin
    #       view = fetch_view name, opts.merge({:include_docs => true}), &block
    #       view['rows'].collect{|r|new(r['doc'])} if view['rows']
    #     rescue
    #       # fallback for old versions of couchdb that don't 
    #       # have include_docs support
    #       view = fetch_view name, opts, &block
    #       view['rows'].collect{|r|new(database.get(r['id']))} if view['rows']
    #     end
    #   end
    # end

    def fetch_view view_name, opts, &block
      database.view(view_name, opts, &block)
    end

  end
  
end