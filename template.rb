def source_paths
  [File.join(File.dirname(__FILE__), "templates")] + Array(super)
end

def bws_prefix
  app_name.sub(/_core$/, "").tr("-", "_").upcase
end

def docker_image_name
  app_name.tr("-", "_")
end

def container_name
  "#{app_name}-rails-app-1"
end

# 1. Replace Gemfile
remove_file "Gemfile"
template "Gemfile.tt"

# 2. Infrastructure files (pre-bundle)

# Production Dockerfile + docker-entrypoint
remove_file "Dockerfile"
template "Dockerfile.tt"
remove_file ".dockerignore"
copy_file ".dockerignore"
remove_file "bin/docker-entrypoint"
template "bin/docker-entrypoint.tt", "bin/docker-entrypoint"
chmod "bin/docker-entrypoint", 0o755

# .gitignore
remove_file ".gitignore"
template ".gitignore.tt"

# RuboCop
remove_file ".rubocop.yml"
template ".rubocop.yml.tt", ".rubocop.yml"
copy_file ".rubocop/cop/no_comments.rb"
copy_file ".rubocop/cop/rails/skinny_controller.rb"
copy_file ".rubocop/cop/rails/strict_restful_routes.rb"
copy_file ".rubocop/cop/rails/no_metaprogramming.rb"
copy_file ".rubocop/cop/rails/turbo_broadcasts.rb"

# Claude settings + hooks
template ".claude/settings.json.tt", ".claude/settings.json"
copy_file ".claude/.gitignore"
copy_file ".claude/hooks/log_hook.sh"
copy_file ".claude/hooks/tdd_check.sh"
copy_file ".claude/hooks/rubocop_test.sh"
copy_file ".claude/hooks/controller_response_check.sh"
copy_file ".claude/hooks/broadcast_test_guide.sh"
copy_file ".claude/hooks/no_skip_tests.sh"
copy_file ".claude/hooks/rails_test_guide.sh"
copy_file ".claude/hooks/test_posttooluse.sh"
chmod ".claude/hooks/log_hook.sh", 0o755
chmod ".claude/hooks/tdd_check.sh", 0o755
chmod ".claude/hooks/rubocop_test.sh", 0o755
chmod ".claude/hooks/controller_response_check.sh", 0o755
chmod ".claude/hooks/broadcast_test_guide.sh", 0o755
chmod ".claude/hooks/no_skip_tests.sh", 0o755
chmod ".claude/hooks/rails_test_guide.sh", 0o755
chmod ".claude/hooks/test_posttooluse.sh", 0o755

# Devcontainer (Rails 8 generates its own, remove first)
remove_file ".devcontainer/devcontainer.json"
remove_file ".devcontainer/compose.yaml"
remove_file ".devcontainer/Dockerfile"
template ".devcontainer/devcontainer.json.tt", ".devcontainer/devcontainer.json"
template ".devcontainer/compose.yaml.tt", ".devcontainer/compose.yaml"
template ".devcontainer/Dockerfile.tt", ".devcontainer/Dockerfile"
template ".devcontainer/setup-bws-env.sh.tt", ".devcontainer/setup-bws-env.sh"
chmod ".devcontainer/setup-bws-env.sh", 0o755

# GitHub Actions (Rails 8 generates its own ci.yml and dependabot.yml, remove first)
remove_file ".github/dependabot.yml"
remove_file ".github/workflows/ci.yml"
copy_file ".github/dependabot.yml"
template ".github/BWS_SECRETS.md.tt", ".github/BWS_SECRETS.md"
copy_file ".github/actions/setup-bws/action.yml"
template ".github/workflows/ci.yml.tt", ".github/workflows/ci.yml"
template ".github/workflows/cd.yml.tt", ".github/workflows/cd.yml"
template ".github/workflows/kamal.yml.tt", ".github/workflows/kamal.yml"

# Config overrides (cable, cache, queue, deploy, and kamal secrets handled in after_bundle)
remove_file "config/database.yml"
template "config/database.yml.tt", "config/database.yml"
remove_file "config/storage.yml"
template "config/storage.yml.tt", "config/storage.yml"
remove_file "config/puma.rb"
template "config/puma.rb.tt", "config/puma.rb"
copy_file "config/initializers/pagy.rb"

