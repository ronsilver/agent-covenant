# Fowler's Refactoring Catalog (abridged)

## Composing Methods
- Extract Function: move code fragment to new method
- Inline Function: replace call with function body
- Extract Variable: assign expression to named variable

## Moving Features
- Move Function: move to class/module where it's used most
- Move Field: move field to better class
- Extract Class: split class with too many responsibilities

## Simplifying Conditionals
- Decompose Conditional: extract condition, then, else to functions
- Replace Nested Conditional with Guard Clauses: early return
- Replace Conditional with Polymorphism: strategy/state pattern

## API Refactoring
- Parameterize Function: merge similar functions with parameter
- Separate Query from Modifier: getter doesn't modify state
- Remove Flag Argument: boolean split into two explicit functions

## this project Constraints
- NEVER change public API signatures without migration plan
- ALWAYS same inputs -> same outputs
- ONE refactor at a time, run tests after each
