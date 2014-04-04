module Socializer
  module Scraper
    module Collector
      def email_collector

        at_re = "(@|\\s*[\\[|\\(|\\{](@|at)[\\]|\\)|\\}]\\s*)"
        dt_re = "(\\.|\\s*[\\[|\\(|\\{](\\.|dot)[\\]|\\)|\\}]\\s*)"
        regex = /([A-Z0-9._%-]+#{at_re}([A-Z0-9-]+#{dt_re})+[A-Z]{2,4})/i

        emails  = @page.body.scan(regex).map do |a|
          "mailto:" + a[0].gsub(a[1], "@").gsub(a[4], ".")
        end rescue []

        (emails | page_links).map do |e|
          uri = URI.parse(URI.encode(e)) rescue nil
          uri.to if uri.respond_to?(:to)
        end.compact
      end

      def sitemap_collector
        @current_url
      end

      def link_collector
        page_links.map do |link|
          begin
            uri = URI.parse(link).absolute(@url.host, @url.scheme)

            case
            when uri.url? && uri.host == @url.host then { internal: uri.to_s }
            when uri.url? then { external: link }
            when uri.scheme then { uri.scheme.to_sym => link }
            else { unknown: link }
            end
          rescue URI::InvalidURIError
            { unknown: link }
          end
        end.collect_as_hash
      end

      def live_link_collector
        page_links.map do |link|
          begin
            uri = URI.parse(link).absolute(@url.host, @url.scheme)

            case
            when uri.respond_to?(:error?) && (error = uri.error?)
              then { error => uri.to_s }
            when uri.url? && uri.host == @url.host
              then { internal: uri.to_s }
            when uri.url? then { external: link }
            when uri.scheme then { uri.scheme => link }
            else { unknown: link }
            end
          rescue URI::InvalidURIError
            { unknown: link }
          end
        end.collect_as_hash
      end

      def social_profile_collector options = {}
        default  = [ :facebook, :twitter, :github ]
        required = options.select{ |k, v| v}.keys
        allowed  = if options.empty?
                     default
                   elsif required.any?
                     required - (required - default)
                   else
                     default - options.keys
                   end

        allowed = allowed.map{ |a| { a => [] } }.collect_as_hash

        allowed.hash_map do |provider|
          regex = /#{provider}\.com\/[^\/]*$/
          links = page_links.map do |link|
            link =~ regex ? link : nil
          end.accumulate
          [provider, links]
        end
      end
    end
  end
end
