require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    cols = (DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL
    )
    @columns = cols[0].map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end
    end

    self.columns.each do |col|
      define_method("#{col}=") do |value|
        self.attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.underscore.pluralize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
      SQL
    parse_all(results).first
  end

  def initialize(params = {})
    params.each do |attr, value|
      attr_name = attr.to_sym
      if self.class.columns.include?(attr_name)
        self.send("#{ attr_name }=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |attr| self.send(attr) }
  end

  def insert
    col_names = self.class.columns.map(&:to_s).join(', ')
    q_marks = (['?']*self.class.columns.count).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{ self.class.table_name } (#{ col_names })
      VALUES
        (#{ q_marks })
      SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set = self.class.columns.map { |col| "#{ col } = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{ self.class.table_name }
      SET
        #{set}
      WHERE
      #{ self.class.table_name }.id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
