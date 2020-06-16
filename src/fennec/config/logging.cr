Log.setup do |c|
  backend = Log::IOBackend.new

  c.bind "proton.*", :info, backend
end

# Crecto::DbLogger.set_handler(STDOUT)
