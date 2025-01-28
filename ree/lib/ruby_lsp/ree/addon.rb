require "ruby_lsp/addon"
require_relative "basic_listener"
require_relative "definition"
require_relative "completion"
require_relative "ree_indexing_enhancement"
require_relative "ree_lsp_utils"

module RubyLsp
  module Ree
    class Addon < ::RubyLsp::Addon
      def activate(global_state, message_queue)
        $stderr.puts "in activate"

        @global_state = global_state
        @message_queue = message_queue
      end

      def deactivate
      end

      def name
        "Ree Addon"
      end

      def create_hover_listener(response_builder, node_context, dispatcher)
        $stderr.puts "in create_hover_listener"

        BasicListener.new(dispatcher, response_builder)
      end

      def create_definition_listener(response_builder, uri, node_context, dispatcher)
        $stderr.puts("create_definition_listener")

        index = @global_state.index
        RubyLsp::Ree::Definition.new(response_builder, node_context, index, dispatcher)
      end

      def create_completion_listener(response_builder, node_context, dispatcher, uri)
        $stderr.puts("create_completion_listener")

        index = @global_state.index
        RubyLsp::Ree::Completion.new(response_builder, node_context, index, dispatcher, uri)
      end
    end
  end
end