# AWS Monitoring

## CloudWatch Alarms

Every production service needs:

| Metric | Threshold | Action |
|--------|-----------|--------|
| `5XXError` > 0 | 1 evaluation | Pager (SNS → on-call) |
| `Latency p99` > 500ms | 3 of 5 periods | Ticket |
| `CPUUtilization` > 80% | 15 min sustained | Auto-scale or alert |
| `ErrorCount` > baseline*2 | 5 min | Debug |
| `UnhealthyHostCount` > 0 | 2 evaluations | Pager |

## RED Method

- **Rate**: requests/sec
- **Errors**: failed requests/sec
- **Duration**: latency p50, p95, p99

## Dashboard Structure

```
/production/
  /compute/     — EC2/ECS CPU, memory, network
  /data/        — RDS connections, IOPS, replication lag
  /app/         — Service RED metrics per endpoint
  /cost/        — Daily/MTD spend by account, service
```

## Logging Requirements

- All services: structured JSON logs
- Log retention: 30d (dev), 90d (staging), 365d+ (production)
- CloudTrail: enabled in all regions, log to S3 + CloudWatch
- S3 access logs: enabled for sensitive buckets
- VPC Flow Logs: enabled for all VPCs
- ALB/NLB access logs: enabled for all load balancers

## Terraform Pattern

```hcl
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.service_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  tags = {
    Environment = var.environment
  }
}
```
