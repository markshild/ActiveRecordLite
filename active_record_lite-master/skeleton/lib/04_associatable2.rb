require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
  

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_tbl = through_options.table_name
      through_pk = through_options.primary_key
      through_fk = through_options.foreign_key

      source_tbl = source_options.table_name
      source_pk = source_options.primary_key
      source_fk = source_options.foreign_key

      key = self.send(through_fk)
      results = DBConnection.execute(<<-SQL, key)
      SELECT
        #{source_tbl}.*
      FROM
        #{through_tbl}
      JOIN
        #{source_tbl} ON #{source_tbl}.#{source_pk} = #{through_tbl}.#{source_fk}
      WHERE
        #{through_tbl}.#{through_pk} = ?
        SQL

      source_options.model_class.parse_all(results).first
    end

  end
end
