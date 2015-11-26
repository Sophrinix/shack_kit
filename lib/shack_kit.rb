require "shack_kit/version"
require "fileutils"
require "sqlite3"
require "sequel"

module ShackKit
  GEM_ROOT = File.dirname __dir__

  module Data
    DATA_DIR = ENV["HOME"] + "/.shack_kit"
    MIGRATIONS_DIR = GEM_ROOT + "/db/migrations"
    SOURCES_DIR = GEM_ROOT + "/db/sources"
    DB_FILE = DATA_DIR + "/shack_kit.db"
    DB = Sequel.sqlite(DB_FILE)
    CALLSIGN_REGEX = /\A([A-Z]{1,2}|[0-9][A-Z])([0-9])/

    class << self
      def db_setup
        FileUtils.mkpath(DATA_DIR)
        SQLite3::Database.new(DB_FILE) unless File.file?(DB_FILE)
        schema_update
      end

      def schema_update
        Sequel.extension :migration
        Sequel::Migrator.run(DB, MIGRATIONS_DIR)
      end
    end

    class SotaCalls
      def self.update(source_file=SOURCES_DIR+"/masterSOTA.scp")
        calls = DB[:sota_calls]
        calls.delete
        File.foreach(source_file) do |line|
          callsign = line.strip
          calls.insert(callsign: callsign) if callsign =~ CALLSIGN_REGEX
        end
        calls.count
      end

      def self.include?(callsign)
        DB[:sota_calls].where(callsign: callsign).count > 0
      end
    end
  end

end
