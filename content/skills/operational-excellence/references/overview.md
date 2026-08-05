# Operational Excellence Overview

## SRE Best Practices

Site Reliability Engineering (SRE) is about building and running scalable, reliable systems.

## Core Principles

### 1. Observability by Default
**"If it's not observable, it doesn't exist"**

Every service must emit:
- Structured logs (JSON)
- Metrics (RED: Rate, Errors, Duration)
- Distributed traces (OpenTelemetry)

### 2. Automation First
**"Toil should be eliminated"**

Toil is manual, repetitive work that:
- Scales linearly with service growth
- Has no enduring value
- Could be automated

**Target**: <50% of SRE time on toil

### 3. Fail Fast, Recover Faster
**"Design for failure"**

Principles:
- Circuit breakers for dependencies
- Graceful degradation
- Fast rollbacks (< 5 minutes)
- Chaos engineering

### 4. Blameless Postmortems
**"Focus on process improvement, not blame"**

After incidents:
- Document timeline
- Identify root causes (5 Whys)
- Create action items
- Share learnings

## SLO Framework

### Service Level Indicators (SLI)
Quantitative measures of service quality:
- Availability
- Latency
- Error rate
- Throughput

### Service Level Objectives (SLO)
Target values for SLIs:
- "99.9% of requests succeed"
- "95% of requests complete in < 200ms"

### Service Level Agreements (SLA)
Business contracts with consequences:
- "99.95% uptime guarantee"
- "Refunds if SLA breached"

**Relationship**: SLI (measure) → SLO (internal target) → SLA (external promise)

## Error Budgets

**Concept**: If SLO is 99.9%, you have 0.1% error budget

**Usage**:
- If error budget > 0: Can take risks, deploy faster
- If error budget exhausted: Focus on reliability
- Balance innovation vs. stability

## On-Call Rotation

**Best Practices**:
- 24/7 coverage
- Max 1 week on-call shifts
- Clear escalation paths
- Runbooks for all critical alerts
- Post-incident reviews
