---
name: java-expert
description: "Enterprise development with Java 17+ and Spring Boot 3: REST controllers, JPA/Hibernate, Spring Security, testing with JUnit 5/Mockito/Testcontainers, and code quality with SpotBugs/Checkstyle. Use when building Spring Boot REST APIs, implementing JPA repositories, configuring Spring Security, writing integration tests with Testcontainers, or running static analysis. Trigger: Spring Boot, JPA Hibernate, JUnit 5, Mockito, Testcontainers, SpotBugs, Checkstyle. Do NOT trigger for: Go microservices, Python FastAPI services, general REST API design without Java."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: backend
  status: stable
---
# Java Expert

**Java ecosystem: Spring Boot 3, JPA, testing, and linting.**

## Core Stack

- Language: Java 17+ LTS (records, sealed classes, streams, virtual threads)
- Framework: Spring Boot 3.x
- Data: Spring Data JPA + Hibernate
- Security: Spring Security
- Background jobs: Spring @Async + @Scheduled
- Testing: JUnit 5 + Mockito + Testcontainers
- Build: Maven / Gradle
- Linting: SpotBugs + Checkstyle
- Logging: SLF4J / Logback

## Project Structure

```
src/main/java/com/example/<service>/
  controller/     # @RestController (thin)
  service/        # @Service (business logic, @Transactional here)
  repository/     # @Repository (JPA)
  model/          # @Entity + DTOs
  config/         # @Configuration beans
  exception/      # @ControllerAdvice global error handling
src/main/resources/
  application.yml
src/test/java/
  unit/
  integration/
```

## Architecture

```
Controller -> Service -> Repository
```

- Controllers: parse -> call service -> return DTO (NEVER expose @Entity)
- Service: transaction boundary (`@Transactional`), business logic
- Repository: JPA data access, return `Optional<T>`



## Workflow

1. Define `@Entity` + DTO (separate — never expose entity in API)
2. Implement `@Repository` (extend `JpaRepository`)
3. Implement `@Service` with `@Transactional` (transaction boundary here)
4. Implement `@RestController` (parse -> call service -> return DTO)
5. Add `@ControllerAdvice` for global error mapping
6. Write JUnit 5 + Mockito unit tests + Testcontainers integration tests

## Testing

```java
@SpringBootTest
@AutoConfigureMockMvc
class ItemControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ItemService itemService;

    @Test
    void shouldReturnCreated() throws Exception {
        when(itemService.process(any())).thenReturn(new ItemResponse("confirmed"));
        mockMvc.perform(post("/items")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"quantity\":5}"))
            .andExpect(status().isCreated());
    }
}
```

## Linting (Golden Chain)

```
mvn spotbugs:check -> mvn checkstyle:check -> mvn test
```
Stop on first failure. Never skip in CI.

## Constraints

- NEVER expose `@Entity` in REST responses — always use DTO
- NEVER business logic in `@RestController`
- NEVER `@Transactional` on controller methods — service layer only
- NEVER `double`/`float` for precise decimal values — ALWAYS `BigDecimal`
- ALWAYS validate inputs with `@Valid` + Bean Validation annotations
- ALWAYS use `Optional<T>` for nullable repository returns
- ALWAYS add `@ControllerAdvice` — never return raw exceptions
- ALWAYS use parameterized JPQL — never string concat in queries
- NEVER log passwords, tokens, sensitive data
- NEVER block request threads with sync long-running tasks — use @Async

## Overview

Java 17+ with Spring Boot 3 for production backend services. This skill covers REST APIs, JPA, Spring Security, async processing, and the testing/linting pipeline.

## Quick Reference

| Component | Technology | Role |
|---|---|---|
| API | Spring Boot 3 + @RestController | Parse requests, delegate to services |
| Data | Spring Data JPA + Hibernate | ORM mapping, repository layer |
| Background Jobs | Spring @Async + @Scheduled | Async processing, scheduled tasks |
| Testing | JUnit 5 + Mockito + Testcontainers | Unit + integration coverage |

## Anti-patterns

FAIL: Exposing JPA `@Entity` directly in REST response
PASS: Always map to DTO before serialization

```java
// FAIL:
@GetMapping("/items/{id}")
public ItemEntity getItem(@PathVariable Long id) { return repo.findById(id).orElseThrow(); }

// PASS:
@GetMapping("/items/{id}")
public ItemResponse getItem(@PathVariable Long id) {
    return service.toResponse(repo.findById(id).orElseThrow());
}
```

FAIL: `@Transactional` on controller method
PASS: Transaction boundary belongs in service layer only

```java
// FAIL:
@PostMapping("/items")
@Transactional
public ItemResponse create(@RequestBody ItemRequest req) { ... }

// PASS:
@Service
@Transactional
public class ItemService { ... }
```

FAIL: Using `double`/`float` for precise decimal values
PASS: Always use `BigDecimal` for money

```java
// FAIL: double amount = 19.99; → floating point errors
// PASS: BigDecimal value = new BigDecimal("19.99");
```

## References

- [Spring Boot Reference](https://docs.spring.io/spring-boot/documentation.html) (last_verified: 2026-05-25)
- [Spring Data JPA](https://docs.spring.io/spring-data/jpa/reference/) (last_verified: 2026-05-25)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/) (last_verified: 2026-05-25)

- [references/jpa-patterns.md](references/jpa-patterns.md)
- [references/third-party-plugin-integration.md](references/third-party-plugin-integration.md)
- [references/spring-boot-patterns.md](references/spring-boot-patterns.md)

## Verification Checklist

- [ ] `@Entity` classes never exposed directly in REST responses (always mapped to DTO)
- [ ] `@Transactional` annotations placed only on service layer (never on controllers)
- [ ] Precise decimal values use `BigDecimal` (never `double` or `float`)
- [ ] `@ControllerAdvice` class handles all exceptions (no raw exceptions returned)
- [ ] Inputs validated with `@Valid` and Bean Validation annotations
- [ ] Repository methods return `Optional<T>` for nullable queries

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `LazyInitializationException` | Entity accessed outside transactional context | Add `@Transactional` to service method or use `JOIN FETCH` in query |
| `ConstraintViolationException` without clear message | Missing `@Valid` or validation groups misconfigured | Add `@Valid` to controller `@RequestBody` parameter and check group sequence |
| plugin not receiving events | Plugin interface not fully implemented or registration missing | Verify all required plugin interfaces implemented and registered in `pom.xml` |
| Known issue: Hibernate N+1 on `@OneToMany` with FetchType.EAGER | Spring Data JPA loads all related entities eagerly in a loop | Use `FetchType.LAZY` + `@EntityGraph` or `JOIN FETCH`; add `spring.jpa.open-in-view=false` to detect lazy access early |

| [WARN] plugin `onEvent` not triggered for domain events | Plugin registered as item plugin but domain events go to different bus topic | Register plugin on `DomainEventTopic` or implement `DomainEventListenerService` |
