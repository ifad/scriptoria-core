require 'rubygems'
require 'bundler/setup'

$: << 'lib'
require_relative 'config/environment'
require 'scriptoria-core'

ScriptoriaCore::Ruote.start_engine!

run ScriptoriaCore::Application
