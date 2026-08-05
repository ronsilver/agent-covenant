<!-- [DOMAIN-SPECIFIC] This reference contains third-party fulfillment platform integration patterns. Kept for historical context. Not part of the generic Java skill. For general Spring Boot patterns, see the main SKILL.md. -->
# Third-Party Plugin Integration Patterns

## Plugin Interface
```java
public class CarrierFulfillmentPlugin implements FulfillmentPluginApi {
    @Override
    public FulfillmentTransactionInfoPlugin reserveInventory(...) { }
    @Override
    public FulfillmentTransactionInfoPlugin dispatchShipment(...) { }
    @Override
    public FulfillmentTransactionInfoPlugin returnShipment(...) { }
}
```

## Fulfillment Plan Lifecycle
- CREATE: provision new fulfillment plan
- CHANGE: upgrade/downgrade plan
- CANCEL: deactivate fulfillment plan
- PAUSE/RESUME: temporary suspension

## Webhook Handling
- Validate HMAC signature: third-party fulfillment platform signs webhooks
- Idempotent processing: check event_id before processing
- Async: never block the fulfillment platform's event loop

## Database
Third-party fulfillment platform uses MySQL. InnoDB engine. Buffer pool sized for active dataset.
