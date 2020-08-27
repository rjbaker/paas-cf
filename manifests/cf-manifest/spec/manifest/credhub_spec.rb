RSpec.describe "credhub" do
  let(:manifest) { manifest_with_defaults }
  let(:credhub_props) { manifest.fetch("instance_groups.credhub.jobs.credhub.properties.credhub") }
  let(:credhub_vm_extensions) { manifest.fetch("instance_groups.credhub.vm_extensions") }

  it "enables credhub" do
    expect { credhub_props }.not_to raise_error
  end

  describe "data_storage" do
    let(:data_storage_props) { credhub_props.dig("data_storage") }

    it "uses an external postgres db" do
      expect(data_storage_props.dig("type")).to eq("postgres")

      expect(data_storage_props.dig("host")).to eq(terraform_fixture_value("cf_db_address"))
      expect(data_storage_props.dig("port")).to eq(5432)

      expect(data_storage_props.dig("database")).to eq("credhub")
      expect(data_storage_props.dig("username")).to eq("credhub")

      expect(data_storage_props.dig("password")).to eq("((external_credhub_database_password))")
    end
  end

  describe "vm extensions" do
    it "is able to connect to cf rds database" do
      expect(credhub_vm_extensions).to include("cf_rds_client_sg")
    end
  end
end
