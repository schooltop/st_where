class SQLArrayParam
  def initialize(param = nil)
    @param_ary ||= ["", {}]
    @param_ary = param.to_a if param
  end

  def to_a
    @param_ary
  end

  def sql
    @param_ary[0]
  end

  def sql=(value)
    @param_ary[0]=value
  end

  def sql_params
    @param_ary[1]
  end

  def sql_params=(value)
    @param_ary[1]=value
  end

  def add(param, connector = "AND")
    data = pre_add(param)
    self.sql+=((self.sql.blank? ? "" : " #{connector} ") + data.sql)
    self.sql_params.merge!(data.sql_params)
    return self
  end

  def pre_add(param)
    param = SQLArrayParam.new(param) if param.is_a?(Array)
    new_sql = param.sql
    new_param = {}
    param.sql_params.each do |key, value|
      new_key = valid_key(key)
      if new_key!=key
        new_sql.gsub!(Regexp.new(":#{key}\\b"), ":#{new_key}")
      end
      new_param.merge!({new_key=>value})
    end
    return SQLArrayParam.new([new_sql, new_param])
  end

  def merge!(param, param1, connector = "AND")
    param = SQLArrayParam.new(param) if param.is_a?(Array)
    param1 = SQLArrayParam.new(param1) if param1.is_a?(Array)
    data = pre_add(param)
    self.sql_params.merge!(data.sql_params)
    data1 = pre_add(param1)
    self.sql_params.merge!(data1.sql_params)
    if data.sql.blank?
      self.sql += data1.sql
    else
      self.sql += ["(", data.sql, " #{connector} ", data1.sql, ")"].join
    end

    return true
  end

  def valid_key(key, i=0)
    if self.sql_params.keys.include?(key)
      return valid_key("#{key}_#{i}".to_sym, i+1)
    else
      return key
    end
  end
end