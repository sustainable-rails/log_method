class LogMethod::Config
  attr_accessor :after_log_proc,
                :current_actor_id_label,
                :current_actor_proc,
                :external_identifier_method,
                :trace_id_proc

  def initialize
    reset!
  end

  def reset!
    @after_log_proc             = NO_OP
    @current_actor_id_label     = "current_actor_id"
    @current_actor_proc         = NO_OP
    @external_identifier_method = nil
    @trace_id_proc              = NO_OP
  end

private

  NO_OP = ->(*) {}
end
