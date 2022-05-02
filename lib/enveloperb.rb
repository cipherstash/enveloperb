require "fiddle"

begin
  Fiddle::Function.new(Fiddle.dlopen("#{__dir__}/#{RbConfig::CONFIG["ruby_version"]}/libenveloperb.#{RbConfig::CONFIG["SOEXT"]}")["Init_libenveloperb"], [], Fiddle::TYPE_VOIDP).call
rescue Fiddle::DLError
  begin
    Fiddle::Function.new(Fiddle.dlopen("#{__dir__}/libenveloperb.#{RbConfig::CONFIG["SOEXT"]}")["Init_libenveloperb"], [], Fiddle::TYPE_VOIDP).call
  rescue Fiddle::DLError
    raise LoadError, "Failed to initialize libenveloperb.#{RbConfig::CONFIG["SOEXT"]}; either it hasn't been built, or was built incorrectly for your system"
  end
end

require_relative "./enveloperb/encrypted_record"
require_relative "./enveloperb/awskms"
require_relative "./enveloperb/simple"
