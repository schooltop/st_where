class SQLArray
  def initialize(sql)
    if sql.is_a?(Hash)
      @array = [sql, "AND", nil]
    elsif sql.is_a?(Array)
      @array = sql
    end
  end

  def to_s
    if @array[2]==nil
      @array[0]
    else
      if @array[0].blank?
        @array[2]
      else
        ["(", @array.join(" "), ")"].join
      end
    end
  end

  def to_sql(record=nil)
    if @array[2]==nil
      @array[0].to_sql(record)
    else
      sql_array = SQLArrayParam.new
      left_side, right_side = [@array[0].to_sql(record), @array[2].to_sql(record)]
      sql_array.merge!(left_side, right_side, @array[1])
      return sql_array.to_a
    end
  end

  def +(h)
    if h.is_a?(Hash)
      return SQLArray.new([self, "AND", h])
    elsif h.is_a?(SQLArray)
      return SQLArray.new([self, "AND", h])
    end
  end

  def -(h)
    if h.is_a?(Hash)
      return SQLArray.new([self, "OR", h])
    elsif h.is_a?(SQLArray)
      return SQLArray.new([self, "OR", h])
    end
  end
end