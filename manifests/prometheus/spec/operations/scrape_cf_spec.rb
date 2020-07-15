RSpec.describe "Scrape CF directly" do
  let(:prometheus) do
    manifest_with_defaults.get("instance_groups.prometheus2.jobs.prometheus2")
  end

  let(:scrape_configs) do
    prometheus.dig("properties", "prometheus", "scrape_configs")
  end

  %w[
    api
    cc-worker
    diego-api
    diego-cell
    doppler
    log-api
    nats
    router
    scheduler
    uaa
  ].each do |ig|
    it "scrapes #{ig}" do
      job_name = "#{ig}-metrics-agent"
      scrape_config = scrape_configs.find { |sc| sc["job_name"] == job_name }
      dns_names = scrape_config
        .fetch("dns_sd_configs")
        .flat_map { |cfg| cfg["names"] }

      expect(dns_names).to all(eq("q-s0.#{ig}.*.test.bosh"))
    end
  end
end
