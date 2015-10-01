require 'dotenv'
require 'scriptoria-core'
require 'logger'
require 'httpi'
require 'yajl/json_gem'
require 'rufus-json'
require 'ruote-kit'
require 'ruote-postgres'

# TODO we should seperate this into seperate initialiser files ala Rails

# Load environment from .env in development
Dotenv.load

# Setup logger
ENV['RACK_ENV'] ||= 'development'
ScriptoriaCore.logger = Logger.new(File.expand_path("../../log", __FILE__) + "/" + ENV['RACK_ENV'] + ".log")

# Setup HTTPI
HTTPI.log       = true
HTTPI.logger    = ScriptoriaCore.logger
HTTPI.log_level = :info

# Setup rufus
Rufus::Json.backend = :yajl

# Connect to postgres and create table if needed
$ruote_storage_connection = PG.connect(ENV["DATABASE_URL"])
Ruote::Postgres.create_table($ruote_storage_connection)

# Setup ruote
RuoteKit.engine = Ruote::Engine.new(
  Ruote::Postgres::Storage.new($ruote_storage_connection)
)

# Register participant
RuoteKit.engine.register do
  catchall ScriptoriaCore::HttpParticipant
end
