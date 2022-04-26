module ExampleMethods
  def with_env(vars)
    real_vals = {}

    vars.each do |var, val|
      real_vals[var] = ENV[var]
      if val.nil?
        ENV.delete(var)
      else
        ENV[var] = val
      end
    end

    yield if block_given?

    real_vals.each do |var, val|
      if val.nil?
        ENV.delete(var)
      else
        ENV[var] = val
      end
    end
  end
end
