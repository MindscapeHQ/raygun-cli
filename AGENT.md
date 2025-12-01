# Raygun CLI - Agent Guide

## Build/Test Commands
- `dart test` - Run all tests
- `dart test test/config_props_test.dart` - Run single test file
- `dart analyze` - Run linter/analysis (uses package:lints/recommended.yaml)
- `dart compile exe bin/raygun_cli.dart -o raygun-cli` - Build executable
- `dart run bin/raygun_cli.dart` - Run CLI locally
- `dart format .` - Format code
- `dart run build_runner build` - Generate mocks (one-time)
- `dart run build_runner watch` - Auto-regenerate mocks on changes

## Architecture
- **CLI Tool**: Uploads sourcemaps, manages obfuscation symbols, tracks deployments for Raygun.com
- **Main Entry**: `bin/raygun_cli.dart` - CLI argument parsing and command routing
- **Commands**: `lib/src/` - Five main command modules: sourcemap, symbols, deployments, proguard, dsym
- **APIs**: Each command has corresponding API client (`*_api.dart`) for Raygun REST API calls
- **Config**: `config_props.dart` handles arg parsing with env var fallbacks (RAYGUN_APP_ID, RAYGUN_TOKEN, RAYGUN_API_KEY)

### Directory Structure
```
lib/src/[command]/
  ├── [command]_command.dart  # CLI parsing and routing
  ├── [command]_api.dart      # Raygun API integration
  └── [command].dart          # Business logic (if complex)
lib/src/core/                 # Shared utilities (RaygunCommand, RaygunApi builders)
test/[command]/               # Tests mirror lib structure
```

### Dependency Flow
```
bin/raygun_cli.dart → lib/src/[command]/[command]_command.dart → *_api.dart
```
- Commands are stateless; API clients handle HTTP
- Commands receive API clients via constructor (dependency injection)

## Code Style
- **Imports**: Standard library first, then package imports, then relative imports
- **Naming**: Snake_case for files/dirs, camelCase for variables, PascalCase for classes
- **Functions**: Use `Future<bool>` for async operations, return success/failure status
- **Errors**: Print error messages to console, return false on failure
- **Types**: Use explicit types for public APIs, required named parameters preferred
- **Strings**: Use single quotes, string interpolation with $variable or ${expression}
- **Comments**: Use /// for public API documentation, avoid inline comments

