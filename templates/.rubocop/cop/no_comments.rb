module RuboCop
  module Cop
    module Custom
      class NoComments < Base
        MSG = 'Comments are not allowed. Use self-documenting code with descriptive names instead.'

        def on_new_investigation
          processed_source.comments.each do |comment|
            next if allowed_comment?(comment)

            add_offense(comment.loc.expression)
          end
        end

        private

        def allowed_comment?(comment)
          text = comment.text

          text.match?(/\A#\s*frozen_string_literal:/) ||
            text.match?(/\A#\s*rubocop:/) ||
            text.match?(/\A#\s*TODO:\s*[A-Z]+-\d+(\s|$)/) ||
            text.match?(/\A#!/)
        end
      end
    end
  end
end
