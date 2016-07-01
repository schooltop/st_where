module StWhere
    module SqlLogic
      def get_sql(sql_array)
        sql_array = SQLArray.new(sql_array) if sql_array.is_a?(Hash)
        raise ArgumentError.new("Argument Error!") unless sql_array.is_a?(SQLArray)

        return sql_array.to_sql(self)
      end

      def st_where(sql_hash, options={})
        options[:skip_blank]||=true
        options[:strip]||=true
        raise ArgumentError.new("Argument Error!") unless sql_hash.is_a?(Hash)
        sql_hash.delete_if{|key, value| value.blank?} if options[:skip_blank]
        sql_hash.each{|key, value| sql_hash[key] = value.strip if value.respond_to?(:strip)} if options[:strip]
        if sql_hash.blank?
          return nil
        end
        get_sql(sql_hash)
      end

      def table_name_without_schema
        self.table_name.include?(".") ? self.table_name.split(".").last : self.table_name
      end

      def get_sql_by_key_value(key, value)
        #key_method = "#{key}".to_sym
        associations = reflect_on_all_associations.collect { |assoc| assoc.name }
        if key.to_s =~ /^(#{column_names.join("|")})_(#{Conditions::PRIMARY_CONDITIONS.join("|")})$/ or key.to_s =~ /^(#{associations.join("|")})_(\w+)_(#{Conditions::PRIMARY_CONDITIONS.join("|")})$/
          key_method = "#{key}_to_sql".to_sym
          return self.send(key_method, value)
          #if self.respond_to?(key_method)
          sql = "#{self.table_name_without_schema}.#{key} = :#{key} "
          return [sql, {key_method=>value}]
          #return self.send(key_method, value)
          #else
          #  raise ArgumentError.new("Cannnot find #{key} method!")
          #end
        else
          return nil
        end
    end
end