require 'rubygems'
require 'bundler/setup'

$: << 'lib'
require_relative 'config/environment'
require 'scriptoria-core'

ScriptoriaCore::Ruote.start_engine!

require 'ruote-kit'
RuoteKit.engine = ScriptoriaCore::Ruote.engine
use RuoteKit::Application

run ScriptoriaCore::Application
