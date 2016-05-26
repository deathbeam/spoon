$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'coveralls'
Coveralls.wear!

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'parslet/rig/rspec'
require 'spoon'
