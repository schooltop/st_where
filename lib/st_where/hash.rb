class Hash

  def +(h)
    return SQLArray.new([self, "AND", h])
  end

  def -(h)
    return SQLArray.new([self, "OR", h])
  end

  def delete_blank!
    self.delete_if{|key, value| value.blank?}
  end

  def to_s
    return self.inspect
  end

  def to_sql(record=nil)
    sql_with_params = []
    self.each do |key, value|
      if record
        sql_p = record.get_sql_by_key_value(key, value)
        sql_with_params << sql_p if sql_p
      else
        sql_with_params << ["#{key} = #{value}", {}]
      end
    end
    sql_array = SQLArrayParam.new
    sql_with_params.each do |sp|
      sql_array.add(sp)
    end
    if sql_with_params.size>1
      sql = ["(", sql_array.sql, ")"].join
    else
      sql = sql_array.sql
    end
    return [sql, sql_array.sql_params]
  end
end