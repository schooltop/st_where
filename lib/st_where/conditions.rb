module StWhere
    module Conditions
        COMPARISON_CONDITIONS = {
                :equals => [:is, :eq],
                :eq => [],
                :does_not_equal => [:not_equal_to, :is_not, :not, :neq],
                :neq => [],
                :less_than => [:lt, :before],
                :lt => [], :lte=>[],
                :less_than_or_equal_to => [:lte],
                :greater_than => [:gt, :after],
                :gt=>[], :gte=>[],
                :in=>[], :not_in=>[],
                :greater_than_or_equal_to => [:gte],
                }

        WILDCARD_CONDITIONS = {
                :like => [:contains, :includes],
                :begins_with => [:bw],
                :ends_with => [:ew],
                :full_text=> []
                }

        BOOLEAN_CONDITIONS = {
                :null => [:nil],
                :empty => []
        }

        CONDITIONS = {}

        COMPARISON_CONDITIONS.merge(WILDCARD_CONDITIONS).each do |condition, aliases|
          CONDITIONS[condition] = aliases
        end

        BOOLEAN_CONDITIONS.each { |condition, aliases| CONDITIONS[condition] = aliases }

        PRIMARY_CONDITIONS = CONDITIONS.keys
        ALIAS_CONDITIONS = CONDITIONS.values.flatten

        # Returns the primary condition for the given alias. Ex:
        #
        #   primary_condition(:gt) => :greater_than
        def primary_condition(alias_condition)
          CONDITIONS.find { |k, v| k == alias_condition.to_sym || v.include?(alias_condition.to_sym) }.first
        end

        def primary_condition_name(name)
          if primary_condition?(name)

            name.to_sym
          elsif details = alias_condition_details(name)
            "#{details[:column]}_#{primary_condition(details[:condition])}".to_sym
          else
            nil
          end
        end

        def primary_condition?(name)
          !primary_condition_details(name).nil?
        end

        private
        def method_missing(name, *args, &block)
          if details = primary_condition_details(name)
            get_sql_and_params(details[:column], details[:condition], args)
          else
            super
          end
        end

        def primary_condition_details(name)
          if name.to_s =~ /^(#{column_names.join("|")})_(#{PRIMARY_CONDITIONS.join("|")})_to_sql$/
            {:column => $1, :condition => $2}
          end
        end

        def get_sql_and_params(column, condition, args)
          column_type = columns_hash[column.to_s].type
          case condition.to_s
            when /^equals/, /^eq/
              condition_sql(condition, column, column_type, "#{table_name_without_schema}.#{column} = ?", args)
            when /^does_not_equal/, /^noteq/, /^neq/
              condition_sql(condition, column, column_type, "#{table_name_without_schema}.#{column} != ?", args)
            when /^less_than_or_equal_to/, /^lte/
              condition_sql(condition, column, column_type, "#{table_name_without_schema}.#{column} <= ?", args, :lte)
            when /^less_than/, /^lt/
              condition_sql(condition, column, column_type, "#{table_name_without_schema}.#{column} < ?", args, :lt)
            when /^greater_than_or_equal_to/, /^gte/
              condition_sql(condition, column, column_type, "#{table_name_without_schema}.#{column} >= ?", args, :gte)
            when /^greater_than/, /^gt/
              condition_sql(condition, column, column_type, "#{table_name_without_schema}.#{column} > ?", args, :gt)
            when /^like/
              condition_sql(condition, column, column_type, "lower(#{table_name_without_schema}.#{column}) LIKE ?", args, :like)
            when /^begins_with/
              condition_sql(condition, column, column_type, "lower(#{table_name_without_schema}.#{column}) LIKE ?", args, :begins_with)
            when /^ends_with/
              condition_sql(condition, column, column_type, "lower(#{table_name_without_schema}.#{column}) LIKE ?", args, :ends_with)
            when /^in/
              condition_sql(condition, column, column_type, "#{table_name_without_schema}.#{column} IN (?)", args)
            when /^not_in/
              condition_sql(condition, column, column_type, "#{table_name_without_schema}.#{column} NOT IN (?)", args)
            when /^full_text/
              condition_sql(condition, column, column_type, "CONTAINS(#{table_name_without_schema}.#{column}, ?) > 0", args)
            when "null"
              return ["#{table_name_without_schema}.#{column} IS NULL", {}]
            when "empty"
              return ["#{table_name_without_schema}.#{column} = ''", {}]
          end
        end

        def condition_sql(condition, column, column_type, sql, args, value_modifier = nil)
          case condition.to_s
            when /_(any|all)$/
              #TODO
              values = args
              return ["", {}] if values.empty?
              values = values.flatten

              values_to_sub = nil
              if value_modifier.nil?
                values_to_sub = values
              else
                values_to_sub = values.collect { |value| value_with_modifier(value, value_modifier, column_type) }
              end

              join = $1 == "any" ? " OR " : " AND "
              _sql = [values.collect { |value| sql }.join(join), *values_to_sub]
            else
              value = args[0]
              column_symbol = column_key_symbol(column)
              _sql = sql.gsub("?", column_symbol_in_sql(column_symbol, column_type))
              return [_sql, {column_symbol.to_sym=>value_with_modifier(value, value_modifier, column_type)}]
          end
        end

        def column_key_symbol(column)
          [self.table_name_without_schema, column].join("_")
        end

        def column_symbol_in_sql(column, column_type)
          case column_type
            when :datetime
              ":#{column}"
            else
              ":#{column}"
          end
        end

        def value_with_modifier(value, modifier, column_type)
          case column_type
            when :datetime
              if [:gt, :gte].include?(modifier)
                return fill_date(value, '00:00:00')
              elsif [:lt, :lte].include?(modifier)
                return fill_date(value, '23:59:59')
              end
          end
          case modifier
            when :like
              "%#{value.downcase}%"
            when :begins_with
              "#{value.downcase}%"
            when :ends_with
              "%#{value.downcase}"
            else
              value
          end
        end

        def fill_date(date, time)
          if date.is_a?(String)
            if date.size==10
              new_date = Time.parse([date, time].join(" "))
              return new_date.label
            else
              new_date = Time.parse(date)
              return new_date.label
            end
          elsif date.is_a?(Time)
            return date.label
          else
            return date.to_s
          end
        end
    end
end