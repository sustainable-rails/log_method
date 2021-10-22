class LogMethod::Config
  attr_accessor :after_log_proc,
    :current_actor_id_label,
    :current_actor_proc,
    :external_identifier_method,
    :trace_id_proc

  def initialize
    @current_actor_proc     = ->() {}
    @current_actor_id_label = "current_actor_id"
    @after_log_proc         = ->(*) {}
    @trace_id_proc          = ->() {}
  end
end
