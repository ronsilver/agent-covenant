# Single-Table Design

| PK | SK | GSI1PK | GSI1SK | Attrs |
|---|---|---|---|---|
| WH#ID | METADATA | | | name, status |
| WH#ID | SHP#ID | SHP#ID | STATUS | quantity, cur |

PK=entity, SK=sub-entity. GSI overloaded for different query patterns.
Access patterns FIRST, then design table. NEVER use Scan.
