module Socializer
  module Scraper
    class Extractor

      include Socializer::Scraper::Collector

      attr_reader :url
      attr_writer :collectors

      def initialize options = {}
        self.url = options.fetch(:url, nil)
        self.collectors = options.fetch(:collectors, [])
      end

      # Set the URL to crawl for this Crawler instance.
      #
      # @param url [string] URL or domain name to crawl.
      # @return string url
      def url= url
        return unless url
        @url = URI.parse(url)
        message = "Please, provide a URL that starts with HTTP or HTTPS"
        raise URI::InvalidURIError, message unless @url.url?
      end

      def collectors
        @collectors.any? ? @collectors : self.class.available_collectors
      end

      def run *patterns, &block
        data, options = {}, patterns.extract_options!
        page_wise = options.delete(:page_wise)
        patterns  = patterns.push(options)

        perform(*patterns) do |page|
          collectors.each do |collector|
            found = send("#{collector}_collector")
            yield(page, collector, found) if block_given?
            if page_wise
              data[collector] ||= {}
              data[collector][@current_url] = found
            else
              data[collector] ||= []
              data[collector].push found
            end
          end
        end

        data.hash_map{|kind, list| [kind, list.hashify_or_collect]}
      end

      class << self
        def available_collectors
          self.instance_methods.select do |name|
            name.to_s.end_with?("_collector")
          end.map do |name|
            name.to_s.gsub(/_collector$/, '').to_sym
          end
        end
      end

      protected

      def page_html
        @html ||= Nokogiri::HTML(@page.body)
      end

      def page_links
        page_html.search("a").map{|a| a.attr("href")}.accumulate
      end

      private

      def perform *patterns, &block
        options = patterns.extract_options!
        message = "Please, provide a URL that starts with HTTP or HTTPS"
        raise URI::InvalidURIError, message unless @url.url?

        patterns.push(/.*/) if patterns.empty?

        Anemone.crawl(@url, options) do |anemone|
          anemone.threads = 4
          anemone.verbose = true
          anemone.obey_robots_txt = true
          anemone.accept_cookies = true
          anemone.user_agent = "Googlebot"
          anemone.storage = Anemone::Storage.MongoDB
          anemone.focus_crawl{|page| links_matching(page.links, patterns) }
          anemone.on_every_page do |page|
            @page, @html, @current_url = page, nil, page.url
            yield(page)
          end
        end
      end

      def links_matching links, patterns = []
        return links if patterns.empty?
        links.select do |link|
          patterns.detect{|p| link.to_s =~ p}
        end
      end
    end
  end
end
