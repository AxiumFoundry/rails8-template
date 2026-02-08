# Rails 8 Application Template

Rails 8 application template with CI/CD, Kamal deployment, devcontainer, Claude Code hooks, RuboCop custom cops, TDD workflow, and Bitwarden Secrets Manager integration.

## Usage

```bash
rails new myapp -d postgresql -m /path/to/template.rb
```

Or from GitHub:

```bash
rails new myapp -d postgresql -m https://raw.githubusercontent.com/AxiumFoundry/rails8-template/main/template.rb
```

## What's Included

### Stack
- **Rails 8.x** with PostgreSQL
- **Solid Stack** - Solid Cache, Solid Queue, Solid Cable (multi-database)
- **Hotwire** - Turbo + Stimulus
- **Tailwind CSS**
- **Devise** for authentication
- **ViewComponent** for reusable UI components
- **Kamal** for deployment

### Infrastructure
- **Devcontainer** - PostgreSQL, Selenium, BWS CLI, Claude Code
- **CI** - GitHub Actions: scan, lint, test, system-test, autofix (Claude Code), email notifications
- **CD** - Kamal deploy on CI success (main -> production, develop -> staging)
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
- Root `CLAUDE.md` with project conventions
- 8 nested `CLAUDE.md` files for models, controllers, services, helpers, views, components, Stimulus, tests
- `CLAUDE.local.md.example` for personal preferences

## Dynamic Values

You don't need to find-and-replace anything after generation. The template automatically inserts your project name into every config file, workflow, and script.

The name you pass to `rails new` drives everything:

```bash
rails new my_cool_app -d postgresql -m template.rb
#          ^^^^^^^^^^^
#          This becomes `app_name` -- every value below is derived from it.
```

| Where it shows up | What gets inserted | Example |
|---|---|---|
| Database names | `{app_name}_development`, `_test`, etc. | `my_cool_app_development` |
| Docker image name | `{app_name}` (hyphens become underscores) | `my_cool_app` |
| Devcontainer service | `{app_name}` in `compose.yaml`, `devcontainer.json` | `my_cool_app` |
| Container name | `{app_name}-rails-app-1` (used in pre-commit hook, CLAUDE.md) | `my_cool_app-rails-app-1` |
| Kamal deploy config | `service: {app_name}` in `config/deploy.yml` | `service: my_cool_app` |
| BWS secret prefix | `{APP_NAME}` uppercased (see below) | `MY_COOL_APP` |

### BWS prefix

Bitwarden Secrets Manager keys are prefixed with your project name so multiple projects can share one BWS organization. The prefix is derived by uppercasing `app_name` and replacing hyphens with underscores.

```
my_cool_app -> MY_COOL_APP
my-cool-app -> MY_COOL_APP
```

This prefix appears in:
- **`.kamal/secrets`** - `KAMAL secrets extract MY_COOL_APP_RAILS_MASTER_KEY`
- **`.devcontainer/setup-bws-env.sh`** - maps BWS secrets to environment variables
- **`.github/BWS_SECRETS.md`** - documents every secret your CI/CD needs

See [templates/.github/BWS_SECRETS.md.tt](templates/.github/BWS_SECRETS.md.tt) for the full list of required secrets and which workflows use them.

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
