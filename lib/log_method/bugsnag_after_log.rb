class LogMethod::BugsnagAfterLog
  def self.call(class_thats_logging_name, method_name, object_id, object_class_name, trace_id, current_actor_id)
    Bugsnag.leave_breadcrumb method_name.to_s[0..29], {
      class: class_thats_logging_name,
      object_id: object_id,
      object_class: object_class_name,
      trace_id: trace_id,
      admin_user_id: current_actor_id
    }, Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
  end
end

