require_relative 'db_connection'
require_relative '00_attr_accessor_object'
require 'active_support/inflector'
require 'debugger'

class MassObject
  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end
end


class SQLObject < MassObject
  def self.columns
    return @column_names if @column_names

    column_names = DBConnection.execute2("SELECT * FROM #{table_name}").first
    
    column_names.each do |column|
      define_method("#{column}") { self.attributes[column] }
      define_method("#{column}=") { |arg| self.attributes[column] = arg }
    end

    @column_names = column_names.map(&:to_sym)
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.underscore.pluralize
  end

  def self.all
    self.parse_all(DBConnection.execute("SELECT * FROM #{table_name}"))
  end

  def self.find(id)
    new_obj = (DBConnection.execute("SELECT * FROM #{table_name} WHERE id = ?", id)).first
    self.new(new_obj)
  end

  def attributes
    @attributes ||= Hash.new
    @attributes
  end

  def insert
    col_names = self.attributes.keys.join(',') 
    question_marks = (['?'] * self.attributes.count).join(',')
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
    #{self.class.table_name} (#{col_names})
    VALUES
    (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params={})
    @columns = self.class.columns
    params.each do |attr_name, value|
      if @columns.include?(attr_name.to_sym)
        send("#{attr_name}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def save
    self.id.nil? ? insert : update
  end

  def update
    set_line = self.attributes.keys.map { |attr_name| "#{attr_name} = ?" }.join(',')
    DBConnection.execute(<<-SQL, *attribute_values)
    update
    #{self.class.table_name}
    SET
    #{set_line}
    WHERE
    id = #{self.id}
    SQL
  end

  def attribute_values
    self.attributes.keys.map { |attr_name| send("#{attr_name}") }
  end
end
