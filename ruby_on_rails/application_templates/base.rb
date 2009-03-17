# Rspec generation
generate :rspec

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

# Gems
gem 'haml'
gem 'rspec'
gem 'rspec-rails'

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
file 'lib/extensions.rb', <<-CODE
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

# Remove :controller :action route
gsub_file 'config/routes.rb', /\s*(map\.connect ':controller\/:action\/:id')/, '\n#\1'
gsub_file 'config/routes.rb', /\s*(map\.connect ':controller\/:action\/:id\.:format')/, '\n#\1'

# Filter password in logs
gsub_file 'app/controllers/application_controller.rb', /#\s*(filter_parameter_logging :password)/, '\1'

# Delete all unnecessary files
run "rm README"
run "rm doc/README_FOR_APP"
run "rm public/index.html"
run "rm public/images/rails.png"

# Setup README'
run 'touch doc/README.mdown'

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
