require 'scriptoria-core'
require 'logger'

ScriptoriaCore.logger = Logger.new(File.expand_path("../../../log", __FILE__) + "/" + ENV['RACK_ENV'] + ".log")
