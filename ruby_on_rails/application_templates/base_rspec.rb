##
## See output at the end of this file for a list
## of everything this template includes
##

# Initial gems
gem 'haml'
gem 'compass'
gem 'sprockets'
gem 'rspec', :lib => 'false'
gem 'rspec-rails', :lib => 'spec/rails'

# Rspec generation
generate :rspec

# Cucumber generation
run "cucumber --webrat --rspec"

# Update config/environments/test.rb with rspec gem requirements
run "echo \"\n\nconfig.gem 'rspec', :lib => false unless File.directory?(File.join(Rails.root, 'vendor/plugins/rspec'))\" >> config/environments/test.rb"
run "echo \"config.gem 'rspec-rails', :lib => false unless File.directory?(File.join(Rails.root, 'vendor/plugins/rspec-rails'))\" >> config/environments/test.rb"

# Database.yml 
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
  
memory-test: &memory-test
  adapter: sqlite3
  database: ":memory:"
  schema: automigrate

test:
  <<: *memory-test
  
cucumber:
  <<: *sqlite-test
CODE
run "cp config/database.yml.sample config/database.yml"

# Enable auto migration with this initializer.
# Allows for much faster spec runs with a database in memory.
initializer 'schema_manager.rb', <<-CODE
case ActiveRecord::Base.configurations[RAILS_ENV]['schema']
when 'autoload'
  silence_stream(STDOUT) {load "\#{RAILS_ROOT}/db/schema.rb"}
when 'automigrate'
  silence_stream(STDOUT) {ActiveRecord::Migrator.up("\#{RAILS_ROOT}/db/migrate")}
end
CODE

# Initial application layout
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
    
    = sprockets_include_tag
    
    :javascript
      authenticity_token = '\#{form_authenticity_token}';
  
  %body
  
    #container
    
      #header
    
      #main
        = yield
  
      #footer
  
CODE

# Initial stylesheets and compass
run 'compass --rails -f blueprint .'
run 'touch public/stylesheets/compiled/.gitignore'

# Override strftime to accept '&m', '&I' and '&d' as format codes for
# month, hour and day without padding out to two characters.
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
file 'spec/lib/time_extension_spec.rb', <<-CODE
require File.dirname(__FILE__) + '/../spec_helper'

describe Time, 'extensions' do
  
  before :each do
    @time = Time.parse('2009-04-01 16:00:00')
  end
  
  it 'should drop the leading 0 from the date when &d instead of %d is passed into strftime' do
    @time.strftime('%b &d').should == 'Apr 1'
  end
  
  it 'should drop the leading 0 from the hour when &I instead of %I is passed into strftime' do
    @time.strftime('&I:%M %p').should == '4:00 PM'
  end
  
end
CODE

# Site controller, specs, views
file 'app/controllers/site_controller.rb', <<-CODE
class SiteController < ApplicationController
  
  def index; end
    
end
CODE
run 'mkdir -p app/views/site'
run 'touch app/views/site/index.html.haml'
run 'mkdir -p spec/controllers'
run 'mkdir -p spec/views/site'
file 'spec/controllers/site_controller_spec.rb', <<-CODE
require File.dirname(__FILE__) + '/../spec_helper'

describe SiteController do
  
  describe 'routing' do
    include ActionController::UrlWriter

    it "should route / to the index method" do
      root_path.should == '/'
      action = {:controller => 'site', :action => 'index'}
      route_for(action).should == root_path
      params_from(:get, root_path).should == action
    end

  end

  describe '#index' do
  
    it "should render the index template" do
      get(:index)
      response.should render_template('site/index')
    end
  
  end
  
end
CODE
file 'spec/views/site/index.html.haml_spec.rb', <<-CODE
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/site/index.html.haml" do
  
  before(:each) do
    render
  end

  it "should render successfully" do
    response.should be_success
  end
end
CODE

# Initial features
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

# Remove default routes and clean up the routes file
file 'config/routes.rb', <<-CODE
ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'site'
  SprocketsApplication.routes(map) 
  
end
CODE

