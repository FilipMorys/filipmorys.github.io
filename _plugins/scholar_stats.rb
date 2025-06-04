# _plugins/scholar_stats.rb
require "open-uri"
require "nokogiri"
require "uri"

module Jekyll
  class ScholarStats < Generator
    priority :low      # run late, after site.data is set up
    safe     true

    # Your Google Scholar ID
    SCHOLAR_ID  = "kow6dIkAAAAJ&hl".freeze
    SCHOLAR_URL = "https://scholar.google.com/citations?hl=en&user=".freeze

    # Domains that should never be fetched inside CI
    BLOCKED_HOSTS = %w[medium.com].freeze

    def generate(site)
      url  = SCHOLAR_URL + SCHOLAR_ID
      host = URI(url).host

      # ------------------------------------------------------------------
      # 1. Skip any URL whose host is on the block-list
      # ------------------------------------------------------------------
      if BLOCKED_HOSTS.any? { |d| host&.end_with?(d) }
        Jekyll.logger.info "scholar_stats:", "Skipping blocked host #{host}"
        site.data["scholar"] = { "id" => SCHOLAR_ID, "note" => "fetch skipped" }
        return
      end

      # ------------------------------------------------------------------
      # 2. Fetch the page (pretend to be a browser) — rescue HTTP errors
      # ------------------------------------------------------------------
      html = begin
        URI.open(url, "User-Agent" => "Mozilla/5.0").read
      rescue OpenURI::HTTPError => e
        Jekyll.logger.warn "scholar_stats:", "HTTP error #{e.message} when fetching #{url}"
        site.data["scholar"] = { "id" => SCHOLAR_ID, "error" => e.message }
        return
      end

      # ------------------------------------------------------------------
      # 3. Parse the citation table and stash the metrics in site.data
      # ------------------------------------------------------------------
      doc      = Nokogiri::HTML(html)
      tbl      = doc.css("table").first
      tbl_data = { "id" => SCHOLAR_ID }

      # Each row contains (“Citations”, “h-index”, “i10-index”, …)
      tbl.css("tr")[1..].each do |tr|
        cells = tr.css("td").map(&:text)
        key   = cells[0].downcase.tr("-", "_")   # “h-index” → “h_index”
        tbl_data[key] = cells[1].to_i
      end

      site.data["scholar"] = tbl_data
    end
  end
end
