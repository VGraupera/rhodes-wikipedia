require 'rho'

Rho::RhoConfig::add_source("WikipediaPage", {"url"=>"http://rhosync.m.wikipedia.org:8080/apps/Wikipedia/sources/wikipedia", 
  "source_id"=>1, "type" => "ask"})
  
# Rho::RhoConfig::add_source("WikipediaPage", {"url"=>"http://rhosync.local/apps/Wikipedia/sources/Wikipedia", 
#   "source_id"=>31, "type" => "ask"})
  
# Rho::RhoConfig::add_source("WikipediaPage", {"url"=>"http://dev.rhosync.rhohub.com/apps/Wikipedia/sources/Wikipedia", 
#     "source_id"=>22, "type" => "ask"})
  
#Rho::RhoConfig::add_source("WikipediaPage", {"url"=>"http://rhosync.rhohub.com/apps/Wikipedia/sources/Wikipedia", "source_id"=>22})