# CLAUDE.md files (root)
template "CLAUDE.md.tt"
template "CLAUDE.local.md.example.tt"

# 3. after_bundle block
after_bundle do
  # Override Solid Stack configs (installed automatically during bundle)
  remove_file "config/cache.yml"
  template "config/cache.yml.tt", "config/cache.yml"
  remove_file "config/queue.yml"
  template "config/queue.yml.tt", "config/queue.yml"
  remove_file "config/cable.yml"
  template "config/cable.yml.tt", "config/cable.yml"

  # Override Kamal configs (kamal init runs during bundle)
  remove_file ".kamal/secrets"
  template ".kamal/secrets.tt", ".kamal/secrets"
  remove_file "config/deploy.yml"
  template "config/deploy.yml.tt", "config/deploy.yml"
  template "config/deploy.staging.yml.tt", "config/deploy.staging.yml"

  # Generate Devise
  generate "devise:install"
  generate "devise", "User"

  # Inject AR encryption + Solid Queue + ViewComponent config into application.rb
  inject_into_class "config/application.rb", "Application", <<~RUBY
    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = { database: { writing: :queue } }
    config.cache_store = :solid_cache_store

    config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]

    config.view_component.preview_paths = [ Rails.root.join("test/components/previews") ]
    config.view_component.generate.preview = true
  RUBY

  # Copy app code
  copy_file "app/services/application_service.rb"
  template "app/services/CLAUDE.md.tt", "app/services/CLAUDE.md"
  copy_file "app/components/application_component.rb"
  template "app/components/CLAUDE.md.tt", "app/components/CLAUDE.md"
  copy_file "app/javascript/controllers/flash_controller.js"
  copy_file "app/javascript/controllers/dropdown_controller.js"
  copy_file "app/javascript/controllers/modal_controller.js"
  template "app/javascript/controllers/CLAUDE.md.tt", "app/javascript/controllers/CLAUDE.md"

  # Copy nested CLAUDE.md files
  template "app/models/CLAUDE.md.tt", "app/models/CLAUDE.md"
  template "app/controllers/CLAUDE.md.tt", "app/controllers/CLAUDE.md"
  template "app/helpers/CLAUDE.md.tt", "app/helpers/CLAUDE.md"
  template "app/views/CLAUDE.md.tt", "app/views/CLAUDE.md"

  # Copy test infrastructure
  remove_file "test/test_helper.rb"
  template "test/test_helper.rb.tt", "test/test_helper.rb"
  remove_file "test/application_system_test_case.rb"
  template "test/application_system_test_case.rb.tt", "test/application_system_test_case.rb"
  remove_file "test/factories/users.rb"
  template "test/factories/users.rb.tt", "test/factories/users.rb"
  template "test/CLAUDE.md.tt", "test/CLAUDE.md"

  # Install Tailwind CSS
  rails_command "tailwindcss:install"

  # Clean up Rails/Devise-generated files to pass RuboCop
  # Remove comments from generated files (NoComments cop)
  %w[
    Rakefile
    config.ru
    app/controllers/application_controller.rb
    app/jobs/application_job.rb
    app/models/user.rb
    test/models/user_test.rb
  ].each do |file|
    next unless File.exist?(file)
    content = File.read(file)
    cleaned = content.lines.reject { |line| line.strip.start_with?("#") && !line.strip.start_with?("# frozen_string_literal") }.join
    cleaned.gsub!(/\n{3,}/, "\n\n")
    File.write(file, cleaned)
  end

  # Auto-fix remaining RuboCop offenses (SpaceInsideArrayLiteralBrackets, StringLiterals)
  run "bundle exec rubocop -A --fail-level=E 2>/dev/null || true"

  # Database setup
  rails_command "db:create"
  rails_command "db:migrate"

  # Git init + commit
  git :init unless File.exist?(".git")
  git add: "-A"
  git commit: "-m 'Initial commit from Rails 8 boilerplate template'"

  # Copy pre-commit hook
  template "git_hooks/pre-commit.tt", ".git/hooks/pre-commit"
  chmod ".git/hooks/pre-commit", 0o755
end
