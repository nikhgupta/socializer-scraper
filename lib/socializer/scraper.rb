require "uri"

require "anemone"

require "socializer/scraper/version"
require "socializer/scraper/extensions"
require "socializer/scraper/collector"
require "socializer/scraper/extractor"

module Socializer
  module Scraper
    # Your code goes here...
  end
end

module Anemone
  class Core
    #
    # Perform the crawl
    #
    def run
      process_options

      @urls.delete_if { |url| !visit_link?(url) }
      return if @urls.empty?

      link_queue = Queue.new
      page_queue = Queue.new

      @opts[:threads].times do
        @tentacles << Thread.new { Tentacle.new(link_queue, page_queue, @opts).run }
      end

      @urls.each{ |url| link_queue.enq(url) }

      loop do
        page = page_queue.deq
        @pages.touch_key page.url
        print "#{page.url} Queue: #{link_queue.size}" if @opts[:verbose]
        do_page_blocks page
        page.discard_doc! if @opts[:discard_page_bodies]

        links = links_to_follow page
        links.each do |link|
          link_queue << [link, page.url.dup, page.depth + 1]
        end
        @pages.touch_keys links

        @pages[page.url] = page

        # if we are done with the crawl, tell the threads to end
        if link_queue.empty? and page_queue.empty?
          until link_queue.num_waiting == @tentacles.size
            Thread.pass
          end
          if page_queue.empty?
            @tentacles.size.times { link_queue << :END }
            break
          end
        end
      end

      @tentacles.each { |thread| thread.join }
      do_after_crawl_blocks
      self
    end
  end
end
