module RuboCop
  module Cop
    module Rails
      class StrictRestfulRoutes < Base
        MSG_NON_RESTFUL_ACTION = 'Non-RESTful action "%<action>s" detected. Use only: index, show, new, create, edit, update, destroy.'
        MSG_FORMS_IN_SHOW = 'Forms must NOT be in show actions. Use "edit" action for forms, "show" action for display only.'
        MSG_CUSTOM_ROUTES = 'Custom routes outside resources blocks detected. All routes must be within resources/resource blocks.'
        MSG_CONDITIONAL_ROUTES = 'Conditional routes detected. Even development/test routes must follow REST conventions.'
        MSG_TEST_DEMO_ROUTES = 'Test/demo routes detected. Create proper resources with meaningful names instead.'
        MSG_CUSTOM_MEMBER_COLLECTION = 'Custom member/collection actions are NOT allowed. Create new nested resources instead.'
        MSG_NAMESPACE_VIOLATIONS = 'Custom routes in namespace detected. Use resources/resource even within namespaces.'

        RESTFUL_ACTIONS = %w[index show new create edit update destroy].freeze
        ALLOWED_PRIVATE_METHODS = %w[
          set_ find_ load_ authorize_ authenticate_ verify_ ensure_ require_ redirect_
          permitted_ respond_to
        ].freeze
        ALLOWED_ROUTE_EXCEPTIONS = %w[
          devise_for rails/health#show rails/pwa# mount root redirect match.*errors#
        ].freeze

        def on_class(node)
          return unless controller_class?(node)

          check_controller_actions(node)
        end

        def on_send(node)
          return unless routes_file?

          check_routes_patterns(node) if route_definition?(node)
        end

        def on_block(node)
          return unless routes_file?

          check_member_collection_blocks(node)
          check_namespace_blocks(node)
        end

        private

        def controller_class?(node)
          return false unless node.const_name&.end_with?('Controller')

          parent_class = node.parent_class
          return true if parent_class&.const_name == 'ApplicationController'
          return true if parent_class&.const_name == 'ActionController::Base'

          false
        end

        def routes_file?
          processed_source.file_path.end_with?('routes.rb')
        end

        def route_definition?(node)
          return false unless node.method_name

          method_name = node.method_name.to_s
          %w[get post put patch delete match].include?(method_name)
        end

        def check_controller_actions(class_node)
          class_node.each_descendant(:def) do |method_node|
            method_name = method_node.method_name.to_s

            next if private_helper_method?(method_name)

            if method_name == 'show' && contains_form?(method_node)
              add_offense(method_node, message: MSG_FORMS_IN_SHOW)
            end

            unless RESTFUL_ACTIONS.include?(method_name) || private_helper_method?(method_name)
              add_offense(
                method_node.loc.name,
                message: format(MSG_NON_RESTFUL_ACTION, action: method_name)
              )
            end
          end
        end

        def check_routes_patterns(node)
          return if allowed_system_route?(node)
          return if resources_route?(node)

          route_path = extract_route_path(node)
          return unless route_path

          if conditional_route?(node)
            add_offense(node, message: MSG_CONDITIONAL_ROUTES)
            return
          end

          if test_demo_route?(route_path)
            add_offense(node, message: MSG_TEST_DEMO_ROUTES)
            return
          end

          add_offense(node, message: MSG_CUSTOM_ROUTES)
        end

        def check_member_collection_blocks(node)
          return unless member_or_collection_block?(node)

          node.each_descendant(:send) do |route_node|
            next unless route_definition?(route_node)

            route_action = extract_route_action(route_node)
            next unless route_action

            unless RESTFUL_ACTIONS.include?(route_action.to_s)
              add_offense(
                route_node,
                message: MSG_CUSTOM_MEMBER_COLLECTION
              )
            end
          end
        end

        def check_namespace_blocks(node)
          return unless namespace_block?(node)

          node.each_descendant(:send) do |route_node|
            next unless route_definition?(route_node)
            next if resources_route?(route_node)

            add_offense(route_node, message: MSG_NAMESPACE_VIOLATIONS)
          end
        end

        def private_helper_method?(method_name)
          ALLOWED_PRIVATE_METHODS.any? { |pattern| method_name.start_with?(pattern) } ||
            method_name.end_with?('_params') ||
            ALLOWED_PRIVATE_METHODS.include?(method_name)
        end

        def contains_form?(method_node)
          method_source = method_node.source
          method_source.include?('form_with') || method_source.include?('form_for')
        end

        def allowed_system_route?(node)
          route_source = node.source
          ALLOWED_ROUTE_EXCEPTIONS.any? { |pattern| route_source.match?(/#{pattern}/) }
        end

        def resources_route?(node)
          return false unless node.method_name

          %w[resources resource].include?(node.method_name.to_s)
        end

        def conditional_route?(node)
          ancestor = node.parent
          while ancestor
            return true if conditional_block?(ancestor)
            ancestor = ancestor.parent
          end
          false
        end

        def conditional_block?(node)
          return false unless node.respond_to?(:if_type?) && node.respond_to?(:unless_type?)

          node.if_type? || node.unless_type?
        end

        def test_demo_route?(path)
          test_patterns = %w[test demo example sample debug playground sandbox]
          test_patterns.any? { |pattern| path.downcase.include?(pattern) }
        end

        def member_or_collection_block?(node)
          return false unless node.block_type?

          send_node = node.send_node
          return false unless send_node&.method_name

          %w[member collection].include?(send_node.method_name.to_s)
        end

        def namespace_block?(node)
          return false unless node.block_type?

          send_node = node.send_node
          return false unless send_node&.method_name

          send_node.method_name.to_s == 'namespace'
        end

        def extract_route_path(node)
          first_arg = node.first_argument
          return nil unless first_arg

          if first_arg.str_type?
            first_arg.value
          elsif first_arg.sym_type?
            first_arg.value.to_s
          end
        end

        def extract_route_action(node)
          first_arg = node.first_argument
          return nil unless first_arg&.sym_type?

          first_arg.value
        end
      end
    end
  end
end
