source 'https://rubygems.org'

group :rake do
  gem 'rake'
end

group :lint do
  gem 'foodcritic', '~> 7.1'
  gem 'cookstyle'
end

group :unit do
  gem 'berkshelf',  '~> 5.0'
  gem 'chefspec',   '~> 4.7'
  gem 'rspec-its'
end

group :kitchen_common do
  gem 'test-kitchen', '~> 1.12'
  gem 'kitchen-sync'
  gem 'kitchen-inspec'
  gem 'activesupport', '< 5.0.0'
end

group :kitchen_vagrant do
  gem 'kitchen-vagrant'
end
