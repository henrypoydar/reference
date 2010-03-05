##
## Rails 2-3-stable Application Template
## Shoulda, Cucumber, jQuery, Heroku
##
## See output at the end of this file for a full list
## of everything this template includes
##

# -- Bundler and gems

file 'Gemfile', <<-CODE
source :rubygems

gem 'rails', '2.3.5', :require => nil
gem 'compass'
gem 'haml'
gem 'jammit'
gem 'sqlite3-ruby', :require => 'sqlite3'

group :cucumber do
  gem 'cucumber'
  gem 'cucumber-rails'
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'faker'
  gem 'redgreen'
  gem 'rspec', :require => 'spec'
  gem 'rspec-rails'  
  gem 'webrat'
end

group :test do
  gem 'factory_girl'
  gem 'faker'
  gem 'mocha'
  gem 'redgreen'
  gem 'shoulda'
end
CODE

append_file '/config/preinitializer.rb', %{
begin
  # Require the preresolved locked set of gems.
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  require "rubygems"
  require "bundler"
  if Bundler::VERSION <= "0.9.5"
    raise RuntimeError, "Bundler incompatible.\n" +
      "Your bundler version is incompatible with Rails 2.3 and an unlocked bundle.\n" +
      "Run `gem install bundler` to upgrade or `bundle lock` to lock."
  else
    Bundler.setup
  end
end
}.strip

gsub_file 'config/boot.rb', "Rails.boot!", %{

class Rails::Boot
 def run
   load_initializer
   extend_environment
   Rails::Initializer.run(:set_load_path)
 end

 def extend_environment
   Rails::Initializer.class_eval do
     old_load = instance_method(:load_environment)
     define_method(:load_environment) do
       Bundler.require :default, Rails.env
       old_load.bind(self).call
     end
   end
 end
end

Rails.boot!
}

run 'bundle install'

# -- Cucumber setup

run "ruby script/generate cucumber --testunit --webrat"

# -- Database configuration

run "rm -rf config/database.yml"
file 'config/database.yml.sample', <<-CODE
development:
  adapter: sqlite3
  database: db/development.sqlite3
  timeout: 5000

sqlite-test: &sqlite-test
  adapter: sqlite3
  database: db/test.sqlite3
  timeout: 5000
  
test:
  <<: *sqlite-test
  
cucumber:
  <<: *sqlite-test
  database: db/cucumber.sqlite3
CODE
run "cp config/database.yml.sample config/database.yml"

# -- Javascripts (jQuery, Jammit)

