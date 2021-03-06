require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Curly::XML" do
  def xml(source)
    Curly.xml(source)
  end

  def node(source)
    Curl.node(source)
  end

  describe "Curly::XML::Builder" do
    context "#parse_tag_name" do
      def parse(head)
        Curly::XML::Builder.new(Curly.parse("{p}")).send(:parse_tag_name,head)
      end
      
      it "parses out head" do
        head, _, _ = parse("head")
        head.should == "head"
      end

      it "has no modifiers" do
        _, id, classes = parse("head")
        id.should be_nil
        classes.should be_empty
      end

      it "has id" do
        _, id, classes = parse("head#id")
        id.should == "id"
        classes.should be_empty
      end

      it "has classes" do
        _, id, classes = parse("head.c1.c2")
        id.should == nil
        classes.should == ["c1","c2"]
      end

      it "has id and classes" do
        _, id, classes = parse("head#id.c1.c2")
        id.should == "id"
        classes.should == ["c1","c2"]
      end

      it "has id can be in any position" do
        _, id, classes = parse("head.c1#id.c2")
        id.should == "id"
        classes.should == ["c1","c2"]
        _, id, classes = parse("head.c1.c2#id")
        id.should == "id"
        classes.should == ["c1","c2"]
      end
      
      it "raises if id is empty" do 
        lambda { parse("head#") }.should raise_error
      end

      it "raises if head is empty" do
        lambda { parse(".c.d") }.should raise_error
      end
    end

    context ".xml" do
      def build(tag)
        Curly::XML::Builder.node(tag)
      end

      it "builds empty tag" do
        node = build([:foo])
        node.children.should be_empty
        node.attributes.should be_empty
      end

      it "raises if tag name is empty" do
        lambda { build([]) }.should raise_error(Curly::XML::Builder::EmptyTagName)
      end

      it "builds tag with no attributes" do
        build([:foo,nil]).attributes.should be_empty
      end

      it "builds tag with attributes" do
        build([:foo,{:a => "1"}])[:a].should == "1"
      end

      it "builds tag with children" do
        node = build([:foo,nil,["a","b",[:bar,nil,"c"]]])
        node.inner_text.should == "abc"
        (node / "bar").should_not be_empty
      end
      
    end
  end
  
  describe "xml" do
    let(:doc) do
      xml("{foo[a 1][b 2] {cdata lalala} bar{! {qux}} bar{baz {foo[a 3] foo}}}")
    end
    subject { doc }

    specify("inner_text") {
      doc.inner_text.should == "lalala bar barfoo"
    }
    
    def search(selector,n=1)
      (doc / selector).should have(n).nodes
    end

    it "has no qux" do
      search("qux",0)
    end

    it "has baz" do
      search("baz")
    end

    it "has two foo" do
      search("foo",2)
    end

    it "has one foo foo" do
      search("foo foo")
    end

    it "has one baz foo" do
      search("baz foo")
    end

    context "attributes" do
      let(:foo) {doc.at "foo"}
      let(:foofoo) {doc.at "foo foo"}
      specify "foo's attributes" do
        foo["a"].should == "1"
        foo["b"].should == "2"
      end

      specify "foofoo's attributes" do
        foofoo["a"].should == "3"
        foofoo["b"].should be_nil
      end
    end

    context "#id and .class" do
      it "has id and classes" do
        node = xml("{a#id.c1.c2}").root
        node["id"].should == "id"
        node["class"].should == "c1 c2"
      end
    end
    
  end
end
