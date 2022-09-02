require "active_support/tagged_logging"

module LogMethod::Log
  def logging_external_identifier_method
    @logging_external_identifier_method ||=  LogMethod.config.external_identifier_method
  end

  def log(method, message_or_object, message=nil)

    trace_id         = LogMethod.config.trace_id_proc.()
    current_actor_id = LogMethod.config.current_actor_proc.()
    object_id        = nil
    object_class     = nil

    logger = Rails.logger.tagged("#{self.class}##{method}").tagged("via LogMethod::Log")
    if message.nil?
      message = message_or_object
    else
      object_id, object_class = extract_object_identifier(message_or_object)
      logger = logger.tagged("#{object_class}/#{object_id}")
    end
    logger = logger_with_trace_id(logger,trace_id)
    logger = logger_with_current_actor_id(logger,current_actor_id)

    logger.info(message)

    all_args = [self.class.name, method, object_id, object_class&.name, trace_id, current_actor_id, message]

    LogMethod.config.after_log_procs.each do |after_log_proc|
      arity = if after_log_proc.kind_of?(Proc)
                after_log_proc.arity
              elsif after_log_proc.respond_to?(:call)
                after_log_proc.method(:call).arity
              end
      args_for_arity = if arity <= 0
                         []
                       else
                         all_args[0..(arity-1)]
                       end
      after_log_proc.(*args_for_arity)
    end
  end

private

  def extract_object_identifier(message_or_object)
    if !logging_external_identifier_method.nil? &&
        message_or_object.respond_to?(logging_external_identifier_method)

      [message_or_object.send(logging_external_identifier_method), message_or_object.class]

    elsif message_or_object.kind_of?(ActiveRecord::Base)

      [message_or_object.id, message_or_object.class]

    else

      [message_or_object.inspect, message_or_object.class]

    end
  end

  def logger_with_trace_id(logger,trace_id)
    return logger if trace_id.nil?
    logger.tagged("trace_id:#{trace_id}")
  end

  def logger_with_current_actor_id(logger,current_actor_id)
    return logger if current_actor_id.nil?
    logger.tagged("#{LogMethod.config.current_actor_id_label}:#{current_actor_id}")
  end
end
