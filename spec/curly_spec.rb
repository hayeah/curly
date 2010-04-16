require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Curly" do
  it "transform to dom" do
    d = Curly.xml("{a[width 10] bcd<> {c {f g}}}")
    (d / "c").after("<abc>")
    (d / "f").before("foobar")
    puts d.to_xml
    # puts Curly.xml("{a[width 10] bcd<> {c {f g}}}").to_xml
  end
end







