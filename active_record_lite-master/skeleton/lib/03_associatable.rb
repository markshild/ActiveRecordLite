require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
  model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      :class_name => "#{name.to_s.singularize.camelcase}",
      :primary_key => :id,
      :foreign_key => "#{name}_id".to_sym
    }
    defaults.merge!(options)
    defaults.keys.each do |key|
      self.send("#{key}=", defaults[key])
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      :class_name => "#{name.to_s.singularize.camelcase}",
      :primary_key => :id,
      :foreign_key => "#{self_class_name.to_s.downcase}_id".to_sym
    }
    defaults.merge!(options)
    defaults.keys.each do |key|
      self.send("#{key}=", defaults[key])
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      key = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => key).first
    end
    nil
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      key = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => key)
    end
    nil
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
