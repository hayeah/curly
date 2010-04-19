module Curly
  require 'strscan'
  require 'nokogiri'
  extend self
  def parse(source)
    Parser.new(source).parse
  end

  def xml(source)
    XML.new(source).generate
  end

  def node(source)
    xml(source).root
  end
end

require 'curly/parser'
require 'curly/xml'


