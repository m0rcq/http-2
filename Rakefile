require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run all RSpec tests"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
task :test => [:spec]

require 'yard'
YARD::Rake::YardocTask.new
