module StWhere
    module Associations

        def primary_condition_name(name) # :nodoc:
          if result = super
            result
          elsif association_condition?(name)
            name.to_sym
          elsif details = association_alias_condition_details(name)
            "#{details[:association]}_#{details[:column]}_#{primary_condition(details[:condition])}".to_sym
          else
            nil
          end
        end

        # Is the name of the method a valid name for an association condition?
        def association_condition?(name)
          !association_condition_details(name).nil?
        end

        # Is the ane of the method a valie name for an association alias condition?
        # An alias being "gt" for "greater_than", etc.
        def association_alias_condition?(name)
          !association_alias_condition_details(name).nil?
        end

        private
        def method_missing(name, *args, &block)
          if details = association_condition_details(name)
            create_association_condition(details[:association], details[:column], details[:condition], args)
          else
            super
          end
        end

        def association_condition_details(name)
          associations = reflect_on_all_associations.collect { |assoc| assoc.name }
          if name.to_s =~ /^(#{associations.join("|")})_(\w+)_(#{Conditions::PRIMARY_CONDITIONS.join("|")})_to_sql$/
            {:association => $1, :column => $2, :condition => $3}
          end
        end

        def create_association_condition(association_name, column, condition, args)
          #named_scope("#{association_name}_#{column}_#{condition}", association_condition_options(association_name, "#{column}_#{condition}", args))
          values = args
          association = reflect_on_association(association_name.to_sym)
          association_method = "#{column}_#{condition}_to_sql"
          result = association.klass.send(association_method, *args)
        end
      end
    end
end  