# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/osx'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

require 'bubble-wrap/http'
require 'bubble-wrap/reactor'

Motion::Project::App.setup do |app|
  app.name = 'bitrates'
  app.info_plist['LSUIElement'] = true
  app.sdk_version = '10.8'
  app.deployment_target = '10.8'
end
