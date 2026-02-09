### Implementing Dependency Injection in Core Libraries

#### 1. Modify Initialization Functions

Create `*_init` functions for each core library, allowing optional dependency
injection for external components like loggers, configuration handlers, or testing
stubs. Example for `oradba_env_parser.sh`:

```bash
function oradba_parser_init {
    local logger="$1"
    ORADBA_PARSER_LOGGER="$logger"
}
```

#### 2. Internal Logging Using Injected Logger

Replace direct logging calls with a private logging function that uses the injected logger:

```bash
function _oradba_log {
    if [[ -n "$ORADBA_LOGGER" ]]; then
        "$ORADBA_LOGGER" "$@"
    else
        echo "$@"
    fi
}
```

#### 3. Testing with Mock Dependencies

When testing libraries, inject mock logger functions to validate behavior without
relying on the actual logger. For instance:

```bash
mock_logger() {
    echo "[MOCK LOG] $*"
}
oradba_parser_init mock_logger
# Run tests...
```

#### 4. Backward Compatibility

Ensure all changes maintain backward compatibility by falling back to default
behavior if no dependencies are injected.
