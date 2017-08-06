source 'http://rubygems.org'

gemspec

gem 'rails', '~>5.1.0'
gem 'sqlite3'
gem 'yard'
gem 'rake'

gem 'awesome_nested_set'
gem 'carrierwave'

group :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'factory_girl'
  gem 'capybara'
  gem 'capybara-selenium'
  gem 'selenium-webdriver', '~> 3.4.4'
  gem 'chromedriver-helper'
  gem 'database_cleaner'
end

group :development do
  gem 'web-console', '~> 2.0'
end

group :development, :test do
  # gem 'spring' # troubles...
  gem 'pry-rails'
  gem 'netzke-core', github: 'thepry/netzke-core', branch: 'ext-js-6-0-0'
  gem 'netzke-testing', github: 'thepry/netzke-testing', branch: 'ext-6-rails-5'
  gem 'faker'
end
