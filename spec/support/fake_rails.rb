require "active_support/tagged_logging"
major,minor,_ = RUBY_VERSION.split(/\./).map(&:to_i)
if (major > 2) || ((major == 2) && (minor > 6))
  require "active_support/isolated_execution_state"
end
module Rails
  def self.logger
    ActiveSupport::TaggedLogging.new(Logger.new($stdout))
  end
end
module ActiveRecord
  class Base
    def id
      "fake id"
    end
  end
end

