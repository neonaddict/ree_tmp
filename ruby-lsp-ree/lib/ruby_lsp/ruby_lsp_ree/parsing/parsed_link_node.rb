require 'prism'

class RubyLsp::Ree::ParsedLinkNode
  attr_reader :node, :document_package, :name, :imports

  FROM_ARG_KEY = 'from'
  IMPORT_ARG_KEY = 'import'

  def initialize(node, document_package = nil)
    @node = node
    @document_package = document_package
    @name = parse_name
  end

  def link_package_name
    from_arg_value || document_package
  end

  def location
    @node.location
  end

  def from_arg_value
    @kw_args ||= @node.arguments.arguments.detect{ |arg| arg.is_a?(Prism::KeywordHashNode) }
    return unless @kw_args

    @from_param ||= @kw_args.elements.detect{ _1.key.unescaped == FROM_ARG_KEY }
    return unless @from_param

    @from_param.value.unescaped
  end

  def name_arg_node
    @node.arguments.arguments.first
  end

  def link_type
    return @link_type if @link_type
    
    @link_type = case name_arg_node
    when Prism::SymbolNode
      :object_name
    when Prism::StringNode
      :file_path
    else
      nil
    end
  end

  def file_path_type?
    link_type == :file_path
  end

  def object_name_type?
    link_type == :object_name
  end

  def parse_name
    case name_arg_node
    when Prism::SymbolNode
      name_arg_node.value
    when Prism::StringNode
      name_arg_node.unescaped
    else
      ""
    end
  end

  def parse_imports
    @imports ||= get_imports
  end

  private

  def get_imports
    return [] if @node.arguments.arguments.size == 1
    
    last_arg = @node.arguments.arguments.last

    if last_arg.is_a?(Prism::KeywordHashNode)
      import_arg = last_arg.elements.detect{ _1.key.unescaped == IMPORT_ARG_KEY }
      return [] unless import_arg

      [import_arg.value.body.body.first.name.to_s]
    elsif last_arg.is_a?(Prism::LambdaNode)
      [last_arg.body.body.first.name.to_s]
    else
      return []
    end
  rescue => e
    $stderr.puts("can't parse imports: #{e.message}")
    return []
  end
end