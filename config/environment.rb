require 'dotenv'
require 'yajl/json_gem'
require 'rufus-json'
require 'ruote-kit'
require 'ruote-postgres'

# Load environment from .env in development
Dotenv.load

# Setup rufus
Rufus::Json.backend = :yajl

# Connect to postgres and create table if needed
ruote_storage_connection = PG.connect(ENV["DATABASE_URL"])
Ruote::Postgres.create_table(ruote_storage_connection)

# Setup ruote
RuoteKit.engine = Ruote::Engine.new(
    Ruote::Worker.new(
          Ruote::Postgres::Storage.new(ruote_storage_connection)))
