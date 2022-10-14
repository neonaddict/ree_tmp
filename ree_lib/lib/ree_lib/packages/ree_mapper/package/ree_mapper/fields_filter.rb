# frozen_string_literal: true

class ReeMapper::FieldsFilter
  class OnlyStrategy
    def initialize(only, except)
      @fields = Set.new

      only.each do |item|
        if item.is_a? Symbol
          @fields << item
        else
          item.each do |key, val|
            @fields << key
          end
        end
      end

      if !except.nil?
        except.each do |item|
          if item.is_a? Symbol
            @fields.delete item
          else
            item.each do |key, val|
              @fields.delete key
            end
          end
        end
      end
    end

    def allow?(field)
      fields.include? field
    end

    private
    attr_reader :fields
  end

  class ExceptStrategy
    def initialize(except)
      @fields = Set.new

      except&.each do |item|
        if item.is_a? Symbol
          @fields << item
        end
      end
    end

    def allow?(field)
      !fields.include?(field)
    end

    private
    attr_reader :fields
  end

  class NoneStrategy
    def self.allow?(field)
      true
    end
  end

  def self.empty_filter
    @empty_filter ||= new(NoneStrategy, {}).freeze
  end

  contract Nilor[ReeMapper::FilterFieldsContract], Nilor[ReeMapper::FilterFieldsContract] => Any
  def self.build(only:, except:)
    return empty_filter if only.nil? && except.nil?

    strategy = if !only.nil?
      OnlyStrategy.new(only, except)
    elsif !except.nil?
      ExceptStrategy.new(except)
    else
      NoneStrategy
    end

    nested_fields_filters = {}
    
    only = only&.select { _1.is_a? Hash }&.reduce(&:merge)
    except = except&.select { _1.is_a? Hash }&.reduce(&:merge)

    only&.each { nested_fields_filters[_1] = build(only: _2, except: except&.dig(_1)) }
    except&.each { nested_fields_filters[_1] ||= build(only: nil, except: _2) }

    new(strategy, nested_fields_filters)
  end

  def initialize(strategy, nested_fields_filters)
    @strategy              = strategy
    @nested_fields_filters = nested_fields_filters
  end

  def allow?(field)
    strategy.allow?(field)
  end

  def filter_for(field)
    nested_fields_filters.fetch(field, self.class.empty_filter)
  end

  private
  attr_reader :strategy, :nested_fields_filters
end