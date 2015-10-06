require 'yajl/json_gem'
require 'rufus-json'

# Setup rufus (dependencie of ruote)
Rufus::Json.backend = :yajl
