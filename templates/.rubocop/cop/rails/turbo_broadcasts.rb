module RuboCop
  module Cop
    module Rails
      class TurboBroadcasts < Base
        MSG_CALLBACK_NO_BROADCAST = 'Model has %<callback>s callback but no broadcasting. Consider adding broadcasts_refreshes or broadcasts_to.'
        MSG_SYNC_BROADCAST_IN_CALLBACK = 'Using synchronous broadcasts in callbacks. Use %<method>s_later_to for better performance.'
        MSG_LOCAL_TRUE = 'local: true disables Turbo! Remove local: true to enable Turbo form submissions.'
        MSG_BLANK_STREAMABLES = 'turbo_stream_from with potentially blank streamables will raise ArgumentError.'
        MSG_MIXED_BROADCAST_PATTERNS = 'Using both broadcasts_refreshes and specific broadcasts may cause conflicts.'

        CALLBACK_METHODS = %w[
          after_create_commit after_update_commit after_destroy_commit after_save_commit
        ].freeze

        BROADCAST_METHODS = %w[
          broadcasts_refreshes broadcasts_to
          broadcast_append broadcast_prepend broadcast_replace
          broadcast_update broadcast_remove broadcast_before broadcast_after broadcast_refresh
        ].freeze

        ASYNC_BROADCAST_METHODS = %w[
          broadcast_append_later_to broadcast_prepend_later_to broadcast_replace_later_to
          broadcast_update_later_to broadcast_remove_later_to broadcast_before_later_to
          broadcast_after_later_to broadcast_refresh_later_to
        ].freeze

        SYNC_BROADCAST_METHODS = %w[
          broadcast_append_to broadcast_prepend_to broadcast_replace_to
          broadcast_update_to broadcast_remove_to broadcast_before_to
          broadcast_after_to broadcast_refresh_to
        ].freeze

        def on_class(node)
          return unless model_class?(node)

          check_callback_broadcasts(node)
          check_mixed_broadcast_patterns(node)
        end

        def on_send(node)
          check_local_true_in_views(node) if erb_file?
          check_turbo_stream_from(node) if erb_file?
          check_sync_broadcasts_in_callbacks(node) if model_file?
        end

        private

        def model_class?(node)
          return false unless node.const_name
          return false unless model_file?

          parent_class = node.parent_class
          return true if parent_class&.const_name == 'ApplicationRecord'
          return true if parent_class&.const_name == 'ActiveRecord::Base'

          false
        end

        def model_file?
          processed_source.file_path.include?('app/models/') &&
            processed_source.file_path.end_with?('.rb')
        end

        def erb_file?
          processed_source.file_path.end_with?('.erb')
        end

        def check_callback_broadcasts(class_node)
          has_callbacks = false
          has_broadcasts = false
          callback_nodes = []

          class_node.each_descendant(:send) do |send_node|
            method_name = send_node.method_name.to_s

            if CALLBACK_METHODS.include?(method_name)
              has_callbacks = true
              callback_nodes << send_node
            elsif BROADCAST_METHODS.any? { |broadcast| method_name.include?(broadcast) }
              has_broadcasts = true
            end
          end

          if has_callbacks && !has_broadcasts
            callback_nodes.each do |callback_node|
              callback_name = callback_node.method_name.to_s
              add_offense(
                callback_node,
                message: format(MSG_CALLBACK_NO_BROADCAST, callback: callback_name)
              )
            end
          end
        end

        def check_mixed_broadcast_patterns(class_node)
          has_broadcasts_refreshes = false
          has_specific_broadcasts = false

          class_node.each_descendant(:send) do |send_node|
            method_name = send_node.method_name.to_s

            if method_name.include?('broadcasts_refreshes')
              has_broadcasts_refreshes = true
            elsif SYNC_BROADCAST_METHODS.any? { |method| method_name.include?(method) } ||
                  ASYNC_BROADCAST_METHODS.any? { |method| method_name.include?(method) }
              has_specific_broadcasts = true
            end
          end

          if has_broadcasts_refreshes && has_specific_broadcasts
            add_offense(
              class_node.loc.name,
              message: MSG_MIXED_BROADCAST_PATTERNS
            )
          end
        end

        def check_local_true_in_views(node)
          return unless node.method_name == :form_with || node.method_name == :form_for

          node.arguments.each do |arg|
            next unless arg.hash_type?

            arg.pairs.each do |pair|
              key_node = pair.key
              value_node = pair.value

              if key_node.sym_type? && key_node.value == :local &&
                 value_node.true_type?
                add_offense(pair, message: MSG_LOCAL_TRUE)
              end
            end
          end
        end

        def check_turbo_stream_from(node)
          return unless node.method_name == :turbo_stream_from

          node.arguments.each do |arg|
            if potentially_blank_argument?(arg)
              add_offense(node, message: MSG_BLANK_STREAMABLES)
            end
          end
        end

        def check_sync_broadcasts_in_callbacks(node)
          method_name = node.method_name.to_s

          SYNC_BROADCAST_METHODS.each do |sync_method|
            next unless method_name.include?(sync_method)

            if inside_callback?(node)
              async_method = sync_method.sub('_to', '_later_to')
              add_offense(
                node,
                message: format(MSG_SYNC_BROADCAST_IN_CALLBACK, method: async_method)
              )
            end
          end
        end

        def inside_callback?(node)
          ancestor = node.parent
          while ancestor
            if ancestor.block_type?
              send_node = ancestor.send_node
              if send_node && CALLBACK_METHODS.include?(send_node.method_name.to_s)
                return true
              end
            elsif ancestor.def_type?
              method_name = ancestor.method_name.to_s
              return CALLBACK_METHODS.include?(method_name)
            end
            ancestor = ancestor.parent
          end
          false
        end

        def potentially_blank_argument?(arg)
          case arg.type
          when :array
            arg.children.empty?
          when :nil
            true
          when :str
            arg.value.empty?
          when :send
            %w[nil blank empty].include?(arg.method_name.to_s)
          else
            false
          end
        end
      end
    end
  end
end
