module RuboCop
  module Cop
    module Rails
      class SkinnyController < Base
        MSG_BUSINESS_LOGIC = 'Controllers should not contain business logic. Move method "%<method>s" to a model, service object, or PORO.'
        MSG_COMPLEX_CONDITIONALS = 'Complex conditional logic detected in controller. Consider extracting to a model method or service object.'
        MSG_COMPLEX_QUERIES = 'Complex database queries detected in controller. Move to model scope or query object.'
        MSG_RAW_SQL = 'Raw SQL detected in controller. Use ActiveRecord methods or query objects instead.'
        MSG_TOO_MANY_LINES = 'Controller method "%<method>s" has %<lines>d lines (max 5). Extract logic to service objects or private methods.'

        MAX_METHOD_LINES = 5

        BUSINESS_LOGIC_PATTERNS = %w[
          calculate_ compute_ process_ validate_ send_email send_notification
          generate_report import_ export_ transform_ aggregate_ analyze_
        ].freeze

        COMPLEX_CONDITIONAL_PATTERNS = [
          /if.*&&.*&&/,
          /if.*\|\|.*\|\|/,
          /case.*when.*when.*when/
        ].freeze

        COMPLEX_QUERY_PATTERNS = [
          /\.where.*\.where/,
          /\.includes.*\.includes/
        ].freeze

        RAW_SQL_PATTERNS = [
          /ActiveRecord::Base\.connection/,
          /execute\(/,
          /find_by_sql/
        ].freeze

        def on_class(node)
          return unless controller_class?(node)

          node.each_descendant(:def) do |method_node|
            next unless public_method?(method_node)

            check_method_length(method_node)
            check_business_logic_method(method_node)
            check_complex_logic(method_node)
          end
        end

        private

        def controller_class?(node)
          class_name = node.const_name || ''
          return false unless class_name.end_with?('Controller') || class_name.split('::').last&.end_with?('Controller')

          parent_class = node.parent_class
          parent_name = parent_class&.const_name || ''

          return true if parent_name.include?('ApplicationController')
          return true if parent_name.include?('ActionController')
          return true if parent_name.include?('BaseController')
          return true if parent_name == 'ApplicationController'

          false
        end

        def public_method?(method_node)
          method_name = method_node.method_name.to_s

          return false if method_name.start_with?('set_', 'find_', 'load_', 'authorize_', 'authenticate_', 'verify_', 'ensure_', 'require_', 'redirect_')
          return false if method_name.end_with?('_params', '_permitted')
          return false if %w[respond_to].include?(method_name)

          %w[index show new create edit update destroy].include?(method_name) ||
            !method_name.start_with?('_')
        end

        def check_method_length(method_node)
          method_name = method_node.method_name.to_s
          method_lines = count_method_lines(method_node)

          if method_lines > MAX_METHOD_LINES
            add_offense(
              method_node.loc.name,
              message: format(MSG_TOO_MANY_LINES, method: method_name, lines: method_lines)
            )
          end
        end

        def count_method_lines(method_node)
          start_line = method_node.loc.keyword.line
          end_line = method_node.loc.end.line

          body_lines = end_line - start_line - 1
          body_lines.positive? ? body_lines : 0
        end

        def check_business_logic_method(method_node)
          method_name = method_node.method_name.to_s

          BUSINESS_LOGIC_PATTERNS.each do |pattern|
            if method_name.start_with?(pattern)
              add_offense(
                method_node.loc.name,
                message: format(MSG_BUSINESS_LOGIC, method: method_name)
              )
            end
          end
        end

        def check_complex_logic(method_node)
          method_source = method_node.source

          COMPLEX_CONDITIONAL_PATTERNS.each do |pattern|
            if pattern.match?(method_source)
              add_offense(
                method_node.loc.name,
                message: MSG_COMPLEX_CONDITIONALS
              )
              break
            end
          end

          COMPLEX_QUERY_PATTERNS.each do |pattern|
            if pattern.match?(method_source)
              add_offense(
                method_node.loc.name,
                message: MSG_COMPLEX_QUERIES
              )
              break
            end
          end

          RAW_SQL_PATTERNS.each do |pattern|
            if pattern.match?(method_source)
              add_offense(
                method_node.loc.name,
                message: MSG_RAW_SQL
              )
              break
            end
          end
        end
      end
    end
  end
end
