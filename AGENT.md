# Raygun CLI - Agent Guide

## Build/Test Commands
- `dart test` - Run all tests
- `dart test test/config_props_test.dart` - Run single test file
- `dart analyze` - Run linter/analysis (uses package:lints/recommended.yaml)
- `dart compile exe bin/raygun_cli.dart -o raygun-cli` - Build executable
- `dart run bin/raygun_cli.dart` - Run CLI locally
- `dart format .` - Format code

## Architecture
- **CLI Tool**: Uploads sourcemaps, manages obfuscation symbols, tracks deployments for Raygun.com
- **Main Entry**: `bin/raygun_cli.dart` - CLI argument parsing and command routing
- **Commands**: `lib/src/` - Four main command modules: sourcemap, symbols, deployments, proguard
- **APIs**: Each command has corresponding API client (`*_api.dart`) for Raygun REST API calls
- **Config**: `config_props.dart` handles arg parsing with env var fallbacks (RAYGUN_APP_ID, RAYGUN_TOKEN, RAYGUN_API_KEY)

## Code Style
- **Imports**: Standard library first, then package imports, then relative imports
- **Naming**: Snake_case for files/dirs, camelCase for variables, PascalCase for classes
- **Functions**: Use `Future<bool>` for async operations, return success/failure status
- **Errors**: Print error messages to console, return false on failure
- **Types**: Use explicit types for public APIs, required named parameters preferred
- **Strings**: Use single quotes, string interpolation with $variable or ${expression}
- **Comments**: Use /// for public API documentation, avoid inline comments