jquery_file_name = 'jquery-1.4.2.js'
run 'rm -rf public/javascripts/*.js'
run 'mkdir -p app/javascripts/vendor'
file 'config/assets.yml', <<-CODE
javascripts:
  common:
    - app/javascripts/vendor/#{jquery_file_name}
    - app/javascripts/vendor/*.js
    - app/javascripts/custom/*.js
    - app/javascripts/application.js
CODE
run "curl -L http://jqueryjs.googlecode.com/files/#{jquery_file_name} > app/javascripts/vendor/#{jquery_file_name}"
file 'app/javascripts/application.js', <<-CODE
$(document).ready(function() {});
CODE

file 'lib/javascripts_host.rb', <<-CODE
# Rack middleware for serving individual javascript files
# from non-public directories to the Jammit asset packager
# when in test or development modes
#
# To use, add this line to the relevant (development)
# environment file:
#
#     config.middleware.use 'JavascriptsHost'  
#

class JavascriptsHost

  def initialize(app, opts={})
    @app = app
    @location = opts[:location] || '/app/javascripts'
    root = opts[:root] || Dir.pwd
    @file_server = Rack::File.new(root)
  end

  def call(env)
    path = env["PATH_INFO"]
    if path.index(@location) == 0
      resp = @file_server.call(env)
      return resp unless resp[0] == 404
    end
    @app.call(env)
  end
end
CODE

%w{development, test, cucumber}.each do |env|
  append_file "/config/#{env}.rb", %{
config.middleware.use 'JavascriptsHost'
}
end

# -- Stylesheets and compass

run 'compass --rails -f blueprint .'

# -- Initial application layout

file 'app/views/layouts/application.html.haml', <<-CODE
!!! XML
!!!
%html
  %head
    
    %title 
      TODO: Application title
    
    = stylesheet_link_tag 'compiled/screen.css', :media => 'screen, projection'
    = stylesheet_link_tag 'compiled/print.css', :media => 'print'
    /[if IE]
      = stylesheet_link_tag 'compiled/ie.css', :media => 'screen, projection'
    
    = include_javascripts :common
    
    :javascript
      authenticity_token = '\#{form_authenticity_token}';
  
  %body
  
    #container
    
      #header
    
      #main
        = yield
  
      #footer
  
CODE

# -- Extensions

file 'lib/time_extension.rb', <<-CODE
# Override strftime to accept '&m', '&I' and '&d' as format codes for
# month, hour and day without padding out to two characters.
class Time
  alias_method :orig_strftime, :strftime
  def strftime(x)
    result = orig_strftime(x)
    result.gsub!(/&m/) {"%d" % self.month}
    result.gsub!(/&d/) {"%d" % self.day}
    if self.hour > 12 then use_i_hour = self.hour - 12 else use_i_hour = self.hour end
    if use_i_hour == 0 then use_i_hour = 12 end
    result.gsub!(/&I/) {"%d" % use_i_hour}
    result
  end
end
CODE

initializer 'extensions.rb', <<-CODE
require 'time_extension'
CODE

file 'test/lib/time_extension_test.rb', <<-CODE
require 'test_helper'

class TimeExtensionTest < Test::Unit::TestCase
  
  context 'formatting' do
  
    setup do
      @time = Time.parse('2009-04-01 16:00:00')
    end
  
    should 'drop the leading 0 from the date when &d instead of %d is passed into strftime' do
      assert_equal 'Apr 1', @time.strftime('%b &d')
    end
  
    should 'drop the leading 0 from the hour when &I instead of %I is passed into strftime' do
      assert_equal '4:00 PM', @time.strftime('&I:%M %p')
    end
  
  end
    
end
CODE

# -- Site controller with tests and views

file 'app/controllers/site_controller.rb', <<-CODE
class SiteController < ApplicationController
  
  def index; end
    
end
CODE

run 'mkdir -p app/views/site'
run 'touch app/views/site/index.html.haml'
run 'mkdir -p test/functional'

file 'test/functional/site_controller_test.rb', <<-CODE
require 'test_helper'

class SiteControllerTest < ActionController::TestCase

  context "routing" do
    should_route :get, "/", :controller => :site, :action => :index
  end
  
  context "on GET to :index" do
    setup do
      get :index
    end
    should_respond_with :success
    should_render_template :index
  end

end
CODE

# -- Initial features

file 'features/home_page.feature', <<-CODE
Feature: Home Page
  As a web user
  In order to use this site
  I want to visit the homepage
  Scenario: view homepage
    Given I am an outside user
    When I go to the homepage
    Then I should see the homepage
CODE

file 'features/step_definitions/home_page_steps.rb', <<-CODE
Given /^I am an outside user$/ do; end

When /^When I go to the homepage$/ do 
  visit '/'
end

Then /^I should see the homepage$/ do
  response.should be_success
end
CODE

# -- Setup routes

file 'config/routes.rb', <<-CODE
ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'site'
  Jammit::Routes.draw(map)
  
end
CODE

# -- Asset minification rake tasks

run 'mkdir -p public/assets'

file 'lib/tasks/assets.rake', <<-CODE
namespace :assets do
  
  desc "Compiles and concatenates javascripts and stylesheets"
  task :compile do
    system 'jammit'
    puts "Compiled and concatenated javascripts"
    system "compass -e production --force"
    puts "Compiled and concatenated stylesheets"
  end
  
  desc "Minifies cached stylesheets"
  task :minify do
    
    require 'rubygems'
    require 'cssmin'
  
    Dir.glob("\#{File.dirname(__FILE__)}/../../public/stylesheets/compiled/*.css").each do |css| 
      f = ""
      File.open(css, 'r') {|file| f << CSSMin.minify(file)}
      File.open(css, 'w') {|file| file.write(f)}
      puts "Minified \#{css}"
    end
  
  end
  
  desc "Remove compiled and concatenated assets"
  task :cleanup do
    Dir.glob("\#{File.dirname(__FILE__)}/../../public/stylesheets/compiled/*.css").each do |css| 
      FileUtils.rm_rf(css)
      system "git rm \#{css}"
    end
    puts 'Removed compiled stylesheets'
    Dir.glob("\#{File.dirname(__FILE__)}/../../public/assets/**/*.js").each do |js|
      FileUtils.rm_rf(js)
      system "git rm \#{js}"
    end
    puts 'Removed compiled javascripts'
  end
  
