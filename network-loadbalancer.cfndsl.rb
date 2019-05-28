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

  targetgroups.each do |tg_name, params|

    ElasticLoadBalancingV2_TargetGroup("#{tg_name}TargetGroup") {
      VpcId Ref(:VpcId)
      Protocol 'TCP'
      Port params['port']

      TargetType params['type'] if params.has_key?('type')

      if params.has_key?('type') and params['type'] == 'ip' and params.has_key? 'target_ips'
        Targets (params['target_ips'].map {|ip|  { 'Id' => ip['ip'], 'Port' => ip['port'] }})
      end

      if params.has_key?('attributes')
        TargetGroupAttributes params['attributes'].map { |key,value| { Key: key, Value: value } }
      end

      if params.has_key?('healthcheck')
        HealthCheckPort params['healthcheck']['port'] if params['healthcheck'].has_key?('port')
        HealthCheckProtocol 'TCP'
        HealthCheckIntervalSeconds params['healthcheck']['interval'] if params['healthcheck'].has_key?('interval')
        HealthCheckTimeoutSeconds params['healthcheck']['timeout'] if params['healthcheck'].has_key?('timeout')
        HealthyThresholdCount params['healthcheck']['heathy_count'] if params['healthcheck'].has_key?('heathy_count')
        UnhealthyThresholdCount params['healthcheck']['unheathy_count'] if params['healthcheck'].has_key?('unheathy_count')
      end

      Tags default_tags
    }
  end if defined? targetgroups

  listeners.each do |listener_name, params|

    ElasticLoadBalancingV2_Listener("#{listener_name}Listener") {
      Protocol params['protocol'].upcase
      Port params['port']
      LoadBalancerArn Ref(:NetworkLoadBalancer)

      if params['protocol'].upcase == 'TLS'
        certificate = params['certificates'].shift()
        puts  certificate
        Certificates [{ CertificateArn: FnSub("${#{certificate}}") }]
        SslPolicy params['ssl_policy'] if params.has_key?('ssl_policy')
      end

      DefaultActions ([
          TargetGroupArn: Ref("#{params['targetgroup']}TargetGroup"),
          Type: "forward"
      ])
    }

    if (params.has_key?('certificates')) && (params['protocol'].upcase == 'TLS') && (params['certificates'].any?)
      ElasticLoadBalancingV2_ListenerCertificate("#{listener_name}ListenerCertificate") {
        Certificates params['certificates'].map { |certificate| { CertificateArn: FnSub("${#{certificate}}") }  }
        ListenerArn Ref("#{listener_name}Listener")
      }
    end

  end if defined? listeners

  records.each do |record|
    name = (['apex',''].include? record) ? dns_format : "#{record}.#{dns_format}."
    Route53_RecordSet("#{record.gsub('*','Wildcard').gsub('.','Dot').gsub('-','')}LoadBalancerRecord") do
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
