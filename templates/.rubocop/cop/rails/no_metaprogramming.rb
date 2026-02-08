module RuboCop
  module Cop
    module Rails
      class NoMetaprogramming < Base
        MSG_METAPROGRAMMING = 'Metaprogramming detected: %<method>s. Use regular methods instead for better clarity and maintainability.'
        MSG_LARGE_SERVICE = 'Large service object detected (%<lines>d lines). Consider if this logic can live in model/controller instead.'

        METAPROGRAMMING_METHODS = %w[
          define_method
          method_missing
          class_eval
          instance_eval
          module_eval
          eval
          const_missing
          send
          public_send
          instance_variable_get
          instance_variable_set
          class_variable_get
          class_variable_set
          remove_method
          undef_method
          alias_method
        ].freeze

        SERVICE_PATTERNS = %w[
          Service
          Interactor
          Command
          UseCase
          Operation
          Action
        ].freeze

        MAX_SERVICE_LINES = 50

        def on_send(node)
          check_metaprogramming(node)
        end

        def on_class(node)
          check_service_object_size(node)
        end

        private

        def check_metaprogramming(node)
          method_name = node.method_name.to_s

          if METAPROGRAMMING_METHODS.include?(method_name)
            add_offense(
              node.loc.selector,
              message: format(MSG_METAPROGRAMMING, method: method_name)
            )
          end
        end

        def check_service_object_size(node)
          return unless service_object?(node)

          line_count = count_lines_of_code(node)

          if line_count > MAX_SERVICE_LINES
            add_offense(
              node.loc.name,
              message: format(MSG_LARGE_SERVICE, lines: line_count)
            )
          end
        end

        def service_object?(node)
          return false unless node.const_name

          class_name = node.const_name
          SERVICE_PATTERNS.any? { |pattern| class_name.include?(pattern) }
        end

        def count_lines_of_code(node)
          return 0 unless node.loc.expression

          start_line = node.loc.expression.first_line
          end_line = node.loc.expression.last_line

          source_lines = processed_source.lines[start_line - 1..end_line - 1]
          source_lines.count do |line|
            cleaned_line = line.strip
            !cleaned_line.empty? && !cleaned_line.start_with?('#')
          end
        end
      end
    end
  end
end
