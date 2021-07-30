require 'yaml'

describe 'should fail without a task_definition' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/default.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/default/network-loadbalancer.compiled.yaml") }

  context 'Resource NLB' do

    let(:properties) { template["Resources"]["NetworkLoadBalancer"]["Properties"] }

    it 'has Properties' do
      expect(properties).to include({
        "Type"=>"network", 
        "Subnets" => {"Ref"=>"SubnetIds"},
        "Tags" => [{"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}],
      })
    end

  end

  
end