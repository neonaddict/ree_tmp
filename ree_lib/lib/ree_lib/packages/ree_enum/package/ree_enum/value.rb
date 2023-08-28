# frozen_string_literal: true

class ReeEnum::Value
  attr_reader :enum_class, :enum_name, :value, :method, :mapped_value

  contract(Class, Symbol, String, Or[Integer, String], Symbol => Any)
  def initialize(enum_class, enum_name, value, mapped_value, method)
    @enum_class = enum_class
    @enum_name = enum_name
    @value = value
    @method = method
    @mapped_value = mapped_value
  end

  def to_s
    value
  end

  def as_json(*args)
    to_s
  end

  contract(Or[ReeEnum::Value, String, Symbol, Integer, Any] => Bool)
  def ==(compare)
    if compare.is_a?(self.class)
      value == compare.value
    elsif compare.is_a?(Symbol)
      value == compare.to_s
    elsif compare.is_a?(String)
      value == compare || mapped_value == compare
    elsif compare.is_a?(Integer)
      mapped_value == compare
    else
      false
    end
  end

  def inspect
    "#{enum_class.name}##{value}"
  end
end