# Add asset minification rake tasks
file 'lib/tasks/assets.rake', <<-CODE
namespace :assets do
  
  desc "Compiles and concatenates javascripts and stylesheets"
  task :compile => ['sprockets:install_script', 'sprockets:install_assets'] do
    puts "Compiled and concatenated javascripts"
    system "compass -e production --force"
    puts "Compiled and concatenated stylesheets"
  end
  
  desc "Minifies cached javascript and stylesheets"
  task :minify do
    
    require 'rubygems'
    require 'jsmin'
    require 'cssmin'
  
    Dir.glob("\#{File.dirname(__FILE__)}/../../public/stylesheets/compiled/*.css").each do |css| 
      f = ""
      File.open(css, 'r') {|file| f << CSSMin.minify(file)}
      File.open(css, 'w') {|file| file.write(f)}
      puts "Minified \#{css}"
    end
  
    Dir.glob("\#{File.dirname(__FILE__)}/../../public/sprockets.js").each do |js| 
      f = ""
      File.open(js, 'r') {|file| f << JSMin.minify(file)}
      File.open(js, 'w') {|file| file.write(f)}
      puts "Minified \#{js}"
    end
  
  end
  
  desc "Remove compiled and concatenated assets"
  task :cleanup do
    Dir.glob("\#{File.dirname(__FILE__)}/../../public/stylesheets/compiled/*.css").each do |css| 
      FileUtils.rm_rf(css)
      system "git rm \#{css}"
    end
    puts 'Removed compiled stylesheets'
    Dir.glob("\#{File.dirname(__FILE__)}/../../public/sprockets.js").each do |js|
      FileUtils.rm_rf(js)
      system "git rm \#{js}"
    end
    puts 'Removed compiled javascripts'
  end
  
end
CODE

# Add Heroku deployment rake tasks
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

# Filter password in logs
gsub_file 'app/controllers/application_controller.rb', /#\s*(filter_parameter_logging :password)/, '\1'

# Delete all unnecessary files
run "rm README"
run "rm doc/README_FOR_APP"
run "rm public/index.html"
run "rm public/images/rails.png"

# Setup README'
run 'touch doc/README.md'

# Setup javascripts  (jQuery, sprockets)
run 'script/plugin install git://github.com/sstephenson/sprockets-rails.git'
run 'rm -rf public/javascripts/*.js'
file 'config/sprockets.yml', <<-CODE
:asset_root: public
:load_path:
  - app/javascripts
  - vendor/sprockets/*/src
  - vendor/plugins/*/javascripts
:source_files:
  - app/javascripts/jquery-*.js
  - app/javascripts/jquery.*.js
  - app/javascripts/**/*.js
  - app/javascripts/application.js
CODE
jquery_file_name = 'jquery-1.3.2.min.js'
run "curl -L http://jqueryjs.googlecode.com/files/#{jquery_file_name} > app/javascripts/#{jquery_file_name}"
file 'app/javascripts/application.js', <<-CODE
$(document).ready(function() {});
CODE

# Initialize git repository
git :init

# Setup .gitignore
file ".gitignore", <<-END
.svn
.DS_Store
app/stylesheets/.sass-cache
config/database.yml
db/*.sqlite3
db/schema.rb
log/*.log
public/system
public/stylesheets/*.css
public/stylesheets/compiled/*.css
tmp/**/*
*.swp
END
run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore db/.gitignore'

# Add plugins
plugin 'rspec-on-rails-matchers', :git => 'git://github.com/joshknowles/rspec-on-rails-matchers.git'
plugin 'ya-rspec-scaffolder', :git => 'git://github.com/hpoydar/ya-rspec-scaffolder.git'

# Initial commit
git :add => ".", :commit => "-m 'initial commit'"

# Run initial specs and features
puts 'Setting up schema ...'
run 'rake db:migrate'
puts 'Running initial specs ...'
run 'rake spec'
puts 'Stepping through initial features ...'
run 'rake cucumber:all'

puts ''
puts 'Application setup with:'
puts '* git SCM'
puts '* Rspec BDD framework'
puts '* Cucumber BDD framework'
puts '* Haml/Sass formatting library'
puts '* Compass CSS framework manager with Blueprint CSS framework'
puts '* Asset minification rake tasks'
puts '* Deployment rake tasks for Heroku'
puts '* rspec-on-rails-matchers plugin'
puts '* ya-rspec-scaffolder plugin'
puts '* sprockets-rails plugin'
puts '* jQuery (in place of default prototype.js)'
puts '* sprockets.yml setup for jQuery'
puts '* DB-in-memory test environment'
puts '* README documentation converted to markdown'
puts '* A Time class extension for dropping leading zeros'
puts "* A general 'site' controller with an index action"
puts '* A single root path to the site controller'
puts '* A simple application layout in Haml'
puts '* Initial controller and view specs'
puts '* An initial Cucumber feature'
puts ''