## Error Handling & Exit Codes
Standard error handling patterns used throughout:
- **Exit code 0**: Success
- **Exit code 1**: Failure (operation didn't succeed)
- **Exit code 2**: Error (exception or invalid input)
- Print errors to console before returning/exiting
- Use `Future<bool>` return type for async operations
- Chain with `.then()` and `.catchError()` for error handling

Example:
```dart
run().then((result) {
  if (result) {
    exit(0);
  } else {
    exit(2);
  }
}).catchError((e) {
  print('Error: $e');
  exit(2);
});
```

## Command Implementation Patterns
All commands extend the `RaygunCommand` abstract class:

### Required Implementation
```dart
class MyCommand extends RaygunCommand {
  const MyCommand({required this.api});

  final MyApi api;

  @override
  String get name => 'mycommand';

  @override
  ArgParser buildParser() { /* ... */ }

  @override
  void execute(ArgResults command, bool verbose) { /* ... */ }
}
```

### Command Patterns
- **Help Flag**: Always check for `--help` flag first and exit(0)
- **Config Loading**: Use `ConfigProp.load()` for app-id, token, api-key (exits if missing)
- **Subcommands**: Use `ArgParser.addCommand()` (see symbols: upload/list/delete)
- **Verbose Flag**: Available in all commands (inherited from main parser)
- **Mandatory Args**: Use `mandatory: true` in ArgParser for required flags

### Example: Subcommands Pattern (symbols command)
```dart
ArgParser buildParser() {
  return ArgParser()
    ..addOption('app-id')
    ..addOption('token')
    ..addCommand('upload')
    ..addCommand('list')
    ..addCommand('delete');
}
```

## API Client Patterns
Each command has a corresponding API client:

### Builder Pattern for Requests
- `RaygunMultipartRequestBuilder` - For file uploads
- `RaygunPostRequestBuilder` - For JSON POST requests

Example:
```dart
final request = RaygunMultipartRequestBuilder(url, 'POST')
  .addBearerToken(token)
  .addFile('file', filePath)
  .addField('version', version)
  .build();
```

### API Client Structure
- Factory method pattern: Use static `.create()` for production instances
- Return `Future<bool>` to indicate success/failure
- Print response codes and messages for debugging
- Handle HTTP responses and errors appropriately

## Testing Patterns & Mock Generation

### Test Structure
- Tests use `mockito` for mocking API clients
- Test files mirror `lib/` structure (e.g., `lib/src/symbols/` → `test/symbols/`)
- Mock files use `.mocks.dart` suffix and are git-tracked
- Generate mocks with: `dart run build_runner build`

### Test Pattern
```dart
// 1. Generate mock classes with @GenerateMocks annotation
@GenerateMocks([MyApi])
void main() {
  group('MyCommand', () {
    late MockMyApi mockApi;

    setUp(() {
      mockApi = MockMyApi();
    });

    test('description', () async {
      // 2. Setup mock behavior
      when(mockApi.someMethod()).thenAnswer((_) async => true);

      // 3. Inject mock into command
      final command = MyCommand(api: mockApi);

      // 4. Execute and verify
      final result = await command.run(...);
      expect(result, true);
    });
  });
}
```

### Mock Regeneration
- After changing API signatures, run: `dart run build_runner build`
- Use `watch` mode during development: `dart run build_runner watch`

## Dependency Injection

### Pattern
- Commands receive API clients via constructor
- Global command instances use `.create()` factories
- Tests inject mock API clients
- Enables testing without hitting real APIs

Example:
```dart
// Production usage (in command file)
SymbolsCommand symbolsCommand = SymbolsCommand(api: SymbolsApi.create());

// Test usage
final mockApi = MockSymbolsApi();
final command = SymbolsCommand(api: mockApi);
```

## CI/CD & Release Workflow

### PR Requirements
- **Title**: Must follow Conventional Commits (enforced by `.github/workflows/pr.yml`)
- **Checks**: All must pass - format, analyze, test
- **Platforms**: Multi-platform builds run automatically (Linux, macOS, Windows)

### Conventional Commits Format
Examples:
- `feat: add new command for X`
- `fix: resolve issue with Y`
- `chore: update dependencies`
- `docs: update README`

### Version Management
**IMPORTANT**: Update BOTH files when releasing:
1. `pubspec.yaml` - version field
2. `bin/raygun_cli.dart` - version constant

### Workflows
- **pr.yml**: Validates PR title format
- **main.yml**: Runs tests, format check, analysis, and builds binaries for all platforms
- **release.yml**: On GitHub release, builds and uploads zipped binaries

## Development Workflow

### Local Testing
```bash
# Run CLI locally with arguments
dart run bin/raygun_cli.dart <command> <args>

# Use verbose flag for debug output
dart run bin/raygun_cli.dart -v sourcemap --help

# Set environment variables for testing
export RAYGUN_APP_ID=test-app-id
export RAYGUN_TOKEN=test-token
export RAYGUN_API_KEY=test-api-key
```

### Testing Workflow
1. Write/modify API client code
2. Add `@GenerateMocks([MyApi])` to test file
3. Run `dart run build_runner build` to generate mocks
4. Write tests using mock instances
5. Run `dart test` to verify

### Build for Distribution
```bash
# Compile for current platform
dart compile exe bin/raygun_cli.dart -o raygun-cli

# Note: Cross-compilation not supported; use CI for other platforms
```

## Common Gotchas & Best Practices

### Validation Order
1. Always validate `--help` flag first before parsing other args
2. `ConfigProp.load()` calls `exit(2)` if required config is missing
3. Check mandatory args before executing business logic

### File Operations
- Use `File.existsSync()` before file operations
- Throw descriptive exceptions if files don't exist
- Use `.split("/").last` to get filename from path

### Argument Parsing
- Use `command.wasParsed('flag')` to check if flag was provided
- Use `command['option']` to get option value
- Use `command.command?.name` to get subcommand name

### Async Patterns
- Prefer `.then()` and `.catchError()` over try/catch for CLI commands
- Always handle errors gracefully with user-friendly messages
- Use `Future<bool>` for operations that can succeed or fail

### String Conventions
- Always use single quotes for strings (Dart convention)
- Use string interpolation: `'Value: $variable'` or `'Value: ${expression}'`

## Quick Reference

### Command Examples
```bash
# Sourcemap upload (Flutter)
dart run bin/raygun_cli.dart sourcemap -p flutter \
  --uri=https://example.com/main.dart.js \
  --app-id=XXX --token=YYY

# Sourcemap upload (single file)
dart run bin/raygun_cli.dart sourcemap \
  --input-map=path/to/index.js.map \
  --uri=https://example.com/index.js \
  --app-id=XXX --token=YYY

# Symbols upload
dart run bin/raygun_cli.dart symbols upload \
  --path=app.android-arm64.symbols \
  --version=1.0.0 \
  --app-id=XXX --token=YYY

# Symbols list
dart run bin/raygun_cli.dart symbols list \
  --app-id=XXX --token=YYY

# Symbols delete
dart run bin/raygun_cli.dart symbols delete \
  --id=2c7a3u3 \
  --app-id=XXX --token=YYY

# Deployments tracking
dart run bin/raygun_cli.dart deployments \
  --version=1.0.0 \
  --token=YYY \
  --api-key=ZZZ \
  --scm-type=GitHub \
  --scm-identifier=abc123

# Proguard upload
dart run bin/raygun_cli.dart proguard \
  --app-id=XXX \
  --version=1.0.0 \
  --path=mapping.txt \
  --external-access-token=EAT \
  --overwrite

# iOS dSYM upload
dart run bin/raygun_cli.dart dsym \
  --app-id=XXX \
  --path=path/to/dsym.zip \
  --external-access-token=EAT
```

### Environment Variables
```bash
export RAYGUN_APP_ID=your-app-id
export RAYGUN_TOKEN=your-token
export RAYGUN_API_KEY=your-api-key
```

## Known TODOs & Future Improvements
- Config file support (.raygun.yaml or similar) - see `lib/src/config_props.dart:9`
- NodeJS sourcemap platform support (currently stubbed in sourcemap command)
- System package manager installations (brew, apt, etc.)

## Troubleshooting

### Mock Generation Issues
- Ensure `@GenerateMocks` annotation is present in test file
- Run `dart pub get` to ensure dependencies are installed
- Clean and rebuild: `dart run build_runner clean && dart run build_runner build`

### Build Issues
- Ensure Dart SDK version matches `pubspec.yaml` requirement (^3.5.0)
- Run `dart pub get` to update dependencies
- Check that version in `bin/raygun_cli.dart` matches `pubspec.yaml`

### Test Failures
- Verify mocks are regenerated after API changes
- Check that mock behavior is properly stubbed with `when()`
- Ensure async tests use `async/await` or return Future
