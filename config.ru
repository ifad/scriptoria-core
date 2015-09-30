require 'rubygems'
require 'bundler/setup'

$: << 'lib'
require_relative 'config/environment'
require 'scriptoria-core'

use RuoteKit::Application
run ScriptoriaCore::Application
