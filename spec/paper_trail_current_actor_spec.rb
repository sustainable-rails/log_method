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
    let(:logger) { double("Logger") }
    before do
      allow(Bugsnag).to receive(:leave_breadcrumb)
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)

      LogMethod.config.reset!
      LogMethod.config.current_actor_proc = LogMethod::PaperTrailCurrentActor
    end
    it "uses the whodunnit resulkts as the current actor" do

      ThingThatLogs.new.log :some_method, "test message"

      expect(logger).to have_received(:info).with(/current_actor_id:some actor id/)
    end
  end
end
