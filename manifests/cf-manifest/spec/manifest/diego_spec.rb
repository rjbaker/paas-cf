RSpec.describe "diego" do
  context "rep" do
    let(:manifest) { manifest_with_defaults }
    let(:rep_properties) { manifest.fetch("instance_groups.diego-cell.jobs.rep.properties") }

    it "has containers configured" do
      expect(rep_properties.dig("containers")).not_to be_nil
    end

    it "has containers/proxy enabled" do
      expect(rep_properties.dig("containers", "proxy", "enabled")).to be(true)
    end
  end

  describe "api instance" do
    subject(:instance) { manifest.fetch("instance_groups.diego-api") }

    let(:manifest) { manifest_with_defaults }

    it_behaves_like "a cf rds client"
  end

  describe "ipsec" do
    let(:racoon_props) { manifest_with_defaults.fetch("instance_groups.diego-cell.jobs.racoon.properties.racoon") }

    it "has ipsec enabled with router instances" do
      cell_network = racoon_props.dig("ports").find { |n| n["name"] == "cell" }
      router_cidrs = terraform_fixture_value("router_subnet_cidr_blocks")

      router_cidrs.each do |cidr|
        expect(cell_network["targets"]).to include(cidr), "cell network should include router cidr #{cidr}"
      end
    end

    it "has ipsec enabled with cell instances" do
      cell_network = racoon_props.dig("ports").find { |n| n["name"] == "cell" }
      cell_cidrs   = terraform_fixture_value("cell_subnet_cidr_blocks")

      cell_cidrs.each do |cidr|
        expect(cell_network["targets"]).to include(cidr), "cell network should include cell cidr #{cidr}"
      end
    end
  end

  context "silk-cni" do
    let(:silk_cni) { manifest_with_defaults.fetch("instance_groups.diego-cell.jobs.silk-cni") }

    it "overrides the vpa bosh link" do
      expect(silk_cni.dig('consumes', 'vpa')).to eq('from' => 'vpa-default')
    end

    let(:silk_cni_props) { manifest_with_defaults.fetch("instance_groups.diego-cell.jobs.silk-cni.properties") }

    it "accounts for the IPsec VPN when setting the MTU" do
      vm_mtu = 9001
      ipsec_overhead = 73

      mtu = silk_cni_props['mtu']
      expect(mtu).to be <= (vm_mtu - ipsec_overhead)
    end
  end

  context "silk-daemon" do
    let(:silk_daemon) { manifest_with_defaults.fetch("instance_groups.diego-cell.jobs.silk-daemon") }

    it "overrides the vpa bosh link" do
      expect(silk_daemon.dig('consumes', 'vpa')).to eq('from' => 'vpa-default')
    end
  end

  context "vxlan-policy-agent" do
    let(:vxlan_policy_agent) { manifest_with_defaults.fetch("instance_groups.diego-cell.jobs.vxlan-policy-agent") }

    it "overrides the vpa bosh link" do
      expect(vxlan_policy_agent.dig('provides', 'vpa')).to eq('as' => 'vpa-default')
    end
  end
end
