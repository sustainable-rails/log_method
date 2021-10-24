require_relative "fake_rails"
class ThingThatLogs
  include LogMethod::Log
end

class ThingWithExternalId

  attr_reader :external_id

  def initialize(external_id)
    @external_id = external_id
  end
end

class ThingWithoutExternalId

  def initialize(inspect_output)
    @inspect_output = inspect_output
  end

  def inspect
    @inspect_output
  end
end

class SomeActiveRecord < ActiveRecord::Base
  def initialize(id)
    @id = id
  end
  def id
    @id
  end
end

