# C4 Model Quick Reference

## Level 1: System Context (everyone)
```
graph TB
    User((User)) --> System[Order Creation]
    System --> Ext[External Service]
    System --> Bank[Acquiring Bank]
```
Shows: system + users + external systems. Audience: everyone.

## Level 2: Container (technical)
```
graph TB
    User-->Web[SPA: React]
    Web-->API[API: Go/Python]
    API-->DB[(PostgreSQL)]
    API-->Cache[(Redis)]
```
Shows: apps, databases, file systems. Audience: technical stakeholders.

## Level 3: Component (dev team)
```
graph TB
    API-->Auth[Auth Component]
    API-->Shp[Shipment Component]
    API-->Notify[Notification Component]
```
Shows: modules, services, APIs. Audience: development team.

## Level 4: Code (developers)
Auto-generated from source (UML class diagrams). Audience: developers.

## Mermaid C4 Syntax
```mermaid
C4Context
  Person(user, "Shopper")
  System(processor, "Processing System")
  System_Ext(carrier, "Fulfillment Provider")
  Rel(user, processor, "Submits to")
  Rel(processor, ext, "Connects via")
```
