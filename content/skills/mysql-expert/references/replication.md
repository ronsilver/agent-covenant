# MySQL Replication

## Master-Slave (Async)
- Reads scale to slaves
- Writes go to master
- Replication lag: seconds under normal load

## Group Replication (HA)
- 3+ nodes, single-primary mode
- Auto-failover on primary failure
- Paxos consensus for transaction ordering

## Aurora MySQL
- AWS managed replication
- Read replicas: <100ms lag typical
- Automated failover: <30 seconds

## Monitoring
```sql
SHOW SLAVE STATUS\G
SELECT SECONDS_BEHIND_MASTER;  -- replication lag
```
Alert if lag > 5 seconds for > 1 minute.
