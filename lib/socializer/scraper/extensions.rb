class Array

  def hash_collection?
    flatten.compact.reject{|v| v.is_a?(Hash)}.empty?
  end

  def collect_as_hash
    raise StandardError, "Array is not a hash collection!" unless hash_collection?
    flatten.compact.each_with_object(Hash.new([])) do |h1,h|
      h1.each{|k,v| h[k] = (h[k] | [v]).accumulate }
    end
  end

  def accumulate
    flatten.compact.uniq
  end

  def hashify_or_collect
    hash_collection? ? collect_as_hash : accumulate
  end

  def extract_options!
    last.is_a?(Hash) && last.instance_of?(Hash) ? pop : {}
  end
end

class Hash
  def hash_map &block
    Hash[self.map{|key, value| yield(key, value) }]
  end

  def hash_collection?
    true
  end

  def collect_as_hash
    self
  end
  alias :hashify_or_collect :collect_as_hash
end

class String
  def url?
    self =~ /^#{URI::regexp}$/
  end

  def blank?
    strip.empty?
  end
end

module URI

  class Generic
    def url?
      %w[ http https ].include?(scheme)
    end

    def mail?
      scheme == "mailto"
    end

    def absolute(host, scheme = nil)
      return self unless self.scheme.nil?
      path = to_s.start_with?("/") ? to_s : "/#{to_s}"
      URI.parse("#{scheme.blank? ? "http" : scheme}://#{host}#{path}")
    end

  end

  class HTTP
    def error?
      return :unknown unless url?
      puts "Testing URL: #{self}"
      req = Net::HTTP.new(host, port)
      req.use_ssl = is_a?(URI::HTTPS)
      res = req.request_head(path.empty? ? "/" : path)
      if res.kind_of?(Net::HTTPRedirection)
        URI.parse(res["location"]).absolute(host, scheme).error?
      else
        case
        when res.code == "401" || res.code == "407" then :unauthorized
        when res.code == "403" then :forbidden
        when res.code == "404" then :not_found
        when res.code[0] == "4" then :client_error
        when res.code == "503" then :temporary_server_error
        when res.code[0] == "5" then :server_error
        end
      end
    rescue ::Errno::ENOENT, ::SocketError
      :no_such_server
    end
  end
end

class Object
  def accumulate
    [ self ].accumulate
  end

  def blank?
    obj = obj.strip if respond_to?(:strip)
    obj.respond_to?(:empty?) ? obj.empty? : !obj
  end

  def present?
    !blank?
  end
end
