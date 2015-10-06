require 'dotenv'

# Load environment from .env in development
Dotenv.load

ENV['RACK_ENV'] ||= 'development'
