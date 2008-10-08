# Objective

Clean, readable and easy to understand code throughout the application.  

# Standards

## General

* DRY it up
* If the code or spec is not easily understood by looking at it, comment it
* Use single quotation marks unless you need specifically need to use doubles
* If you must comment code with a note to do or fix something later, prefix with TODO: or FIXME: so that these items can be programatically foun later
* Only omit parentheses when the first parameter is a string or symbol and there’s no trailing condition, like unless

		some_method "a string"
		some_method :symbol
		some_method :symbol, :foo => 'bar'
		some_method(an_object)
		some_method("a string") || true

* Single statement blocks should be defined using braces.

		log(sql, name, @connection) { |connection| connection.query(sql) }

* Multiple statement blocks should be defined using do...end with the variable in the block defined on the same line as the do

		some_method do |i|
		   puts "a string"
		   puts "another string"
		end

* Use && and || instead of 'and' and 'or' in conditional groups
* Line up hash arrows for readability
* Put spaces around => hash arrows
* Put spaces after ',' in method params - but none between method names and '(' or ')':

		foo(7)
		foo(7, 8)

* Put spaces around hash arguments in braces:

		{ :key => 'value' }

* Break up the structure with white space to help readability when necessary
* Indent private and protected scope operators at same level of class

		class Foo

		  def public_method
		    ...
		  end

		protected

		  def protected_method
		    ...
		  end

		private

		  def private_method
		...

* In class structures, order methods by public, protected and private
* Indent rescue at same level of function

		def method
			...
		rescue
			...
		end

* For method defs, use ()s if there are arguments and none if there are none


## Indentation

* In Ruby files, use 2 spaces for indents, not tabs (soft tabs in textmate)
* In Rails views (*.html.erb) use tab indentation to indicate 
** Markup structure
** Inline functionality structure (loops, conditionals, etc)

## Views and partials

* Avoid logic in views
* Create valid view markup, do not leave invalid markup to be "fixed" later (easily checked with Firefox developer extensions or WebKit console)
* In views, for HTML tag parameters, always use double quotes
* In views, use a spaces between erb braces:

		<%= code %>
		<!-- or -->
		<% code %>
		<!-- NOT -->
		<%=code%>
