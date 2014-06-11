ENV['RACK_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'minitest/autorun'
require 'active_record'

require File.expand_path '../../lib/dishwasher.rb', __FILE__