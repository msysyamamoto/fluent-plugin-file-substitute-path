require 'helper'

class FileSubstitutePathOutputTest < Test::Unit::TestCase

  TMP_DIR = File.dirname(__FILE__) + '/../tmp'

  CONFIG = %[
    path_key expath
    format hash
    buffer_path #{TMP_DIR}/test.*.buf
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
    assert_equal 'expath', d.instance.path_key
  end

  def test_format
    d = create_driver

    d.emit({'expath' => "#{TMP_DIR}/a/b/c", 'foo' => 'bar'}, Time.now.to_i)
    d.expect_format ["#{TMP_DIR}/a/b/c", {'foo' => 'bar'}.to_s + "\n"].to_msgpack
    d.run
  end
  
  def test_write
    d = create_driver %[
      path_key expath
      format hash
      buffer_path #{TMP_DIR}/test.*.buf
      time_slice_format %Y%m%d%H%M%S
    ]
    time = Time.parse('2016-11-12 13:14:15 UTC')
    d.emit({'expath' => "#{TMP_DIR}/access.log", 'message' => 'Hello'}, time.to_i)
    d.emit({'expath' => "#{TMP_DIR}/error.log", 'message' => 'Oops'}, time.to_i)
    d.expect_format ["#{TMP_DIR}/access.log", {'message' => 'Hello'}.to_s + "\n"].to_msgpack
    d.expect_format ["#{TMP_DIR}/error.log", {'message' => 'Oops'}.to_s + "\n"].to_msgpack
    paths = d.run
    assert_equal "#{TMP_DIR}/access.log." + time.strftime('%Y%m%d%H%M%S_0.log'), paths[0][0]
    assert_equal "#{TMP_DIR}/error.log." + time.strftime('%Y%m%d%H%M%S_0.log'), paths[0][1]
  end
end