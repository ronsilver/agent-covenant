# Few-Shot Example Library

## SQL Generation
```
Input: "Units shipped by customer last month"
Output: {"sql": "SELECT user_id, SUM(score)/100.0 as total FROM events WHERE created_at > DATEADD(month, -1, SYSDATE()) GROUP BY 1 ORDER BY 2 DESC", "explanation": "Aggregates event scores by user for last month, ordered by total descending", "confidence": "high"}
```

## Data Field Extraction
```
Input: "The quantity field accepts integer counts and is required"
Output: {"field": "quantity", "type": "integer", "unit": "units", "required": true}

Input: "customerId is an optional alphanumeric identifier"
Output: {"field": "customerId", "type": "string", "required": false}
```

## Temperature Settings
| Task | Temp |
|---|---|
| SQL generation | 0.0 |
| Field extraction | 0.1 |
| Narrative report | 0.4 |
| Brainstorming | 0.7 |
