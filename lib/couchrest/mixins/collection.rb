module CouchRest
  module Mixins
    module Collection
  
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def provides_collection(collection_name, collection_options)
          class_eval <<-END, __FILE__, __LINE__ + 1
            def self.find_all_#{collection_name}(options = {})
              view_name = "#{collection_options[:through][:view_name]}"
              view_options = #{collection_options[:through][:view_options].inspect} || {}
              CollectionProxy.new(@database, view_name, view_options.merge(options), Kernel.const_get('#{self}'))
            end
          END
        end

        def paginate(options)
          proxy = create_collection_proxy(options)
          proxy.paginate(options)
        end

        def paginated_each(options, &block)
          proxy = create_collection_proxy(options)
          proxy.paginated_each(options, &block)
        end

        private

        def create_collection_proxy(options)
          view_name, view_options = parse_view_options(options)
          CollectionProxy.new(@database, view_name, view_options, self)
        end

        def parse_view_options(options)
          raise ArgumentError, 'parameter hash expected' unless options.respond_to? :symbolize_keys
          options = options.symbolize_keys

          view_name = options.delete(:view_name)
          raise ArgumentError, 'view_name is required' if view_name.nil?

          view_options = options.delete(:view_options) || {}

          [view_name, view_options]
        end
      end

      class CollectionProxy
        alias_method :proxy_respond_to?, :respond_to?
        instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^object_id$)/ }

        def initialize(database, view_name, view_options = {}, container_class = nil)
          @container_class = container_class
          @database = database
          @view_name = view_name
          @view_options = view_options
        end

        def paginate(options = {})
          page, per_page = parse_options(options)
          rows = @database.view(@view_name, @view_options.merge(pagination_options(page, per_page)))['rows']
          convert_to_container_array(rows)
        end

        def paginated_each(options = {}, &block)
          page, per_page = parse_options(options)

          begin
            collection = paginate({:page => page, :per_page => per_page})
            collection.each(&block)
            page += 1
          end until collection.size < per_page
        end

        def respond_to?(*args)
          proxy_respond_to?(*args) || (load_target && @target.respond_to?(*args))
        end

        # Explicitly proxy === because the instance method removal above
        # doesn't catch it.
        def ===(other)
          load_target
          other === @target
        end

        private

        def method_missing(method, *args)
          if load_target
            if block_given?
              @target.send(method, *args)  { |*block_args| yield(*block_args) }
            else
              @target.send(method, *args)
            end
          end
        end

        def load_target
          unless loaded?
            rows = @database.view(@view_name, @view_options)['rows']
            @target = convert_to_container_array(rows)
          end
          @loaded = true
          @target
        end

        def loaded?
          @loaded
        end

        def reload
          reset
          load_target
          self unless @target.nil?
        end

        def reset
          @loaded = false
          @target = nil
        end

        def inspect
          load_target
          @target.inspect
        end

        def convert_to_container_array(rows)
          return rows if @container_class.nil?

          container = []
          rows.each { |row| container << @container_class.new(row['value']) } unless rows.nil?
          container
        end

        def pagination_options(page, per_page)
          { :limit => per_page, :skip => per_page * (page - 1) }
        end

        def parse_options(options)
          raise ArgumentError, 'parameter hash expected' unless options.respond_to? :symbolize_keys
          options = options.symbolize_keys

          page = options[:page] || 1
          per_page = options[:per_page] || 30
          [page, per_page]
        end
      end

    end
  end
end