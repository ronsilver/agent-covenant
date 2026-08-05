# Coding Standards (Generic)

## File Limits
- File: max 300 lines. If exceeded -> split by SRP.
- Function: max 50 lines. If exceeded -> extract to named helper.
- Parameters: max 5. If exceeded -> group into struct/object.
- Nesting: max 3 levels. If exceeded -> early return / guard clause.
- Exceptions: generated code, proto, fixtures (mark `# exceeds limit: generated`)

## Naming Conventions
### Go
- Packages: lowercase, single word (payment, auth, handler)
- Exported: PascalCase (ProcessPayment)
- Unexported: camelCase (validateAmount)
- Interfaces: single-method = -er suffix (Reader, Writer)

### Python
- Classes: PascalCase (PaymentService)
- Functions: snake_case (process_payment)
- Constants: UPPER_SNAKE_CASE (MAX_RETRIES)
- Private: _leading_underscore

### TypeScript
- Interfaces/Types: PascalCase (PaymentRequest)
- Functions: camelCase (processPayment)
- Constants: UPPER_SNAKE_CASE
- Files: kebab-case (api-service.ts)

## Code Quality
- DRY: 3+ repetitions -> extract function
- SOLID: each class/module, one responsibility
- Immutable by default (const, final, readonly)
- Prefer composition over inheritance
- Early return over deep nesting
