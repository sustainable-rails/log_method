module LogMethod
end

require_relative "log_method/config"
require_relative "log_method/log"

module LogMethod
  def self.config(&block)
    @config ||= LogMethod::Config.new
    if !block.nil?
      block.(@config)
    end
    @config
  end
end
