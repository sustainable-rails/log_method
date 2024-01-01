require "ostruct"
require "log_method"
require "log_method/paper_trail_current_actor"
require "support/fake_rails"
require "support/helper_classes"

RSpec.describe LogMethod::PaperTrailCurrentActor do

  module PaperTrail
    def self.request
      OpenStruct.new(whodunnit: "some actor id")
    end
  end
  describe "#call" do
    let(:log_dev) { StringIO.new }
    let(:logger) { Logger.new(log_dev, level: :info) }
    before do
      allow(Bugsnag).to receive(:leave_breadcrumb)
      allow(Logger).to receive(:new).and_return(logger)

      LogMethod.config.reset!
      LogMethod.config.current_actor_proc = LogMethod::PaperTrailCurrentActor
    end
    it "uses the whodunnit resulkts as the current actor" do

      ThingThatLogs.new.log :some_method, "test message"

      expect(log_dev.string).to match(/current_actor_id:some actor id/)
    end
  end
end
