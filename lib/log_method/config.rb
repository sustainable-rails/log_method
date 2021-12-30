class LogMethod::Config
  attr_reader   :after_log_procs
  attr_accessor :current_actor_id_label,
                :current_actor_proc,
                :external_identifier_method,
                :trace_id_proc

  def initialize
    reset!
  end

  def reset!
    @after_log_procs            = []
    @current_actor_id_label     = "current_actor_id"
    @current_actor_proc         = NO_OP
    @external_identifier_method = nil
    @trace_id_proc              = NO_OP
  end

  def after_log_proc=(proc_or_array)
    @after_log_procs = Array(proc_or_array)
  end

private

  NO_OP = ->(*) {}
end
