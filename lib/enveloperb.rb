module Enveloperb
end

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require_relative "./#{$1}/enveloperb"
rescue LoadError
  begin
    require_relative "./enveloperb.#{RbConfig::CONFIG["DLEXT"]}"
  rescue LoadError
    raise LoadError, "Failed to load enveloperb.#{RbConfig::CONFIG["DLEXT"]}; either it hasn't been built, or was built incorrectly for your system"
  end
end

require_relative "./enveloperb/encrypted_record"
require_relative "./enveloperb/awskms"
require_relative "./enveloperb/simple"
