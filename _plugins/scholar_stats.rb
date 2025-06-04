# _plugins/scholar_stats.rb
#
# Scrapes your Google-Scholar profile for basic metrics and stores them
# in site.data['scholar'].
# The begin‒rescue block makes the plugin fail-safe: if Google refuses
# the request (403, timeout, etc.) the build continues instead of dying.

require "open-uri"
require "nokogiri"

module Jekyll
  class ScholarStats < Generator
    safe     true   # tells Jekyll this plugin is safe for GitHub Pages
    priority :low   # run late so other site.data is already loaded

    # -- customise this with *your* Scholar ID ---------------------------
    SCHOLAR_ID  = "kow6dIkAAAAJ&hl".freeze
    # --------------------------------------------------------------------
    SCHOLAR_URL = "https://scholar.google.com/citations?hl=en&user=".freeze

    def generate(site)
      # ---------------------------------------------------------------
      # 1. Fetch the HTML (pretend to be a browser) — catch HTTP errors
      # ---------------------------------------------------------------
      html = begin
        URI.open(
          SCHOLAR_URL + SCHOLAR_ID,
          "User-Agent" => "Mozilla/5.0"   # avoids some bot blocks
        ).read
      rescue OpenURI::HTTPError, SocketError => e
        Jekyll.logger.warn "scholar_stats:", "Could not fetch data (#{e.message}); skipping."
        return            # exit plugin, let the rest of the site build
      end

      # ---------------------------------------------------------------
      # 2. Parse the citation-metrics table
      # ---------------------------------------------------------------
      doc = Nokogiri::HTML(html)
      tbl = doc.css("table").first
      return unless tbl                    # layout change = just skip

      data = { "id" => SCHOLAR_ID }

      tbl.css("tr")[1..].each do |tr|
        cells = tr.css("td").map(&:text)
        next if cells.size < 2
        key        = cells[0].downcase.tr("-", "_")  # "h-index" → "h_index"
        data[key]  = cells[1].to_i
      end

      # ---------------------------------------------------------------
      # 3. Expose the hash to Liquid templates: {{ site.data.scholar }}
      # ---------------------------------------------------------------
      site.data["scholar"] = data
    end
  end
end
