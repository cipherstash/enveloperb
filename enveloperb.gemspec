begin
  require 'git-version-bump'
rescue LoadError
  nil
end

Gem::Specification.new do |s|
  s.name = "enveloperb"

  s.version = ENV.fetch("GVB_VERSION_OVERRIDE") { GVB.version rescue "0.0.0.1.NOGVB" }
  s.date    = GVB.date    rescue Time.now.strftime("%Y-%m-%d")

  s.platform = Gem::Platform::RUBY

  s.summary  = "Ruby bindings for the envelopers envelope encryption library"

  s.authors  = ["Matt Palmer"]
  s.email    = ["matt@cipherstash.com"]
  s.homepage = "https://cipherstash.com"

  s.files = `git ls-files -z`.split("\0").reject { |f| f =~ /^(\.|G|spec|Rakefile)/ }

  s.extensions = ["ext/enveloperb/extconf.rb"]

  s.required_ruby_version = ">= 2.7.0"

  s.metadata["homepage_uri"] = s.homepage
  s.metadata["source_code_uri"] = "https://github.com/cipherstash/enveloperb"
  s.metadata["changelog_uri"] = "https://github.com/cipherstash/enveloperb/releases"
  s.metadata["bug_tracker_uri"] = "https://github.com/cipherstash/enveloperb/issues"
  s.metadata["documentation_uri"] = "https://rubydoc.info/gems/enveloperb"
  s.metadata["mailing_list_uri"] = "https://discuss.cipherstash.com"
  s.metadata["funding_uri"] = "https://cipherstash.com/pricing"

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'github-release'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rake-compiler', '~> 1.2'
  s.add_development_dependency 'rake-compiler-dock', '~> 1.2'
  s.add_development_dependency 'rb-inotify', '~> 0.9'
  s.add_development_dependency 'rb_sys', '~> 0.1'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard'
end
