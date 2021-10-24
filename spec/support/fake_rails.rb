# Don't want to have this gem depend on all of Rails just for testing
module Rails
  def self.logger
    Object.new
  end
end
module ActiveRecord
  class Base
    def id
      "fake id"
    end
  end
end

