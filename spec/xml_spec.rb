require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Curly.xml" do
  def xml(source)
    Curly.xml(source)
  end

  def node(source)
    Curl.node(source)
  end

  describe "xml" do
    let(:doc) do
      xml("{foo[a 1][b 2] {cdata lalala} bar{! {qux}} bar{baz {foo[a 3] foo}}}")
    end
    subject { doc }
    its(:inner_text) {
      should == "lalala bar barfoo"
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
    
  end
end
