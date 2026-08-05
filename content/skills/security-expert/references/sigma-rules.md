# Sigma Rules for Threat Hunting

## Unauthorized API Call from External IP
```yaml
title: Unauthorized API Call from External IP
logsource: aws_cloudtrail
detection:
  selection:
    sourceIPAddress|re: '^(?!10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)'
    errorCode: 'AccessDenied'
  condition: selection
fields: [sourceIPAddress, eventName, userAgent]
level: medium
tags: [attack.t1078]
```

## S3 Bucket Made Public
```yaml
title: S3 Bucket ACL Made Public
logsource: aws_cloudtrail
detection:
  selection:
    eventName: PutBucketAcl
    requestParameters.AccessControlPolicy.AccessControlList.Grant.Grantee.URI: 'http://acs.amazonaws.com/groups/global/AllUsers'
  condition: selection
level: critical
tags: [attack.t1530]
```

## IAM User Created Outside Business Hours
```yaml
detection:
  selection:
    eventName: CreateUser
  timeframe: 1h
  condition: selection and eventTime not between 08:00 and 18:00
level: medium
tags: [attack.t1136]
```
