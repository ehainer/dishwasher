#!/usr/bin/env rake
require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('dishwasher', '0.1.0') do |p|
	p.description = "Periodically check links in database fields for connection errors."
	p.url = "http://www.commercekitchen.com"
	p.author = "Commerce Kitchen"
	p.email = "eric@commercekitchen.com"
	p.ignore_pattern = ["tmp/*", "script/*"]
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each{ |ext| load ext }
