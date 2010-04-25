$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'curly'
require 'rspec'
require 'rspec/autorun'
require 'pp'

Rspec.configure do |config|
  
end
