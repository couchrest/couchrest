module CouchRest
  module Mixins
    module AttributeProtection
      # Attribute protection from mass assignment to CouchRest properties
      # 
      # Protected methods will be removed from
      #  * new 
      #  * update_attributes
      #  * upate_attributes_without_saving
      #  * attributes=
      #  
      # There are two modes of protection
      #  1) Declare accessible poperties, assume all the rest are protected 
      #    property :name, :accessible => true
      #    property :admin                     # this will be automatically protected
      #
      #  2) Declare protected properties, assume all the rest are accessible
      #    property :name                      # this will not be protected
      #    property :admin, :protected => true
      #
      # Note: you cannot set both flags in a single class
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def accessible_properties
          properties.select { |prop| prop.options[:accessible] }
        end

        def protected_properties
          properties.select { |prop| prop.options[:protected] }
        end
      end

      def accessible_properties
        self.class.accessible_properties
      end

      def protected_properties
        self.class.protected_properties
      end

      def remove_protected_attributes(attributes)
        protected_names = properties_to_remove_from_mass_assignment.map { |prop| prop.name }
        return attributes if protected_names.empty?

        attributes.reject! do |property_name, property_value|
          protected_names.include?(property_name.to_s)
        end

        attributes || {}
      end

      private

      def properties_to_remove_from_mass_assignment
        has_protected = !protected_properties.empty?
        has_accessible = !accessible_properties.empty?

        if !has_protected && !has_accessible
          []
        elsif has_protected && !has_accessible
          protected_properties
        elsif has_accessible && !has_protected
          properties.reject { |prop| prop.options[:accessible] }
        else
          raise "Set either :accessible or :protected for #{self.class}, but not both"
        end
      end
    end
  end
end
