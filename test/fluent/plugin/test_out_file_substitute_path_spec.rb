require 'helper'

class FileSubstitutePathOutputTest < Test::Unit::TestCase

  TMP_DIR = File.dirname(__FILE__) + "/../tmp"

  def setup
    Fluent::Test.setup
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
  end

  def test_sample
    assert_equal 1, 2
  end
end