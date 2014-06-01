require_relative '03_searchable'
require 'active_support/inflector'
require 'debugger'

# Phase IVa
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
    options = { :foreign_key => "#{name.to_s.underscore}_id".to_sym,
                :class_name => name.to_s.camelcase.singularize,
                :primary_key => :id }.merge(options)

    options.keys.each { |key| self.send("#{key}=", options[key]) }
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options = { :foreign_key => "#{self_class_name.to_s.underscore}_id".to_sym,
                :class_name => name.to_s.camelcase.singularize,
                :primary_key => :id }.merge(options)

    options.keys.each { |key| self.send("#{key}=", options[key]) }
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    assoc_options[name] = options

    define_method("#{name.to_s}") do
      foreign_key = send(options.foreign_key)
      return options.model_class.where(options.primary_key => foreign_key).first
    end

  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)

    define_method("#{name.to_s}") do
      primary_key = send(options.primary_key)
      return options.model_class.where(options.foreign_key => primary_key)
    end      
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
