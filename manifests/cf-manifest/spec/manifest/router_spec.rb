RSpec.describe "router" do
  describe "gorouter" do
    let(:manifest) { manifest_with_defaults }
    let(:gorouter_props) { manifest.fetch("instance_groups.router.jobs.gorouter.properties.router") }

    it "has max_idle_connections set to disable keepalives" do
      expect(gorouter_props.dig("max_idle_connections")).to eq(0)
    end

    it "has ca_certs which is a superset of cf-deployment" do
      cfd_ca_certs = cf_deployment_manifest
        .dig("instance_groups")
        .find { |ig| ig["name"] == "router" }
        .dig("jobs")
        .find { |ig| ig["name"] == "gorouter" }
        .dig("properties", "router", "ca_certs")

      ca_certs = gorouter_props.fetch("ca_certs")

      expect(ca_certs).to include(cfd_ca_certs)
    end
  end
end
