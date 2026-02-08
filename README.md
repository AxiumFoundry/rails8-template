# Rails 8 Application Template

A production-ready Rails 8 application template with batteries included: CI/CD, Kamal deployment, devcontainer, Claude Code hooks, RuboCop custom cops, TDD workflow, and Bitwarden Secrets Manager integration.

## Usage

```bash
rails new myapp -d postgresql -m /path/to/template.rb
```

Or from a remote URL:

```bash
rails new myapp -d postgresql -m https://raw.githubusercontent.com/YOUR_USER/docker-rails7-tailwind-pgsql/main/template.rb
```

## What's Included

### Stack
- **Rails 8.x** with PostgreSQL
- **Solid Stack** - Solid Cache, Solid Queue, Solid Cable (multi-database)
- **Hotwire** - Turbo + Stimulus for frontend interactivity
- **Tailwind CSS** for styling
- **Devise** for authentication
- **ViewComponent** for reusable UI components
- **Kamal** for Docker-based deployment

### Infrastructure
- **Devcontainer** - VS Code devcontainer with PostgreSQL, Selenium, BWS CLI, Claude Code
- **CI/CD** - GitHub Actions with scan, lint, test, system-test, autofix (Claude Code), email notifications
- **CD** - Automated deployment via Kamal on CI success (main -> production, develop -> staging)
- **Kamal** - Production and staging deploy configs with Docker Hub registry
- **BWS** - Bitwarden Secrets Manager for all secrets (only `BWS_ACCESS_TOKEN` needed as GitHub secret)

### Code Quality
- **RuboCop** with 5 custom cops:
  - `Custom/NoComments` - Enforces self-documenting code
  - `Rails/SkinnyController` - Max 5 lines per action, no business logic
  - `Rails/StrictRestfulRoutes` - Only 7 RESTful actions, no custom routes
  - `Rails/NoMetaprogramming` - No `define_method`, `send`, etc.
  - `Rails/TurboBroadcasts` - Enforces async broadcasts, no `local: true`
- **Claude Code hooks** - TDD enforcement, auto-test, auto-lint on every edit
- **Git pre-commit hook** - RuboCop + related tests on staged files

### Testing
- **Minitest + Capybara** with parallel test execution
- **FactoryBot** for test data
- **WebMock** for HTTP stubbing
- **SimpleCov** for code coverage
- **TDD workflow** enforced by Claude hooks

### CLAUDE.md Documentation
- Root `CLAUDE.md` with full project conventions
- 8 nested `CLAUDE.md` files for models, controllers, services, helpers, views, components, Stimulus, tests
- `CLAUDE.local.md.example` for personal preferences

## Dynamic Values

All project-specific values are derived from the `app_name`:

| Value | Example (`my_cool_app`) |
|---|---|
| BWS prefix | `MY_COOL_APP` |
| Docker image | `my_cool_app` |
| Container name | `my_cool_app-rails-app-1` |
| Database | `my_cool_app_development` |

## Post-Generation Setup

1. **BWS**: Create secrets in Bitwarden Secrets Manager with the correct prefix
2. **GitHub**: Add `BWS_ACCESS_TOKEN` and `CLAUDE_CODE_OAUTH_TOKEN` as repository secrets
3. **Kamal**: Update `config/deploy.yml` and `config/deploy.staging.yml` with your server IPs and domains
4. **Docker Hub**: Update registry username in deploy configs
5. **`.kamal/secrets`**: Add your BWS secret UUIDs

## File Structure

```
template.rb           # Main orchestrator
templates/            # Thor template files
  Gemfile.tt
  Dockerfile.tt
  .rubocop.yml.tt
  .rubocop/cop/       # 5 custom RuboCop cops
  .claude/            # Claude Code settings + 8 hook scripts
  .devcontainer/      # VS Code devcontainer
  .github/            # CI/CD workflows + BWS action
  .kamal/             # Kamal secrets
  config/             # Database, cable, cache, queue, storage, puma, deploy
  app/                # ApplicationService, ApplicationComponent, Stimulus controllers
  test/               # Test helper, system test case, factories
  git_hooks/          # Pre-commit hook
  CLAUDE.md.tt        # + 8 nested CLAUDE.md templates
```
