# -*- encoding: utf-8 -*-
# stub: dishwasher 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dishwasher"
  s.version = "0.2.0"
  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Commerce Kitchen"]
  s.date = "2014-06-02"
  s.description = "Periodically check links in database fields for connection errors."
  s.email = "eric@commercekitchen.com"
  s.extra_rdoc_files = ["README.rdoc", "lib/dishwasher.rb"]
  s.files = ["README.rdoc", "Rakefile", "lib/dishwasher.rb", "Manifest", "dishwasher.gemspec"]
  s.homepage = "http://www.commercekitchen.com"
  s.rdoc_options = ["--line-numbers", "--title", "Dishwasher", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "dishwasher"
  s.rubygems_version = "2.1.11"
  s.summary = "Periodically check links in database fields for connection errors."
  s.add_runtime_dependency "echoe"
  s.add_runtime_dependency "whenever"
  s.add_runtime_dependency "rest-client"
end