end
CODE

# -- Heroku deployment rake tasks

file 'lib/tasks/heroku.rake', <<-CODE
namespace :heroku do
  
  desc "Prepare and deploy the application to heroku"
  task :deploy => ['heroku:deploy:default']
  
  namespace :deploy do

    task :default => ['assets:compile', 'assets:minify', :commit, :push, 'assets:cleanup']
    
    desc "Commit pre-deployment changes"
    task :commit do
      puts 'Committing deployment changes'
      system "git add public/stylesheets/compiled public/sprockets.js && git commit -m 'Prepared for heroku deployment'"
    end
    
    desc "Push application to heroku" 
    task :push do
      puts 'Pushing application to heroku'
      system "git push heroku master"
    end
    
    desc "Prepare and deploy the application to heroku and run pending migrations" 
    task :migrations => :default do
      puts 'Running pending migrations'
      system "heroku rake db:migrate"
    end

  end
  
end
CODE

# -- Filter password in logs                                                                           

gsub_file 'app/controllers/application_controller.rb', /#\s*(filter_parameter_logging :password)/, '\1'

# -- Delete all unnecessary files

run "rm README"
run "rm doc/README_FOR_APP"
run "rm public/index.html"
run "rm public/images/rails.png"

# -- Setup docs

run 'touch doc/README.md'

# -- Git

git :init

file ".gitignore", <<-END
.bundle
.DS_Store
.svn
*.swp
app/stylesheets/.sass-cache
config/database.yml
db/*.sqlite3
db/schema.rb
log/*.log
public/system
public/stylesheets/*.css
public/stylesheets/compiled/*.css
tmp/**/*
END

run 'touch db/.gitignore log/.gitignore tmp/.gitignore vendor/.gitignore public/assets/.gitignore public/stylesheets/compiled/.gitignore'

git :add => ".", :commit => "-m 'initial commit'"

# -- Initial tests and features

puts 'Setting up schema ...'
run 'rake db:migrate'
puts 'Running initial tests ...'
run 'rake test'
puts 'Stepping through initial features ...'
run 'cucumber'

# -- Finished!

puts ''
puts 'Application setup with:'
puts '* git SCM'
puts '* Shoulda TDD framework'
puts '* Factory Girl fixtures framework'
puts '* Mocha mocking framework'
puts '* Cucumber BDD framework'
puts '* jQuery javascript framework'
puts '* Haml/Sass formatting library'
puts '* Compass CSS framework manager with Blueprint CSS framework'
puts '* Jammit asset management for javascripts'
puts '* Asset minification rake tasks'
puts '* Deployment rake tasks for Heroku'
puts '* README documentation converted to markdown'
puts '* A Time class extension for dropping leading zeros'
puts "* A general 'site' controller with an index action"
puts '* A single root path to the site controller'
puts '* A simple application layout in Haml'
puts '* Initial controller and view tests'
puts '* An initial Cucumber feature'
puts ''


