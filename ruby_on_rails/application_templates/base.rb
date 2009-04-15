# Gems
gem 'haml'
gem 'cucumber'
gem 'rspec', :lib => false 
gem 'rspec-rails', :lib => false 
gem 'webrat' 

# Rspec generation
generate :rspec

# Cucumber generation
generate :cucumber

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
    
    = stylesheet_link_tag 'screen', :media => 'screen'
    = stylesheet_link_tag 'print', :media => 'print'
    
    :javascript
      authenticity_token = '\#{form_authenticity_token}';
  
  %body
  
CODE

# Initial stylesheets
run 'mkdir public/stylesheets/sass'
file 'public/stylesheets/sass/screen.sass', <<-CODE
*
  :margin 0
  :padding 0
CODE
run 'touch public/stylesheets/sass/print.sass'

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

# Site controller, specs, views
file 'config/initializers/extensions.rb', <<-CODE
require 'time_extension'
CODE

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

file 'spec/views/site/index.html.haml_spec', <<-CODE
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

# Remove default routes and clean up the routes file
file 'config/routes.rb', <<-CODE
ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'site'
  
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

# Initialize git repository
git :init

# Setup .gitignore
file ".gitignore", <<-END
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
db/schema.rb
public/stylesheets/*.css
END
run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore db/.gitignore'

# Add plugins as submodules
plugin 'rspec-on-rails-matchers', :git => 'git://github.com/joshknowles/rspec-on-rails-matchers.git', :submodule => true
plugin 'ya-rspec-scaffolder', :git => 'git://github.com/hpoydar/ya-rspec-scaffolder.git', :submodule => true

# Commit
git :add => ".", :commit => "-m 'initial commit'"
