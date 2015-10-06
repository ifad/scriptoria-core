require 'scriptoria-core/ruote'

ScriptoriaCore::Ruote.initialize_storage!(ENV["DATABASE_URL"])

# You need to call ::start_engine! or ::start_worker! to actually start Ruote
# later, before it can be used
