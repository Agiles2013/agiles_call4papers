source 'http://rubygems.org'

gem 'rails', '=3.1.3'
gem 'jquery-rails', '=1.0.19'
gem 'haml', '=3.0.25'
gem 'will_paginate', '=3.0.2'
gem 'formtastic', '=1.2.4'
gem 'inherited_resources', '=1.2.2'
gem 'responders', '=0.6.5'
gem 'has_scope', '=0.5.1'
gem 'devise', '=1.5.3'
gem 'brhelper', '=3.0.8'
gem 'brcpfcnpj', '=3.0.8'
gem 'seed-fu', '=2.1.0'
gem 'acts-as-taggable-on', '=2.0.6'
gem 'cancan', '=1.6.7'
gem 'acts_as_commentable', '=3.0.1'
gem 'state_machine', '=1.1.1'
gem 'validates_existence', '=0.7.1'
gem 'goalie', '=0.0.4'
#gem 'jammit', '=0.6.5'
gem 'fastercsv', '=1.5.4'
gem 'hoptoad_notifier', '=2.4.11'
gem 'aws-ses', '=0.4.4', :require => 'aws/ses'

platforms :mswin, :mingw do
  gem 'RedCloth', '=4.2.9', :require => 'redcloth', :platforms => :mswin
end

platforms :ruby do
  gem 'RedCloth', '=4.2.9', :require => 'redcloth'
end

group :production do
#  gem 'mysql2', '=0.3.11'
  gem "pg"
end

group :development do
  gem 'sqlite3-ruby', '=1.3.3', :require => 'sqlite3'
  gem 'capistrano-ext', '=1.2.1'
end

group :development, :test do
  gem 'mocha', '=0.9.12'
  gem 'rspec-rails', '=2.5.0'
  gem 'remarkable_activerecord', '=4.0.0.alpha4'
  gem 'factory_girl_rails', '=1.6.0'
  gem 'metric_fu', '=2.1.1'
  gem 'hoe', '=2.8.0'
end
