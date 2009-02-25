require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'couchrest')

def show obj
  puts obj.inspect
  puts
end

SERVER = CouchRest.new
SERVER.default_database = 'couchrest-extendeddoc-example'

class Author < CouchRest::ExtendedDocument
  use_database SERVER.default_database
  property :name
  
  def drink_scotch
    puts "... glug type glug ... I'm #{name} ... type glug glug ..."
  end
end

class Post < CouchRest::ExtendedDocument
  use_database SERVER.default_database
  
  property :title
  property :body
  property :author, :cast_as => 'Author'

  timestamps!
end

class Comment < CouchRest::ExtendedDocument
  use_database SERVER.default_database
  
  property :commenter, :cast_as => 'Author'
  timestamps!
  
  def post= post
    self["post_id"] = post.id
  end
  def post
    Post.get(self['post_id']) if self['post_id']
  end
  
end

puts "Act I: CRUD"
puts
puts "(pause for dramatic effect)"
puts
sleep 2

puts "Create an author."
quentin = Author.new("name" => "Quentin Hazel")
show quentin

puts "Create a new post."
post = Post.new(:title => "First Post", :body => "Lorem ipsum dolor sit amet, consectetur adipisicing elit...")
show post

puts "Add the author to the post."
post.author = quentin
show post

puts "Save the post."
post.save
show post

puts "Load the post."
reloaded = Post.get(post.id)
show reloaded

puts "The author of the post is an instance of Author."
reloaded.author.drink_scotch

puts "\nAdd some comments to the post."
comment_one = Comment.new :text => "Blah blah blah", :commenter => {:name => "Joe Sixpack"}
comment_two = Comment.new :text => "Yeah yeah yeah", :commenter => {:name => "Jane Doe"}
comment_three = Comment.new :text => "Whatever...", :commenter => {:name => "John Stewart"}

# TODO - maybe add some magic here?
comment_one.post = post
comment_two.post = post
comment_three.post = post
comment_one.save
comment_two.save
comment_three.save

show comment_one
show comment_two
show comment_three

puts "We can load a post through its comment (no magic here)."
show post = comment_one.post

puts "Commenters are also authors."
comment_two['commenter'].drink_scotch
comment_one['commenter'].drink_scotch
comment_three['commenter'].drink_scotch

puts "\nLet's save an author to her own document."
jane = comment_two['commenter']
jane.save
show jane

puts "Oh, that's neat! Because Ruby passes hash valuee by reference, Jane's new id has been added to the comment she left."
show comment_two

puts "Of course, we'd better remember to save it."
comment_two.save
show comment_two

puts "Oooh, denormalized... feel the burn!"
puts
puts
puts
puts "Act II: Views"
puts
puts
sleep 2

puts "Let's find all the comments that go with our post."
puts "Our post has id #{post.id}, so lets find all the comments with that post_id."
puts

class Comment
  view_by :post_id
end

comments = Comment.by_post_id :key => post.id
show comments

puts "That was too easy."
puts "We can even wrap it up in a finder on the Post class."
puts

class Post
  def comments
    Comment.by_post_id :key => id
  end
end

show post.comments
puts "Gimme 5 minutes and I'll roll this into the framework. ;)"
puts
puts "There is a lot more that can be done with views, but a lot of the interesting stuff is joins, which of course range across types. We'll pick up where we left off, next time."