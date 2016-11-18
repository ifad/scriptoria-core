# scriptoria-core

[![Build Status](https://travis-ci.org/ifad/scriptoria-core.svg?branch=master)](https://travis-ci.org/ifad/scriptoria-core) [![Code Climate](https://codeclimate.com/github/ifad/scriptoria-core/badges/gpa.svg)](https://codeclimate.com/github/ifad/scriptoria-core) [![Test Coverage](https://codeclimate.com/github/ifad/scriptoria-core/badges/coverage.svg)](https://codeclimate.com/github/ifad/scriptoria-core/coverage) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/ifad/scriptoria-core/blob/master/LICENSE)

Scriptoria Workflow Engine, on Ruote

## Requirements

  * Ruby 2.2+
  * Postgres 9+
  
## Installation

Clone the repo then:

    bundle install
    
Then start the services:

    bundle exec unicorn -p 1234
    bundle exec ./script/worker
    
The database will be setup automatically - you don't need to run migrations.
    
## Configuration

Configuration can be provided by environmental variables or a .env file:

  * `DATABASE_URL` - Postgres URL, e.g. `postgres://scriptoria-core@localhost/scriptoria-core`
  * `BASE_URL` - The URL where Scriptoria Core is accessible, e.g. `http://scriptoria-core.mycompany.com`
    
## Documentation

[API docs](API_v1.md)

## License

[MIT license](LICENSE)
