module RubyLsp
  module Ree
    module ReeLspUtils
      def package_name_from_uri(uri)
        uri_parts = uri.to_s.split('/')
        package_index = uri_parts.find_index('package') + 1
        uri_parts[package_index]
      end

      def path_from_package(uri)
        uri_parts = uri.chomp(File.extname(uri)).split('/')
        pack_folder_index = uri_parts.index('package')
        uri_parts.drop(pack_folder_index+1).join('/')
      end

      def parse_doc_info(uri)
        ast = Prism.parse_file(uri.path).value

        class_node = ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
        fn_node = class_node.body.body.detect{ |node| node.name == :fn }
        block_node = fn_node.block

        link_nodes = if block_node && block_node.body
          block_node.body.body.select{ |node| node.name == :link }
        else
          []
        end

        linked_objects = link_nodes.map do |link_node|
          name_arg_node = link_node.arguments.arguments.first

          name_val = case name_arg_node
          when Prism::SymbolNode
            name_arg_node.value
          when Prism::StringNode
            name_arg_node.unescaped
          else
            ""
          end

          OpenStruct.new(
            name: name_val
          )
        end

        return OpenStruct.new(
          ast: ast,
          package_name: package_name_from_uri(uri),
          class_node: class_node,
          fn_node: fn_node,
          block_node: block_node,
          link_nodes: link_nodes,
          linked_objects: linked_objects
        )
      end   

      def get_range_for_fn_insert(doc_info, link_text)
        fn_line = doc_info.fn_node.location.start_line

        position = if doc_info.block_node
          doc_info.block_node.opening_loc.end_column + 1
        else
          doc_info.fn_node.arguments.location.end_column + 1
        end

        Interface::Range.new(
          start: Interface::Position.new(line: fn_line - 1, character: position),
          end: Interface::Position.new(line: fn_line - 1, character: position + link_text.size),
        )
      end
    end
  end
end