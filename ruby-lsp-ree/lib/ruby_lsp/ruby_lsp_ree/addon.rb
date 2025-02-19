require "ruby_lsp/addon"
require_relative "definition"
require_relative "completion"
require_relative "ree_indexing_enhancement"
require_relative "ree_lsp_utils"
require_relative "ree_formatter"
require_relative "parsing/parsed_document_builder"

module RubyLsp
  module Ree
    class Addon < ::RubyLsp::Addon
      def activate(global_state, message_queue)
        @global_state = global_state
        @message_queue = message_queue

        global_state.register_formatter("ree_formatter", RubyLsp::Ree::ReeFormatter.new)
      end

      def deactivate
      end

      def name
        "Ree Addon"
      end

      def create_definition_listener(response_builder, uri, node_context, dispatcher)
        index = @global_state.index
        RubyLsp::Ree::Definition.new(response_builder, node_context, index, dispatcher, uri)
      end

      def create_completion_listener(response_builder, node_context, dispatcher, uri)
        index = @global_state.index
        RubyLsp::Ree::Completion.new(response_builder, node_context, index, dispatcher, uri)
      end
    end
  end
end