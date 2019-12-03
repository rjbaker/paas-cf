RSpec.describe "diego" do
  context "with the default certificates" do
    let(:manifest) { manifest_with_defaults }
    let(:properties) { manifest.fetch("instance_groups.diego-cell.jobs.rep.properties") }

    it "has containers configured" do
      expect(properties.dig("containers")).not_to be_nil
    end

    it "has containers/proxy enabled" do
      expect(properties.dig("containers", "proxy", "enabled")).to be(true)
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
end
