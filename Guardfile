guard 'rspec',
      :cmd            => "cargo build --release && bundle exec rspec",
      :all_on_start   => true,
      :all_after_pass => true do
	watch(%r{^spec/.+_spec\.rb$}) { "spec" }
	watch(%r{^spec/.+_methods\.rb$}) { "spec" }
	watch(%r{^(lib|src)/}) { "spec" }
end
