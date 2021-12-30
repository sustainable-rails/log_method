require "log_method"
require "log_method/open_telemetry_after_log"
require "support/fake_rails"
require "support/helper_classes"

RSpec.describe LogMethod::OpenTelemetryAfterLog do

  class FakeOpenTelemetrySpan
    attr_reader :log_message, :attributes

    def initialize
      @log_message = nil
      @attributes = nil
    end

    def add_event(log_message, attributes:)
      @log_message = log_message
      @attributes = attributes
    end

  end

  module OpenTelemetry
    module Trace
      def self.current_span
        @current_span ||= FakeOpenTelemetrySpan.new
      end
    end
  end

  describe "#call" do
    let(:logger) { double("Logger") }
    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)
      LogMethod.config.reset!
      LogMethod.config.after_log_proc = LogMethod::OpenTelemetryAfterLog
    end
    it "calls into OpenTelemetry's current_span's add_event method" do
      LogMethod.config.trace_id_proc = ->() { "some trace id" }
      LogMethod.config.current_actor_proc = ->() { "some actor id" }

      ThingThatLogs.new.log :some_method, SomeActiveRecord.new(42), "test message"


      fake_span = OpenTelemetry::Trace.current_span

      expect(fake_span.log_message).to                                eq("test message")
      expect(fake_span.attributes["log_method.class_name"]).to        eq(ThingThatLogs.name)
      expect(fake_span.attributes["log_method.method_name"]).to       eq(:some_method)
      expect(fake_span.attributes["log_method.object_id"]).to         eq(42)
      expect(fake_span.attributes["log_method.object_class_name"]).to eq(SomeActiveRecord.name)
      expect(fake_span.attributes["app.trace_id"]).to                 eq("some trace id")
      expect(fake_span.attributes["app.current_actor_id"]).to         eq("some actor id")
    end
    it "uses the current_actor_id_label if given" do
      LogMethod.config.trace_id_proc = ->() { "some trace id" }
      LogMethod.config.current_actor_proc = ->() { "some actor id" }
      LogMethod.config.current_actor_id_label = "user_id"

      ThingThatLogs.new.log :some_method, SomeActiveRecord.new(42), "test message"


      fake_span = OpenTelemetry::Trace.current_span

      expect(fake_span.attributes["app.user_id"]).to eq("some actor id")
    end
  end
end
