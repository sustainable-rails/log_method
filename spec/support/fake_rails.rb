require "active_support/tagged_logging"
require "active_support/isolated_execution_state"
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

