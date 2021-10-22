require "log_method"


RSpec.describe LogMethod::Log do
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
  class SomeActiveRecord < ActiveRecord::Base
    def initialize(id)
      @id = id
    end
    def id
      @id
    end
  end
  module Bugsnag
    def self.leave_breadcrumb(*)
      Object.new
    end
    class Breadcrumbs
      LOG_BREADCRUMB_TYPE = "LOG_BREADCRUMB_TYPE"
    end
  end
  describe "#log" do
    let(:logger) { double("Logger") }
    let(:admin_user_id) { "00000-0000-00000" }

    subject(:object) { ThingThatLogs.new }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)
      allow(Bugsnag).to receive(:leave_breadcrumb)

      Thread.current.thread_variable_set("trace_id",nil)
      Thread.current.thread_variable_set("current_user_id",nil)

      LogMethod.config do |c|
        c.trace_id_proc = -> () {
          Thread.current.thread_variable_get("trace_id")
        }
        c.current_actor_proc = ->() {
          Thread.current.thread_variable_get("current_user_id")
        }
        c.current_actor_id_label = "current_user_id"
        c.external_identifier_method = :external_id
        c.after_log_proc = ->(class_thats_logging_name, method_name, object_id, object_class_name, trace_id, current_actor_id) {
          Bugsnag.leave_breadcrumb method_name.to_s[0..29], {
            class: class_thats_logging_name,
            object_id: object_id,
            object_class: object_class_name,
            trace_id: trace_id,
            admin_user_id: current_actor_id
          }, Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
        }
      end

    end

    context "no trace id nor admin user id" do
      it "logs a message and sends a bugsnag breadcrumb" do
        object.log :some_method, "this is a test message"

        aggregate_failures do
          expect(logger).to have_received(:info).with(/ThingThatLogs/)
          expect(logger).to have_received(:info).with(/some_method/)
          expect(logger).to have_received(:info).with(/this is a test message/)
          expect(Bugsnag).to have_received(:leave_breadcrumb).with(
            "some_method",
            {
              class: "ThingThatLogs",
              object_class: nil,
              object_id: nil,
              trace_id: nil,
              admin_user_id: nil,
            },
            Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
          )
        end
      end
    end

    context "with a trace id and admin user id" do

      it "logs a message that includes those ids and sends a bugsnag breadcrumb" do
        trace_id = "some-test-trace-id"
        current_user_id = "some-user-id"
        Thread.current.thread_variable_set("trace_id",trace_id)
        Thread.current.thread_variable_set("current_user_id",current_user_id)

        object.log :some_method, "this is a test message"

        aggregate_failures do
          expect(logger).to have_received(:info).with(/ThingThatLogs/)
          expect(logger).to have_received(:info).with(/trace_id:#{trace_id}/)
          expect(logger).to have_received(:info).with(/current_user_id:#{current_user_id}/)
          expect(logger).to have_received(:info).with(/some_method/)
          expect(logger).to have_received(:info).with(/this is a test message/)
          expect(Bugsnag).to have_received(:leave_breadcrumb).with(
            "some_method",
            {
              class: "ThingThatLogs",
              object_class: nil,
              object_id: nil,
              trace_id: trace_id,
              admin_user_id: current_user_id,
            },
            Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
          )
        end
      end
    end

    it "truncates the method name for Bugsnag to avoid an annoying warning" do
      trace_id = "some-test-trace-id"

      object.log :some_method_name_that_is_really_long_and_bothers_bugsnag_but_its_cool, "this is a test message"

      aggregate_failures do
        expect(logger).to have_received(:info).with(/ThingThatLogs/)
        expect(logger).to have_received(:info).with(/some_method/)
        expect(logger).to have_received(:info).with(/this is a test message/)
        expect(Bugsnag).to have_received(:leave_breadcrumb).with(
          "some_method_name_that_is_reall",
          {
            class: "ThingThatLogs",
            object_class: nil,
            object_id: nil,
            trace_id: nil,
            admin_user_id: nil,
          },
          Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
        )
      end
    end

    context "when an object with an external_id is given" do
      it "logs the message with the external_id and sends it as a breadcrumb to Bugsnag" do
        external_id = "some external id"
        object.log :some_method, ThingWithExternalId.new(external_id), "this is a test message"

        aggregate_failures do
          expect(logger).to have_received(:info).with(/ThingThatLogs/)
          expect(logger).to have_received(:info).with(/some_method/)
          expect(logger).to have_received(:info).with(/this is a test message/)
          expect(logger).to have_received(:info).with(/#{external_id}/)
          expect(Bugsnag).to have_received(:leave_breadcrumb).with(
            "some_method",
            {
              class: "ThingThatLogs",
              object_class: ThingWithExternalId.name,
              object_id: external_id,
              trace_id: nil,
              admin_user_id: nil,
            },
            Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
          )
        end
      end
    end

    context "when an active record without a external id is given" do
      it "logs the message with the id and class and sends it as a breadcrumb to Bugsnag" do
        id = 42
        active_record = SomeActiveRecord.new(id)

        object.log :some_method, active_record, "this is a test message"

        aggregate_failures do
          expect(logger).to have_received(:info).with(/ThingThatLogs/)
          expect(logger).to have_received(:info).with(/SomeActiveRecord\/42/)
          expect(logger).to have_received(:info).with(/some_method/)
          expect(logger).to have_received(:info).with(/this is a test message/)
          expect(Bugsnag).to have_received(:leave_breadcrumb).with(
            "some_method",
            {
              class: "ThingThatLogs",
              object_class: SomeActiveRecord.name,
              object_id: active_record.id,
              trace_id: nil,
              admin_user_id: nil,
            },
            Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
          )
        end
      end
    end

    context "when an object without a external_id that is not an active record is given" do

      it "logs a message with a non_external_id object's inspect output" do
        inspect_output = "Some output from inspect"

        object.log :some_method, ThingWithoutExternalId.new(inspect_output), "this is a test message"

        aggregate_failures do
          expect(logger).to have_received(:info).with(/ThingThatLogs/)
          expect(logger).to have_received(:info).with(/#{inspect_output}/)
          expect(logger).to have_received(:info).with(/some_method/)
          expect(logger).to have_received(:info).with(/this is a test message/)
          expect(Bugsnag).to have_received(:leave_breadcrumb).with(
            "some_method",
            {
              class: "ThingThatLogs",
              object_class: ThingWithoutExternalId.name,
              object_id: inspect_output,
              trace_id: nil,
              admin_user_id: nil,
            },
            Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
          )
        end
      end
    end
  end
end
