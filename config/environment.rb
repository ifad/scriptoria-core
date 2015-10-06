# Load initializers in config/initializers
Dir["#{File.dirname(__FILE__)}/initializers/*.rb"].sort.each {|f| require f}
