# Spring Boot 3 Patterns

## Layered Architecture
```java
@RestController -> @Service -> @Repository
```
- Controller: parse, call service, return DTO (NEVER expose @Entity)
- Service: @Transactional, business logic
- Repository: JPA with Optional<T>

## Common Annotations
- @RestController: REST endpoint
- @Service: business logic bean
- @Transactional: transaction boundary (service layer only!)
- @ControllerAdvice: global error handling
- @ExceptionHandler: map exceptions to HTTP status

## Validation
```java
public record ShipmentDTO(
    @NotNull @Positive BigDecimal quantity,
    @NotBlank String category
) {}
```
@Valid on controller parameter triggers validation.
