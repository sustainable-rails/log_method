module LogMethod::Log
  def logging_external_identifier_method
    @logging_external_identifier_method ||=  LogMethod.config.external_identifier_method
  end

  def log(method, message_or_object, message=nil)
    trace_id = LogMethod.config.trace_id_proc.()
    current_actor_id = LogMethod.config.current_actor_proc.()

    message = if message.nil?
                message_or_object
              else
                object_id,object_class = if !logging_external_identifier_method.nil? &&
                                            message_or_object.respond_to?(logging_external_identifier_method)

                                           [message_or_object.send(logging_external_identifier_method), message_or_object.class]

                                         elsif message_or_object.kind_of?(ActiveRecord::Base)

                                           [message_or_object.id, message_or_object.class]

                                         else

                                           [message_or_object.inspect, message_or_object.class]

                                         end
                "[#{object_class}/#{object_id}]: #{message}"
              end

    Rails.logger.info("[#{self.class}##{method}](via LogMethod::Log)#{format_trace_id(trace_id)}#{format_current_actor_id(current_actor_id)}: #{message}")

    LogMethod.config.after_log_proc.(self.class.name, method, object_id, object_class&.name, trace_id, current_actor_id)
  end

private

  def format_trace_id(trace_id)
    return nil if trace_id.nil?
    " trace_id:#{trace_id} "
  end

  def format_current_actor_id(current_actor_id)
    return nil if current_actor_id.nil?
    " #{LogMethod.config.current_actor_id_label}:#{current_actor_id} "
  end
end
