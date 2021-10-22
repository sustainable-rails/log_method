require_relative "lib/log_method/version"

Gem::Specification.new do |spec|
  spec.name     = "log_method"
  spec.version  = LogMethod::VERSION
  spec.authors  = ["Dave Copeland"]
  spec.email    = ["davec@naildrivin5.com"]
  spec.summary  = %q{A nice log method for your Rails app that provides a ton of useful context in each message!}
  spec.homepage = "https://github.com/sustainable-rails/log_method"
  spec.license  = "Hippocratic"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sustainable-rails/log_method"
  spec.metadata["changelog_uri"] = "https://github.com/sustainable-rails/log_method/releases"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency("rspec")
  spec.add_development_dependency("rspec_junit_formatter")
end
