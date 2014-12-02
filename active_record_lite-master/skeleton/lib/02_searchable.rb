require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = []
    values = []
    p params
    params.keys.each do |key|
       where_line << "#{key} = ?"
       values << params[key]
    end
    where_line = where_line.join('AND ')
    p where_line
    p values
    results =DBConnection.execute(<<-SQL, *values)
      SELECT
        "#{self.table_name}".*
      FROM
        "#{self.table_name}"
      WHERE
        #{where_line}

    SQL
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
