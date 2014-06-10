ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'active_record'

require File.expand_path '../../lib/dishwasher.rb', __FILE__