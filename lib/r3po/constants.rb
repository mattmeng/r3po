module Repo
  VERSION = File.read( 'version' ) if File.exists?( 'version' )
end
