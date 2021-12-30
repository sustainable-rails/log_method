require "log_method"
require "log_method/bugsnag_after_log"
require "support/fake_rails"
require "support/helper_classes"

RSpec.describe LogMethod::BugsnagAfterLog do

  module Bugsnag
    def self.leave_breadcrumb(*)
      Object.new
    end
    class Breadcrumbs
      LOG_BREADCRUMB_TYPE = "LOG_BREADCRUMB_TYPE"
    end
  end
  describe "#call" do
    let(:logger) { double("Logger") }
    before do
      allow(Bugsnag).to receive(:leave_breadcrumb)
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)

      LogMethod.config.reset!
      LogMethod.config.after_log_proc = LogMethod::BugsnagAfterLog
    end
    it "calls into Bugsnag's leave_breadcrumb method" do
      LogMethod.config.trace_id_proc = ->() { "some trace id" }
      LogMethod.config.current_actor_proc = ->() { "some actor id" }

      ThingThatLogs.new.log :some_method, SomeActiveRecord.new(42), "test message"

      expect(Bugsnag).to have_received(:leave_breadcrumb).with(
        "some_method",
        {
          class: ThingThatLogs.name,
          object_id: 42,
          object_class: SomeActiveRecord.name,
          trace_id: "some trace id",
          current_actor_id: "some actor id",
        },
        Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
      )
    end
    it "calls uses the configured current_actor_id_label instead of current_actor_id, if set" do
      LogMethod.config.trace_id_proc = ->() { "some trace id" }
      LogMethod.config.current_actor_proc = ->() { "some actor id" }
      LogMethod.config.current_actor_id_label = "user_id"

      ThingThatLogs.new.log :some_method, SomeActiveRecord.new(42), "test message"

      expect(Bugsnag).to have_received(:leave_breadcrumb).with(
        "some_method",
        {
          class: ThingThatLogs.name,
          object_id: 42,
          object_class: SomeActiveRecord.name,
          trace_id: "some trace id",
          user_id: "some actor id",
        },
        Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
      )
    end
    it "truncates long method names because Bugsnag requires that" do
      method_name              = "abcdefghijklmnopqrstuvwxyz0123456789"

      ThingThatLogs.new.log method_name.to_sym, "test message"
      expect(Bugsnag).to have_received(:leave_breadcrumb).with(
        "abcdefghijklmnopqrstuvwxyz0123",
        instance_of(Hash),
        anything,
      )
    end
  end
end
