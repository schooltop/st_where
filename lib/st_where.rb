require 'st_where/associations'
require 'st_where/conditions'
require 'st_where/sql_logic'
require "st_where/version"

module StWhere
  include StWhere::Associations
  include StWhere::Conditions
  include StWhere::SqlLogic
end

ActiveRecord::Base.extend(StWhere)

