class LogMethod::OpenTelemetryAfterLog
  def self.call(class_thats_logging_name, method_name, object_id, object_class_name, trace_id, current_actor_id, log_message)
    current_actor_id_attribute = "app.#{LogMethod.config.current_actor_id_label}"

    OpenTelemetry::Trace.current_span.add_event(
      log_message,
      attributes: {
        "log_method.class_name"        => class_thats_logging_name,
        "log_method.method_name"       => method_name,
        "log_method.object_id"         => object_id,
        "log_method.object_class_name" => object_class_name,
        "app.trace_id"                 => trace_id,
        current_actor_id_attribute     => current_actor_id,
      }
    )
  end
end

