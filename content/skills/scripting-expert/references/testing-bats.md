# bats-core Testing

## Test File
```bash
#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
    export APP_ENV="test"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

@test "script exits 0 on valid input" {
    run ./process.sh --value 1000 --type standard
    [ "${status}" -eq 0 ]
    [ "${output}" = "OK" ]
}

@test "script exits non-zero on missing required arg" {
    run ./process.sh --type standard
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"value is required"* ]]
}

@test "script is idempotent" {
    run ./init.sh --env staging
    [ "${status}" -eq 0 ]
    run ./init.sh --env staging
    [ "${status}" -eq 0 ]
}
```

## Run Tests
```bash
bats tests/
bats --recursive tests/
bats --filter "idempoten" tests/
```

## ShellCheck Integration
```bash
find . -name "*.sh" -not -path "*/vendor/*" -exec shellcheck {} +
```

## CI Integration
```yaml
- name: Shell Tests
  run: |
    shellcheck **/*.sh
    bats tests/
```
