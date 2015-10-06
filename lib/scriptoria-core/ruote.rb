require 'ruote'
require 'ruote-postgres'

module ScriptoriaCore
  module Ruote
    class << self
      def storage
        @storage || raise("No storage configured - call ::initialize_storage! first")
      end

      def engine
        @engine || raise("No engine configured - call ::start_engine! or ::start_worker! first")
      end

      def initialize_storage!(database_url)
        # Connect to PostgreSQL and create the table if needed
        connection = PG.connect(database_url)
        ::Ruote::Postgres.create_table(connection)

        @storage = ::Ruote::Postgres::Storage.new(connection)
      end

      # Starts an instance of the Ruote engine that can manage processes.
      #
      # This engine will be able to manage processes (i.e. launch and cancel
      # workflows), but workflows won't actually be run by this engine (call
      # {::start_worker!} for that).
      def start_engine!
        @engine = ::Ruote::Dashboard.new(storage)

        @engine.register do
          catchall ScriptoriaCore::HttpParticipant
        end
      end

      # Starts an instance of the Ruote engine that will run workflows.
      #
      # This method will launch a Ruote worker and join it's thread - it won't
      # return.
      def start_worker!
        @engine = ::Ruote::Dashboard.new(
          ::Ruote::Worker.new(
            storage
          )
        )
        @engine.join
      end
    end
  end
end
