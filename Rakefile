exec(*(["bundle", "exec", $PROGRAM_NAME] + ARGV)) if ENV['BUNDLE_GEMFILE'].nil?

task :default => :test

begin
	Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
	$stderr.puts e.message
	$stderr.puts "Run `bundle install` to install missing gems"
	exit e.status_code
end

spec = Bundler.load_gemspec("enveloperb.gemspec")

require "rubygems/package_task"

Gem::PackageTask.new(spec) do |pkg|
end

namespace :gem do
  platform = Gem::Platform.local.tap { |p| p.version = nil }.to_s

  desc "Build a 'native' package for #{platform}, with binary blobs included"
  task :native

  really_full_name = "#{spec.full_name}-#{platform}"
  gem_file_name = "#{really_full_name}.gem"
  stage_dir = "pkg/#{really_full_name}"

  directory stage_dir

  binspec = spec.clone
  binspec.extensions = []
  binspec.files = spec.files.reject { |f| f =~ %r{^(Cargo.toml|(ext|src)/)} }
  binspec.platform = Gem::Platform.local.tap { |p| p.version = nil }.to_s
  binspec.required_ruby_version = "~> #{RbConfig::CONFIG["ruby_version"]}"

  binspec.files.each do |f|
    stage_file = "#{stage_dir}/#{f}"
    directory File.dirname(stage_file)
    file stage_file => File.dirname(stage_file) do
      cp f, stage_file
    end
    task :native => stage_file
  end

  soname = "libenveloperb.#{RbConfig::CONFIG["SOEXT"]}"
  sodir = "lib/#{RbConfig::CONFIG["ruby_version"]}"
  binspec.files << "#{sodir}/#{soname}"
  directory "#{stage_dir}/#{sodir}"

  file "#{stage_dir}/#{sodir}/#{soname}" => "#{stage_dir}/#{sodir}" do
    extra_flags = if RbConfig::CONFIG["SOEXT"] == "dylib"
                    ["--", "-C", "link-args=-install_name libenveloperb.dylib -flat_namespace -undefined suppress"]
                  else
                    []
                  end

    sh *(["cargo", "build", "--release", "--target-dir", "#{stage_dir}/target"] + extra_flags)
    mv "#{stage_dir}/target/release/#{soname}", "#{stage_dir}/#{sodir}/#{soname}"
  end
  task :native => "#{stage_dir}/#{sodir}/#{soname}"

  task :native do
    chdir stage_dir do
      when_writing("Creating #{gem_file_name}") do
        Gem::Package.build(binspec)

        verbose $trace do
          mv "#{gem_file_name}", ".."
        end
      end
    end
  end
end

task :release do
	sh "git release"
end

require 'yard'

YARD::Rake::YardocTask.new :doc do |yardoc|
	yardoc.files = %w{lib/**/*.rb - README.md}
end

desc "Run guard"
task :guard do
	sh "guard --clear"
end

namespace :rust do
  desc "Build Rust library"
  task :build do
    sh "cargo build --release"
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :test => "rust:build" do |t|
	t.pattern = "spec/**/*_spec.rb"
end
