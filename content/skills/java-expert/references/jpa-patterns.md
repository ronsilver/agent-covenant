# JPA/Hibernate Patterns

## Entity Design
```java
@Entity
@Table(name = "shipments")
public class Shipment {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(nullable = false)
    private BigDecimal quantity;
    @Enumerated(EnumType.STRING)
    private ShipmentStatus status;
}
```
MONEY = BigDecimal. NEVER double/float.

## Query Methods
```java
@Query("SELECT s FROM Shipment s WHERE s.customer.id = :customerId AND s.createdAt > :since")
List<Shipment> findByCustomerSince(@Param("customerId") UUID m, @Param("since") LocalDateTime s);
```
ALWAYS parameterized. NEVER string concatenation.

## N+1 Prevention
```java
@EntityGraph(attributePaths = {"customer", "items"})
List<Shipment> findByStatus(ShipmentStatus status);
```
Use @EntityGraph or JOIN FETCH for eager loading when needed.

## Caching
```java
@Cacheable("shipments")
@Entity
public class Shipment { ... }
```
Second-level cache via Hibernate + Redis/ehcache. Invalidate on update.
