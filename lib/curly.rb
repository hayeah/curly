module Curly
  require 'nokogiri'
  extend self
  def parse(source)
    Parser.new(source).parse
  end

  def xml(source)
    build_xml(parse(source))
  end

  protected
  def build_xml(parse)
    head, attributes, body = parse
    Nokogiri::XML::Builder.new do |doc|
      doc.send(head,attributes.inject({}) { |h,(k,v)| h[k] = v; h}) do |tag|
        body.each { |element|
          case element
          when String
            tag.text(element)
          when Array
            tag.send(:insert,build_xml(element).root)
          end
        }
      end
    end.doc
  end
end

class Curly::Parser
  require 'strscan'
  attr_reader :source, :scanner
  def initialize(source)
    @source = source
    @scanner = StringScanner.new(@source)
  end

  def parse
    space
    result = tag
    space
    error("Expects eos") unless eos?
    result
  end

  def tag
    if @scanner.getch != "{"
      error("Expects tag opening: {")
    end
    space
    token = self.token
    space
    attributes = self.attributes
    space
    body = self.body
    if @scanner.getch != "}"
      error("Expects tag closing: }")
    end
    [token,attributes,body]
  end

  def attributes
    acc = []
    loop {
      space
      if eos? || !attribute?
        return acc
      end
      acc << attribute
    }
  end

  def attribute?
    peek == ATTRIBUTE_OPEN
  end
  
  ATTRIBUTE_OPEN  = "["
  ATTRIBUTE_CLOSE = "]"
  def attribute
    error("Expects attribute opening: [") unless
      scan(/\[/)
    token = self.token
    @scanner.scan(/\s?/)
    text = self.attribute_text
    error("Expects attribute closing: ]") unless
      scan(/\]/)
    [token,text]
  end
  
  def attribute_text
    text = ""
    loop {
      if eos? || peek(1) == ATTRIBUTE_CLOSE
        return text
      elsif heredoc?
        text << heredoc
      else
        text << @scanner.scan(/[^\[\]]*/)
      end
    }
  end

  def token
    string = if heredoc?
               heredoc
             else
               @scanner.scan(/[a-zA-Z0-9_-:]+/)
             end
    if string.nil?
      error("Expects a token")
    end
    string.to_sym
  end

  def body
    acc = []
    text = ""
    loop {
      if eos? || tag_close?
        acc << text unless text.empty?
        break
      elsif heredoc?
        text << heredoc
      elsif tag_open?
        unless text.empty?
          acc << text
          text = ""
        end
        acc << tag
      else
        text << @scanner.scan(/[^{}]*/)
      end
    }
    acc
  end

  # with this syntax we avoid another special char
  HEREDOC_OPEN = "{<"
  HEREDOC_CLOSE = ">}"
  def heredoc
    error("Expects heredoc opening: #{HEREDOC_OPEN}") unless
      scan(HEREDOC_OPEN)
    result = if heredoc_short?
               heredoc_short
             else
               heredoc_long
             end
    error("Expects heredoc closing: #{HEREDOC_CLOSE}") unless
      scan(HEREDOC_CLOSE)
    result
  end

  def heredoc_short
    # TODO fancy stuff like (), {}, <>
    delimiter = @scanner.getch
    string = scan(Regexp.new("[^#{Regexp.quote(delimiter)}]*"))
    @scanner.getch
    string
  end

  def heredoc_long
    open_delimiter = scan(/[[:alnum:]]+/)
    # eats the first space
    error("Expects a space after heredoc opening") unless scan(/\s/)
    close_delimiter = Regexp.new "\\s#{Regexp.quote(open_delimiter)}[^[:alnum:]]"
    result = scan_until_exclusive(close_delimiter) 
    error("Can't find heredoc closing: #{open_delimiter}") unless result
    # skip to end of delimiter.
    ## the + 1 is to account for the space before the closing delimiter
    @scanner.pos = @scanner.pos + 1 + open_delimiter.size
    result
  end

  def heredoc_short?
    peek =~ /[^[:alnum:]]/
  end

  def heredoc?
    peek(2) == HEREDOC_OPEN
  end
  
  TAG_OPEN = "{"
  def tag_open?
    peek == TAG_OPEN
  end

  TAG_CLOSE = "}"
  def tag_close?
    peek == TAG_CLOSE
  end

  def space
    scan(/\s*/)
  end

  def eos?
    @scanner.eos?
  end

  def peek(n=1)
    @scanner.peek(n)
  end

  def scan(pattern)
    @scanner.scan(regexp(pattern))
  end

  # ==================================================
  # Lifted from Mustache
    
  class SyntaxError < StandardError
    def initialize(message, position)
      @message = message
      @lineno, @column, @line = position
      @stripped_line = @line.strip
      @stripped_column = @column - (@line.size - @line.lstrip.size)
    end

    def to_s
      <<-EOF
#{@message}
  Line #{@lineno}
    #{@stripped_line}
    #{' ' * @stripped_column}^
EOF
    end
  end

  # Returns [lineno, column, line]
  def position
    # The rest of the current line
    rest = @scanner.check_until(/\n|\Z/).to_s.chomp

    # What we have parsed so far
    parsed = @scanner.string[0...@scanner.pos]

    lines = parsed.split("\n")

    [ lines.size,
      (lines.last && lines.last.size - 1) || 0,
      (lines.last && lines.last + rest) || rest]
  end
  
  def error(message, pos = position)
    raise SyntaxError.new(message, pos)
  end

  
  # Scans the string until the pattern is matched. Returns the substring
  # *excluding* the end of the match, advancing the scan pointer to that
  # location. If there is no match, nil is returned.
  def scan_until_exclusive(regexp)
    pos = @scanner.pos
    if @scanner.scan_until(regexp)
      @scanner.pos -= @scanner.matched.size
      @scanner.pre_match[pos..-1]
    end
  end

  # Used to quickly convert a string into a regular expression
  # usable by the string scanner.
  def regexp(pattern)
    pattern = Regexp.new(Regexp.escape(pattern)) if String === pattern
    pattern
  end
end
