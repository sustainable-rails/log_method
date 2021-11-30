# log\_method - a better way to log better stuff

[![<sustainable-rails>](https://circleci.com/gh/sustainable-rails/log_method.svg?style=shield)](https://app.circleci.com/pipelines/github/sustainable-rails/log_method)

Instead of `Rails.logger.info`, use `log «method_name»,«context object»,«message»`, and the following will be logged:

* Your log message
* The class where `log` was called
* The method name you pass in
* The class and id of the context object
* Any trace or request id you have configured
* Any current user id you have configured

This will result in more useful log messages that are easier to construct.

## Install

1. Add to your `Gemfile`:

   ```ruby
   # Gemfile
   gem "log_method"
   ```
2. `bundle install`
3. Optionally create a configuration in `config/initializers` (see below)

## Usage

```ruby
class SomeClass
  include LogMethod::Log

  def some_method(some_active_record)
    log :some_method, some_active_record, "Beginning the operation"
  end
end
```

Assuming you have configured trace ids and current user id (see below for how), this is what your log message will look like (assuming the id of `current_user` is 42 and that `some_active_record` is a `Widget` with id 7889):

```
[SomeClass#some_method](via LogMethod::Log) trace_id:7efa5401-08d8-44e3-b101-d5806563a3da current_user_id:42 [Widget:7889]: Beginnging the operation
```

Let's break down each part and understand why it's there, which will help you understand why you should use this gem:

* `[SomeClass#some_method]`                        -  this gives the class and method where the log statement originated. Super helpful when looking at log output and trying to find what code generated that log message.
* `(via LogMethod::Log)`                           -  This makes it clear that *this* gem produced this output. If you don't see this, it means something else is generating log output, too.  Very handy for understanding the source of your log statements.
* `trace_id:7efa5401-08d8-44e3-b101-d5806563a3da`  -  If you set a trace id at the start of a web request, or when you queue a background job, you can then trace all log statements related to that request. SUPER handy for understanding what all happened in a given request you are looking at.
* `current_user_id:42`                             -  System behavior often depends on who is logged in or who the "current actor" is. So you want this in your log.
* `[Widget:7889]:`                                 -  Code is almost always operating on some object or operating in the context of some object.  It's nice to know exactly which one.
* `Beginnging the operation`                       -  And, of course, your log message

### `log` method, explained

There are two ways to call the `log` method:

* `log :some_method, "Some string-based message"` - this is the closest to `Rails.logger.info` and will include `:some_method`, the current class, the message you passed, and, if configured, trace id and current user id.
* `log :some_method, some_object, "Some string-based message"` - In this form, `some_object` is included in the log message.  What is included
depends on what `some_object` is:
  - If you have configured an `external_id` and this object responds to it, the object's class and the value of the external id are included in the log message
  - If `some_object` is an Active Record, its class and the value of its `id` are included.
  - Otherwise, the class and the value of `inspect` are included in the log message

The second form is the one you should prefer whenever you have an Active Record in context, because that's how you can automatically get the class
and ID into the log so you know what data was being operated on.

### Cool, but I gotta put that `include` in every class?

I would recommend putting the `include` line in:

* `ApplicationController`
* `ApplicationJob`
* Whatever base class you use for your service layer (you should be using one).
* Any other "base" class for logic.

If you are putting business logic in your Active Records, you probably want to use the `include` line in `ApplicationRecord` as well. If you are
not putting business logic in Active Records, there's nothing to log, so I would not include this.

## Why can't I just `Rails.logger.info`?

Almost every operation in your Rails app is operating on some piece of data, so it's extremely useful to know what that piece of data was.  It's
also extremely useful to know where in the codebase the message originated.  Lastly, the entire point of request ids/trace ids is to put them in
log messages *and* it's nice to know who was logged in doing the operation.

And it's really hard to remember to put all this into the string when calling `Rails.logger.info`.

### But shouldn't we be using Observability or something?

Probably, but let's be real: not everyone has the time, bandwidth, money, or expertise to set up a true observability platform.  But we *do* have
the time to deal with logs, because those are pretty easy.  Why not make it easier?

## Configuration

If you want to change some of the behavior of the `log` method, create `config/initializers/log_method.rb`.  Here is an example configuration.
Following the example is an explanation of each option:

```ruby
LogMethod.config do |c|
  c.external_identifier_method = :external_id
  c.current_actor_proc = ->() { PaperTrail.request.whodunnit }
  c.current_actor_id_label = "user_id"
  c.after_log_proc = ->(class_thats_logging_name, method_name, object_id, object_class_name, trace_id, current_actor_id) {
    Bugsnag.leave_breadcrumb method_name.to_s[0..29], {
      class: class_thats_logging_name,
      object_id: object_id,
      object_class: object_class_name,
      trace_id: trace_id,
      admin_user_id: current_actor_id
    }, Bugsnag::Breadcrumbs::LOG_BREADCRUMB_TYPE
  }
  c.trace_id_proc = ->() { Thread.current.thread_variable_get("request_id") }
end
```

### Options

* `after_log_proc` This is a proc/lambda to be called after each log message has been sent to `Rails.logger.info`.  In the example above, we're using this to send a breadcrumb to Bugsnag so that if there is an error with this request, we can see what log messages were logged for that request.  It will be given these arguments:
   - `class_thats_logging_name` - The class where `log` was called
   - `method_name` - The method name passed to `log`
   - `object_id` - The id of the object passed to `log`, if it had one
   - `object_class_name` - The class name of the object passed to log, if one was passed
   - `trace_id` - The trace id returned by `trace_id_proc`, or `nil` if that isn't configured.
   - `current_actor_id` - The value returned by; `current_actor_proc`, or `nil` if that isn't configured.
* `current_actor_id_label` - If a current actor is logged, this is the label that will precede it in the logs
* `current_actor_proc` - Called to retrieve an identifier of the current actor executing the code, such as the current user.
* `external_identifier_method` - If you are using external ids on your objects, this is the name of that method. If an object is passed in that responds to this method, it will be used instead of `id` when creating the log message.
* `trace_id_proc` - returns the current request's request ID, trace ID, or cross-request ID.  This is useful to tie various log messages together that were all part of a single request.

### Helper Procs

This gem also includes some helper procs to connect `log` with some common gems and uses cases.

#### Bugsnag Breadcrumbs

In the example above, we use `after_log_proc` to send a breadcrumb to Bugsnag.  This means that if we get an error in a request, Bugsnag will show
all of our log statements as breadcrumbs, which can help understand what data and state was involved in the error.

This proc is included in this gem and you can use it like so:

```ruby
# config/initializers/log_method.rb
require "log_method/bugsnag_after_log"
LogMethod.config do |c|
  c.after_log_proc = LogMethod::BugsnagAfterLog
end
```

#### PaperTrail whodunnit

The [PaperTrail gem](https://github.com/paper-trail-gem/paper_trail) has support for storing an actor or user along with versions created on
changes to the database.  It's common to unify your current user (e.g. from Devise) to the Paper Trail "whodunnit" so that you can always call
`PaperTrail.request.whodunnit` to get the current actor or user.

To use this for logging, this gem includes `LogMethod::PaperTrailCurrentActor` that you can set up like so:

```ruby
# config/initializers/log_method.rb
require "log_method/paper_trail_current_actor"
LogMethod.config do |c|
  c.current_actor_proc = LogMethod::PaperTrailCurrentActor
end
```

### External IDs explained

A useful pattern is to have your Active Records manage a unique external ID that is not used by the database for foreign key constraints or other
lookups.  Suppose you call it `external_id`:

```
> record = SomeRecord.first
> record.id
42
> record.external_id
srec_2489089024u893huiefgjlhkdfg
```

There are many reasons to do this, but if you *do* do this, you will probably want these values in the log and not the database primary keys.

## Philosophy

I have tried to avoid excessive meta programming and stack navigation, resulting in something that is, I think, more predictable and easier to
follow.  The code for `log` is relatively straightforward and verbose.  I think that's what you want out of your logging and infrastructure code.

## Contributing

While I'm interested in fixing bugs and making this library better, I would highly encourage you to run your proposed changes in your production
environment for a while to make sure they are useful to you and don't cause other issues.

If you do that, please open a PR with clear problem statement and I'd love to check it out!

Please do not open PRs for things like coding style, because I do not want to change the coding style :)
