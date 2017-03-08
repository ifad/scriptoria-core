source "https://rubygems.org"

# Force Github URLs to use HTTPS (which will be the default in Bundler 2) so it
# works over VPN
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'ruote',          github: 'jmettraux/ruote'
gem 'ruote-postgres', github: 'ifad/ruote-postgres'

gem 'dotenv'
gem 'yajl-ruby'
gem 'grape'
gem 'grape_logging'
gem 'httpi'

gem 'ruote-kit'

group :development do
  gem 'unicorn'
  gem 'rspec'
  gem 'rack-test'
  gem 'webmock'
  gem 'byebug'
  gem 'simplecov'
  gem 'yard'
end
