require File.expand_path('../helper', __FILE__)
require 'forwardable'

class FlatParamsTest < Faraday::TestCase
  def encoder
    Faraday::FlatParamsEncoder.new(Faraday::Utils)
  end

  extend Forwardable
  def_delegators :encoder, :encode, :decode

  def test_decodes_plus_as_space
    assert_equal({'a' => 'b c d'}, decode('a=b+c+d'))
  end

  def test_decodes_flat
    assert_equal({'a[b][c]'=>'d', 'a[b][e]'=>'f'}, decode('a[b][c]=d&a[b][e]=f'))
  end

  def test_decodes_empty_params
    assert_equal({'a'=>'b', 'empty'=>'', 'blank'=>nil}, decode('a=b&empty=&blank'))
  end
end

class NestedParamsTest < Faraday::TestCase
  def encoder
    Faraday::NestedParamsEncoder.new(Faraday::Utils)
  end

  extend Forwardable
  def_delegators :encoder, :encode, :decode

  def test_decodes_plus_as_space
    assert_equal({'a' => 'b c d'}, decode('a=b+c+d'))
  end

  def test_decodes_nested
    assert_equal({'a' => {'b'=>{'c'=>'d', 'e'=>'f'}} }, decode('a[b][c]=d&a[b][e]=f'))
  end

  def test_empty_brackets_imply_array
    assert_equal({'a' => ['b', 'c']}, decode('a[]=b&a[]=c'))
  end

  def test_numeric_keys_imply_array
    assert_equal({'a' => ['b', 'c']}, decode('a[1]=b&a[2]=c'))
  end

  def test_numeric_keys_get_sorted
    assert_equal({'a' => ['b', 'c']}, decode('a[2]=c&a[1]=b'))
  end

  def test_nested_numeric_keys
    assert_equal({'a' => [['b', 'c'], ['d']]}, decode('a[1][1]=b&a[2][1]=d&a[1][2]=c'))
  end

  def test_mixed_keys_dont_imply_array
    assert_equal({'a' => {'1'=>'b', '2'=>'c', 'd'=>'e'}}, decode('a[1]=b&a[2]=c&a[d]=e'))
  end

  def test_keys_after_empty_brackets
    assert_equal({'a' => {'b'=>'d'}}, decode('a[][b]=c&a[][b]=d'))
  end

  def test_decodes_empty_params
    assert_equal({'a'=>'b', 'empty'=>'', 'blank'=>nil}, decode('a=b&empty=&blank'))
  end
end
