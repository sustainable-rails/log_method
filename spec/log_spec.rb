require "log_method"
require "support/fake_rails"
require "support/helper_classes"

RSpec.describe LogMethod::Log do

  describe "#log" do
    let(:log_dev) { StringIO.new }
    let(:logger) { Logger.new(log_dev, level: :info, progname: "rspec") }

    before do
      allow(Logger).to receive(:new).and_return(logger)

      LogMethod.config.reset!
    end

    context "default behavior" do
      context "no object given" do
        it "logs the message, method name, and class" do
          object = ThingThatLogs.new
          object.log :some_method, "this is a test message"

          aggregate_failures do
            expect(log_dev.string).to match(/ThingThatLogs/)
            expect(log_dev.string).to match(/some_method/)
            expect(log_dev.string).to match(/this is a test message/)
          end
        end
      end
      context "object given" do
        context "object is an Active Record" do
          it "logs the id and class" do
            object = ThingThatLogs.new
            object.log :some_method, SomeActiveRecord.new(999), "this is a test message"

            aggregate_failures do
              expect(log_dev.string).to match(/SomeActiveRecord\/999/)
            end
          end
        end
        context "object is not an Active Record" do
          it "logs the class and the output of inspect" do
            inspect_output = "Some output from inspect"

            object = ThingThatLogs.new
            object.log :some_method, ThingWithoutExternalId.new(inspect_output), "this is a test message"

            aggregate_failures do
              expect(log_dev.string).to match(/ThingWithoutExternalId\/#{Regexp.escape(inspect_output)}/)
            end
          end
        end
      end
    end
    context "using after_log_proc" do
      context "no object given, no trace id, no current actor" do
        it "calls the proc with all info" do
          class_thats_logging_name_received = nil
          method_name_received              = nil
          object_id_received                = nil
          object_class_name_received        = nil
          trace_id_received                 = nil
          current_actor_id_received         = nil
          log_message_received              = nil

          LogMethod.config.after_log_proc = ->(class_thats_logging_name, method_name, object_id, object_class_name, trace_id, current_actor_id, log_message) {
            class_thats_logging_name_received = class_thats_logging_name
            method_name_received              = method_name
            object_id_received                = object_id
            object_class_name_received        = object_class_name
            trace_id_received                 = trace_id
            current_actor_id_received         = current_actor_id
            log_message_received              = log_message
          }

          object = ThingThatLogs.new
          object.log :some_method, "this is a test message"
          aggregate_failures do
            expect(class_thats_logging_name_received).to eq(ThingThatLogs.name)
            expect(method_name_received).to eq(:some_method)
            expect(object_id_received).to eq(nil)
            expect(object_class_name_received).to eq(nil)
            expect(trace_id_received).to eq(nil)
            expect(current_actor_id_received).to eq(nil)
            expect(log_message_received).to eq("this is a test message")
          end
        end
      end
      context "object given, trace id set up, current actor set up" do
        it "calls the proc with all info" do
          class_thats_logging_name_received = nil
          method_name_received              = nil
          object_id_received                = nil
          object_class_name_received        = nil
          trace_id_received                 = nil
          current_actor_id_received         = nil
          log_message_received              = nil

          LogMethod.config.trace_id_proc      = ->() { "some trace id" }
          LogMethod.config.current_actor_proc = ->() { "some user id" }
          LogMethod.config.after_log_proc = ->(class_thats_logging_name, method_name, object_id, object_class_name, trace_id, current_actor_id, log_message) {
            class_thats_logging_name_received = class_thats_logging_name
            method_name_received              = method_name
            object_id_received                = object_id
            object_class_name_received        = object_class_name
            trace_id_received                 = trace_id
            current_actor_id_received         = current_actor_id
            log_message_received              = log_message
          }

          object = ThingThatLogs.new
          object.log :some_method, SomeActiveRecord.new(42), "this is a test message"
          aggregate_failures do
            expect(class_thats_logging_name_received).to eq(ThingThatLogs.name)
            expect(method_name_received).to eq(:some_method)
            expect(object_id_received).to eq(42)
            expect(object_class_name_received).to eq(SomeActiveRecord.name)
            expect(trace_id_received).to eq("some trace id")
            expect(current_actor_id_received).to eq("some user id")
            expect(log_message_received).to eq("this is a test message")
          end
        end
      end
      context "object with external id given" do
        it "calls the proc with the external id" do
          class_thats_logging_name_received = nil
          method_name_received              = nil
          object_id_received                = nil
          object_class_name_received        = nil

          LogMethod.config.external_identifier_method = :external_id
          LogMethod.config.after_log_proc = ->(class_thats_logging_name, method_name, object_id, object_class_name, _trace_id, _current_actor_id,log_message) {
            class_thats_logging_name_received = class_thats_logging_name
            method_name_received              = method_name
            object_id_received                = object_id
            object_class_name_received        = object_class_name
          }

          object = ThingThatLogs.new
          object.log :some_method, ThingWithExternalId.new("some external id"), "this is a test message"
          aggregate_failures do
            expect(class_thats_logging_name_received).to eq(ThingThatLogs.name)
            expect(method_name_received).to eq(:some_method)
            expect(object_id_received).to eq("some external id")
            expect(object_class_name_received).to eq(ThingWithExternalId.name)
          end
        end
      end
      context "proc doesn't accept all params" do
        it "still works OK" do
          class_thats_logging_name_received = nil
          method_name_received              = nil
          object_id_received                = nil
          object_class_name_received        = nil
          trace_id_received                 = nil
          current_actor_id_received         = nil

          LogMethod.config.trace_id_proc      = ->() { "some trace id" }
          LogMethod.config.current_actor_proc = ->() { "some user id" }
          LogMethod.config.after_log_proc = ->(class_thats_logging_name, method_name, object_id, object_class_name, trace_id, current_actor_id) {
            class_thats_logging_name_received = class_thats_logging_name
            method_name_received              = method_name
            object_id_received                = object_id
            object_class_name_received        = object_class_name
            trace_id_received                 = trace_id
            current_actor_id_received         = current_actor_id
          }

          object = ThingThatLogs.new
          object.log :some_method, SomeActiveRecord.new(42), "this is a test message"
          aggregate_failures do
            expect(class_thats_logging_name_received).to eq(ThingThatLogs.name)
            expect(method_name_received).to eq(:some_method)
            expect(object_id_received).to eq(42)
            expect(object_class_name_received).to eq(SomeActiveRecord.name)
            expect(trace_id_received).to eq("some trace id")
            expect(current_actor_id_received).to eq("some user id")
          end
        end
      end
      context "assigning an array" do
        it "calls all of them" do
          class_thats_logging_name_received = []
          method_name_received              = []
          object_id_received                = []
          object_class_name_received        = []
          trace_id_received                 = []
          current_actor_id_received         = []
          log_message_received              = []

          LogMethod.config.trace_id_proc      = ->() { "some trace id" }
          LogMethod.config.current_actor_proc = ->() { "some user id" }
          proc1 = ->(class_thats_logging_name, method_name, object_id, object_class_name, trace_id, current_actor_id, log_message) {
            class_thats_logging_name_received << class_thats_logging_name
            method_name_received              << method_name
            object_id_received                << object_id
            object_class_name_received        << object_class_name
            trace_id_received                 << trace_id
            current_actor_id_received         << current_actor_id
            log_message_received              << log_message
          }
          proc2 = ->(class_thats_logging_name, method_name, object_id, object_class_name, trace_id, current_actor_id, log_message) {
            class_thats_logging_name_received << class_thats_logging_name
            method_name_received              << method_name
            object_id_received                << object_id
            object_class_name_received        << object_class_name
            trace_id_received                 << trace_id
            current_actor_id_received         << current_actor_id
            log_message_received              << log_message
          }
          LogMethod.config.after_log_proc = [ proc1, proc2 ]

          object = ThingThatLogs.new
          object.log :some_method, SomeActiveRecord.new(42), "this is a test message"
          aggregate_failures do
            expect(class_thats_logging_name_received).to eq( [ ThingThatLogs.name, ThingThatLogs.name ])
            expect(method_name_received).to eq( [ :some_method, :some_method ])
            expect(object_id_received).to eq( [ 42, 42 ])
            expect(object_class_name_received).to eq( [ SomeActiveRecord.name, SomeActiveRecord.name ])
            expect(trace_id_received).to eq( [ "some trace id", "some trace id" ])
            expect(current_actor_id_received).to eq( [ "some user id", "some user id" ])
            expect(log_message_received).to eq( [ "this is a test message", "this is a test message" ])
          end
        end
      end
    end
    context "using current_actor_proc" do
      context "using current_actor_id_label" do
        it "logs the current actor id and the configured label" do
          LogMethod.config.current_actor_proc = ->() { "some actor id" }
          LogMethod.config.current_actor_id_label = "user_id"

          object = ThingThatLogs.new
          object.log :some_method, "this is a test message"
          expect(log_dev.string).to match(/user_id:some actor id/)
        end
      end
      context "default current_actor_id_label" do
        it "logs the current actor id and the default label" do
          LogMethod.config.current_actor_proc = ->() { "some actor id" }

          object = ThingThatLogs.new
          object.log :some_method, "this is a test message"
          expect(log_dev.string).to match(/current_actor_id:some actor id/)
        end
      end
    end
    context "using external_identifier_method" do
      it "logs that identifier" do
        LogMethod.config.external_identifier_method = :external_id

        object = ThingThatLogs.new
        object.log :some_method, ThingWithExternalId.new("foobar id"), "this is a test message"
        expect(log_dev.string).to match(/foobar id/)
      end
    end
    context "using trace_id_proc" do
      it "logs the returned id" do
        LogMethod.config.trace_id_proc = ->() { "some trace id" }

        object = ThingThatLogs.new
        object.log :some_method, "this is a test message"
        expect(log_dev.string).to match(/some trace id/)
      end
    end
  end
end
