CloudFormation do

  default_tags = []
  default_tags << { Key: "Environment", Value: Ref("EnvironmentName") }
  default_tags << { Key: "EnvironmentType", Value: Ref("EnvironmentType") }

  tags.each do |key, value|
    default_tags << { Key: key, Value: value }
  end if defined? tags

  private = loadbalancer_scheme == 'internal' ? true : false

  ElasticLoadBalancingV2_LoadBalancer(:NetworkLoadBalancer) do
    Type 'network'

    if !private && static_ips
      SubnetMappings maximum_availability_zones.times.collect { |az| { SubnetId: FnSelect(az, Ref('SubnetIds')), AllocationId: Ref("Nlb#{az}EIPAllocationId") } }
    else
      Scheme 'internal' if private
      Subnets Ref('SubnetIds')
    end

    Tags default_tags
    unless loadbalancer_attributes.nil?
      LoadBalancerAttributes loadbalancer_attributes.map {|key,value| { Key: key, Value: value } }
    end
  end

  targetgroups.each do |tg_name, tg|

    ElasticLoadBalancingV2_TargetGroup("#{tg_name}TargetGroup") {
      VpcId Ref(:VpcId)
      Protocol 'TCP'
      Port tg['port']

      TargetType tg['type'] if tg.has_key?('type')

      if tg.has_key?('type') and tg['type'] == 'ip' and tg.has_key? 'target_ips'
        Targets (tg['target_ips'].map {|ip|  { 'Id' => ip['ip'], 'Port' => ip['port'] }})
      end

      if tg.has_key?('attributes')
        TargetGroupAttributes tg['attributes'].map { |key,value| { Key: key, Value: value } }
      end

      if tg.has_key?('healthcheck')
        HealthCheckPort tg['healthcheck']['port'] if tg['healthcheck'].has_key?('port')
        HealthCheckProtocol 'TCP'
        HealthCheckIntervalSeconds tg['healthcheck']['interval'] if tg['healthcheck'].has_key?('interval')
        HealthCheckTimeoutSeconds tg['healthcheck']['timeout'] if tg['healthcheck'].has_key?('timeout')
        HealthyThresholdCount tg['healthcheck']['heathy_count'] if tg['healthcheck'].has_key?('heathy_count')
        UnhealthyThresholdCount tg['healthcheck']['unheathy_count'] if tg['healthcheck'].has_key?('unheathy_count')
      end

      Tags default_tags
    }
  end

  records.each do |record|
    name = ('apex' || '')? dns_format : "#{record}.#{dns_format}."
    Route53_RecordSet("#{record.gsub('*','Wildcard').gsub('.','Dot')}LoadBalancerRecord") do
      HostedZoneName FnSub("#{dns_format}.")
      Name FnSub(name)
      Type 'A'
      AliasTarget ({
          DNSName: FnGetAtt(:NetworkLoadBalancer, :DNSName),
          HostedZoneId: FnGetAtt(:NetworkLoadBalancer, :CanonicalHostedZoneID)
      })
    end

  end if defined? records

end
