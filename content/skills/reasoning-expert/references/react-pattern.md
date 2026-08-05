# ReAct Pattern (Reasoning + Acting)

## Loop
```
THOUGHT: [Analyze problem, form hypothesis]
ACTION: [Run diagnostic tool]
OBSERVATION: [Read tool output]
[Repeat until root cause found]
```

## Example Trace: Debug 500 Error
```
THOUGHT: 500 could be DB connection or backend timeout. Check DB first.
ACTION: grep "connection error" /var/log/api/*.log | head -20
OBSERVATION: 47 "connection refused" errors from PostgreSQL at 14:32.
THOUGHT: PostgreSQL was unreachable. Check if pod crashed.
ACTION: kubectl describe pod postgres-0
OBSERVATION: Pod restarted at 14:30 due to OOMKill (limit 256Mi).
ROOT CAUSE: Memory pressure killed PostgreSQL. Working set is 400Mi.
FIX: Increase memory limit to 512Mi.
```

## CoT vs ToT vs ReAct
| Pattern | Best For |
|---|---|
| CoT | Multi-step problems |
| ToT | Multiple alternatives to evaluate |
| ReAct | Tool-using agents, debugging |
