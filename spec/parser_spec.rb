require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Curly::Parser" do
  def parser(source)
    @parser = Curly::Parser.new(source)
  end

  def scanner
    @parser.scanner
  end

  def peek(n=1)
    scanner.peek(n)
  end

  def raise_syntax
    raise_error(Curly::Parser::SyntaxError)
  end

  context "#token" do
    def token(source)
      parser(source).token
    end
    
    it "returns symbol" do
      token("abcd_9-").should == %s"abcd_9-"
    end

    it "raises if nothing found" do
      lambda { token("!") }.should
       raise_error(Curly::Parser::SyntaxError)
    end

    it "raises on empty token name" do
      lambda { token("") }.should
       raise_error(Curly::Parser::SyntaxError)
    end

    it "leaves off unparsed source" do
      token("abc[]")
      peek(2).should == "[]"
    end

    it "builds token with heredoc" do
      token("{<'abc'>}").should == :abc
    end
  end

  context "#tag" do
    def tag(source)
      parser(source).tag
    end

    it "consumes tag closing" do
      tag("{abc nefg}abc").should ==
        [:abc, [], ["nefg"]]
      peek(3).should == "abc"
      # scanner.should be_eos
    end
    
    it "eats initial whitespace before body" do
      tag("{abc  nefg }").should ==
        [:abc, [], ["nefg "]]
    end

    it "builds tag with attributes" do
      tag("{abc [a b] [c d] \n abcd}").should ==
        [:abc, [[:a, "b"], [:c, "d"]], ["abcd"]]
    end

    it "no need to escape [] in body" do
      tag("{abc [a b] abcd[]}").should ==
        [:abc, [[:a, "b"]], ["abcd[]"]]
    end

    it "builds tag with empty body" do
      tag("{abc}").should ==
        [:abc, [], []]
    end

    it "builds tag with heredoc token" do
      tag("{{<'abc'>}}").should ==
        [:abc, [], []]
    end
  end

  context "#body" do
    def body(source)
      parser(source).body
    end

    it "leaves off unparsed close tag" do
      body("}").should be_empty
      peek(1).should == "}"
    end
    
    it "scans plain text" do
      body(" abc ").should == [" abc "]
    end

    it "scans empty body" do
      body("").should == []
    end

    it "scans tag" do
      self.body("{abc efg}").should ==
        [[:abc, [], ["efg"]]]
    end

    it "tag and text" do
      self.body("a {b c {e f g}} d").should ==
        ["a ", [:b, [], ["c ", [:e, [], ["f g"]]]], " d"]
    end

    it "text and short heredoc" do
      self.body("abcd{<'efg'>}hij").should == ["abcdefghij"]
    end

    it "text and long heredoc" do
      self.body("abcd{<here efg here>}hij").should == ["abcdefghij"]
    end

    it "text and heredoc and tag" do
      self.body("abcd{<here efg here>}hij{foo bar}klm").should ==
        ["abcdefghij", [:foo, [], ["bar"]], "klm"]
    end
  end

  context "#attributes" do
    def attributes(source)
      parser(source).attributes
    end

    it "returns empty" do
      attributes("").should be_empty
    end

    it "collets attributes" do
      attributes("[a b] [c d]").should ==
        [[:a, "b"], [:c, "d"]]
    end
  end

  context "#attribute" do
    def attribute(source)
      parser(source).attribute
    end

    it "head and attribute text" do
      attribute("[abc efg]").should == [:abc, "efg"]
    end
  end

  context "#heredoc" do
    def here(source)
      parser(source).heredoc
    end

    it "quotes with short heredoc" do
      here("{<!abcd!>}").should == "abcd"
    end

    it "quotes with long heredoc" do
      here("{<here abcd here>}").should == "abcd"
    end
    
  end

  context "#heredoc_short" do
    def here(source)
      parser(source).heredoc_short
    end

    it "uses a single char delimiter" do
      here("^ abc{}[] ^efg").should == " abc{}[] "
      peek(3).should == "efg"
    end

    it "uses matching {}" do
      here("{abc}").should == "abc"
    end

    it "uses matching []" do
      here("[abc]").should == "abc"
    end

    it "uses matching <>" do
      here("<abc>").should == "abc"
    end

    it "uses matching ()" do
      here("(abc)").should == "abc"
    end
  end

  context "#heredoc_long" do
    def here(source)
      parser(source).heredoc_long
    end

    it "raises if there's no space after heredoc opening" do
      lambda { here("here,foo here") }.should raise_syntax
    end

    it "raises if there's no closing" do
      lambda { here("here foo") }.should raise_syntax
    end
    
    it "quotes uses tag" do
      here("here heree here\n").should == "heree"
    end

    it "preserve white space" do
      here("here  foo  here\n").should == " foo "
    end
  end

  context "#space" do
    it "skips spaces" do
      parser = self.parser("  \t\nabc")
      parser.space.should == "  \t\n"
      peek(3).should == "abc"
    end
  end

  context "#parse" do
    def parse(source)
      parser(source).parse
    end

    it "parses" do
      parse("  {a b}  ").should ==
        [:a, [], ["b"]]
    end

    it "raises if has unparsed content" do
      lambda { parse("{a b}e") }.should raise_syntax
    end
  end
end
