require 'helper'

class FileSubstitutePathOutputTest < Test::Unit::TestCase

  TMP_DIR = File.dirname(__FILE__) + "/../tmp"

  CONFIG = %[
    extend_path_key expath
    path /tmp/
    format hash
  ]

  def setup
    Fluent::Test.setup
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
  end

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::TimeSlicedOutputTestDriver.new(Fluent::FileSubstitutePathOutput, tag).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'expath', d.instance.extend_path_key
    assert_equal '/tmp/', d.instance.path
  end

  def test_format
    d = create_driver

    d.emit({'expath' => '/a/b/c', 'foo' => 'bar'}, Time.now.to_i)
    d.expect_format ['/a/b/c', {'foo' => 'bar'}.to_s + "\n"].to_msgpack
    d.run
  end
end