require 'helper'

class FileSubstitutePathOutputTest < Test::Unit::TestCase

  TMP_DIR = File.dirname(__FILE__) + '/../tmp'

  CONFIG = %[
    path_key expath
    format hash
    buffer_path #{TMP_DIR}/test.*.buf
    path_prefix #{TMP_DIR}
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
    d1 = create_driver
    assert_equal 'expath', d1.instance.path_key

    err = assert_raise Fluent::ConfigError do
      create_driver %[
        buffer_path #{TMP_DIR}/test.*.buf
        path_prefix #{TMP_DIR}
      ]
    end
    assert_equal "'path_key' parameter is required", err.message

    err = assert_raise Fluent::ConfigError do
      create_driver %[
        buffer_path #{TMP_DIR}/test.*.buf
        path_key path
      ]
    end
    assert_equal "'path_prefix' parameter is required", err.message 
  end

  def test_format
    d = create_driver

    d.emit({'expath' => "a/b/c", 'foo' => 'bar'}, Time.now.to_i)
    d.expect_format ["a/b/c", {'foo' => 'bar'}.to_s + "\n"].to_msgpack
    d.run
  end
  
  def test_write_txt
    d = create_driver %[
      path_key expath
      format hash
      buffer_path #{TMP_DIR}/test.*.buf
      time_slice_format %Y%m%d%H%M%S
      path_prefix #{TMP_DIR}
    ]

    time = Time.parse('2016-11-12 13:14:15 UTC')
    d.emit({'expath' => "access.log", 'message' => 'Hello'}, time.to_i)
    d.emit({'expath' => "error.log", 'message' => 'Oops'}, time.to_i)
    d.expect_format ["access.log", {'message' => 'Hello'}.to_s + "\n"].to_msgpack
    d.expect_format ["error.log", {'message' => 'Oops'}.to_s + "\n"].to_msgpack
    paths = d.run
    assert_equal "#{TMP_DIR}/access.log." + time.strftime('%Y%m%d%H%M%S_0.log'), paths[0][0]
    assert_equal "#{TMP_DIR}/error.log." + time.strftime('%Y%m%d%H%M%S_0.log'), paths[0][1]
  end

  def test_write_gz
    d = create_driver %[
      path_key expath
      format hash
      buffer_path #{TMP_DIR}/test.*.buf
      time_slice_format %Y%m%d%H%M%S
      compress gzip
      path_prefix #{TMP_DIR}
    ]

    time = Time.parse('2016-11-12 13:14:15 UTC')
    d.emit({'expath' => "access.log", 'message' => 'Hello'}, time.to_i)
    d.emit({'expath' => "error.log", 'message' => 'Oops'}, time.to_i)
    d.expect_format ["access.log", {'message' => 'Hello'}.to_s + "\n"].to_msgpack
    d.expect_format ["error.log", {'message' => 'Oops'}.to_s + "\n"].to_msgpack
    paths = d.run
    assert_equal "#{TMP_DIR}/access.log." + time.strftime('%Y%m%d%H%M%S_0.log.gz'), paths[0][0]
    assert_equal "#{TMP_DIR}/error.log." + time.strftime('%Y%m%d%H%M%S_0.log.gz'), paths[0][1]
  end

  def test_write_txt_append
    conf = %[
      path_key expath
      format hash
      buffer_path #{TMP_DIR}/test.*.buf
      time_slice_format %Y%m%d
      append true
      path_prefix #{TMP_DIR}
    ]

    time = Time.parse('2016-11-12 13:14:15 UTC')
    expect_path = "#{TMP_DIR}/access.log." + time.strftime('%Y%m%d.log')

    d1 = create_driver conf
    d1.emit({'expath' => "access.log", 'message' => '1'}, time.to_i)
    paths = d1.run
    assert_equal expect_path, paths[0][0]

    d2 = create_driver conf
    time = Time.parse('2016-11-12 16:17:18 UTC')
    d2.emit({'expath' => "access.log", 'message' => '2'}, time.to_i)
    paths = d2.run
    assert_equal expect_path, paths[0][0]

    contents = File.read(expect_path)
    assert_equal "{\"message\"=>\"1\"}\n{\"message\"=>\"2\"}\n", contents
  end

  def test_write_gz_append
    conf = %[
      path_key expath
      format hash
      buffer_path #{TMP_DIR}/test.*.buf
      time_slice_format %Y%m%d
      append true
      compress gzip
      path_prefix #{TMP_DIR}
    ]

    time = Time.parse('2016-11-12 13:14:15 UTC')
    expect_path = "#{TMP_DIR}/access.log." + time.strftime('%Y%m%d.log.gz')

    d1 = create_driver conf
    d1.emit({'expath' => "access.log", 'message' => '1'}, time.to_i)
    paths = d1.run
    assert_equal expect_path, paths[0][0]

    d2 = create_driver conf
    time = Time.parse('2016-11-12 16:17:18 UTC')
    d2.emit({'expath' => "access.log", 'message' => '2'}, time.to_i)
    paths = d2.run
    assert_equal expect_path, paths[0][0]

    contents = read_gzipped_file(expect_path)
    assert_equal "{\"message\"=>\"1\"}\n{\"message\"=>\"2\"}\n", contents
  end

  def read_gzipped_file(path)
    # This is a copy from https://github.com/fluent/fluentd/blob/87015e1dbcd31b7e40d7387c5cfb3a228635df49/test/plugin/test_out_file.rb#L327-L339
    #
    # Zlib::GzipReader has a bug of concatenated file: https://bugs.ruby-lang.org/issues/9790
    # Following code from https://www.ruby-forum.com/topic/971591#979520
    result = ''
    File.open(path) { |io|
      loop do
        gzr = Zlib::GzipReader.new(io)
        result << gzr.read
        unused = gzr.unused
        gzr.finish
        break if unused.nil?
        io.pos -= unused.length
      end
    }

    result
  end
end
