# network-loadbalancer CfHighlander component

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | string
| EnvironmentType | Tagging | development | true | string | ['development','production']
| VPCId | Security Groups | None | false | AWS::EC2::VPC::Id
| DnsDomain | DNS domain to use | None | true | string
| SubnetIds | list of subnets | None | false | CommaDelimitedList
| SecurityGroupIds | list of security group ids | None | false | CommaDelimitedList
| SslCertId | ACM certificate ID | None | false | string (arn)
| WebACLArn | ACL to use on the load balancer | None | false | string
| HostedZoneId | Route53 Zone ID | None | false | string (arn)

`HostedZoneId` is ONLY used if `use_zone_id` is True.


## Outputs/Exports

| Name | Value | Exported |
| ---- | ----- | -------- |
| {tg_name}TargetGroup | Target Group Name | true
| {listener_name}Listener | Listener Name | true
| LoadBalancer | Load Balancer ARN | true
| LoadBalancerDNSName | Load Balancer URL | true
| LoadBalancerCanonicalHostedZoneID | Load Balancer Hosted Zone ID | true

## Example Configuration
### Highlander
```
Component name: 'networkloadbalancer', template: 'networkloadbalancer'
    parameter name: 'DnsDomain', value: root_domain
    parameter name: 'SubnetIds', value: cfout('vpcv2', 'PublicSubnets')
    parameter name: 'SecurityGroupIds', value: 'security_group1_id, security_group2_id'
    parameter name: 'VPCId', value: cfout('vpcv2', 'VPCId')
    parameter name: 'SslCertId', value: cfout('acmv2', 'CertificateArn')
end
```

## Cfhighlander Setup

install cfhighlander [gem](https://github.com/theonestack/cfhighlander)

```bash
gem install cfhighlander
```

or via docker

```bash
docker pull theonestack/cfhighlander
```
## Testing Components

Running the tests

```bash
cfhighlander cftest network-loadbalancer
```
