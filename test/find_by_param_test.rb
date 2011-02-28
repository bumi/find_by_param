# -*- encoding : utf-8 -*-
require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper.rb'))

# TODO: make some nice mock objects!!!!!!!!!!!!!!!!!!
class Post < ActiveRecord::Base; end
class User < ActiveRecord::Base; end
class Article < ActiveRecord::Base; end
class Author < ActiveRecord::Base;
  def full_name
    [first_name, last_name].join(" ")
  end
end

# TODO DO BETTER TESTING!!!!
class FindByParamTest < Test::Unit::TestCase
  def teardown
    Post.delete_all
    User.delete_all
    Article.delete_all
    Author.delete_all
  end

  def test_default_should_return_id
    post = Post.create(:title=>"hey ho let's go!")
    assert_equal post.to_param, post.id.to_s
    assert_equal post.permalink, nil
  end

  def test_permalink_should_be_saved
    Post.class_eval "make_permalink :with => :title"
    post = Post.create(:title=>"hey ho let's go!")
    assert_equal "hey-ho-let-s-go", post.to_param
    assert_equal post.permalink, post.to_param
  end

  def test_permalink_should_be_allowed_on_virtual_attributes
    Author.class_eval "make_permalink :with => :full_name"
    author = Author.create(:first_name => "Bugs", :last_name => "Bunny")
    assert_equal "bugs-bunny", author.to_param
    assert_equal author.permalink, author.to_param
  end

  def test_permalink_should_not_create_forbidden_permalinks_given_one_string
    Author.class_eval "make_permalink :with => :first_name, :forbidden => 'me'"
    author1 = Author.create(:first_name => "me")
    author2 = Author.create(:first_name => "you")
    assert_not_equal "me",  author1.to_param
    assert_equal     "you", author2.to_param

    # This is implementation detail and should not really be tested. It's just
    # that I feel better, when it is.
    assert_equal "me-1", author1.to_param
  end

  def test_permalink_should_not_create_forbidden_permalinks_given_mulitple_strings
    Author.class_eval "make_permalink :with => :first_name, :forbidden => %w{you me}"
    author1 = Author.create(:first_name => "me")
    author2 = Author.create(:first_name => "you")

    assert_not_equal "me",  author1.to_param
    assert_not_equal "you", author2.to_param
    assert_not_equal author1.to_param, author2.to_param

    # This is implementation detail and should not really be tested. It's just
    # that I feel better, when it is.
    assert_equal "me-1",  author1.to_param
    assert_equal "you-1", author2.to_param
  end

  def test_permalink_should_not_create_forbidden_permalinks_given_a_regexp
    Author.class_eval 'make_permalink :with => :first_name, :forbidden => /\D$/'
    author1 = Author.create(:first_name => "me")
    author2 = Author.create(:first_name => "you")

    assert_not_equal "me",  author1.to_param
    assert_not_equal "you", author2.to_param
    assert_not_equal author1.to_param, author2.to_param

    # This is implementation detail and should not really be tested. It's just
    # that I feel better, when it is.
    assert_equal "me-1",  author1.to_param
    assert_equal "you-1", author2.to_param
  end

  def test_permalink_should_be_truncated
    Post.class_eval "make_permalink :with => :title"
    post = Post.create(:title=>"thisoneisaveryveryveryveryveryveryverylonglonglonglongtitlethisoneisaveryveryveryveryveryveryverylonglonglonglongtitle")
    assert_equal "thisoneisaveryveryveryveryveryveryverylonglonglong", post.to_param
    assert_equal post.to_param.size, 50
    assert_equal post.permalink, post.to_param
  end

  def test_permalink_should_be_truncated_to_custom_size
    Post.class_eval "make_permalink :with => :title, :param_size=>10"
    post = Post.create(:title=>"thisoneisaveryveryveryveryveryveryverylonglonglonglongtitlethisoneisaveryveryveryveryveryveryverylonglonglonglongtitle")
    assert_equal "thisoneisa",   post.to_param
    assert_equal post.permalink, post.to_param
  end

  def test_permalink_should_be_truncated_in_case_of_collision
    Post.class_eval "make_permalink :with => :title, :param_size => 10"
    post1 = Post.create(:title=>"thisoneisaveryveryvery")
    post2 = Post.create(:title=>"thisoneisaveryveryvery")

    assert_not_equal post1.to_param,  post2.to_param
    assert_not_equal post1.permalink, post2.permalink

    assert_equal post1.permalink, post1.to_param
    assert_equal post2.permalink, post2.to_param

    assert(10 >= post1.to_param.size, "permalink of post1 is too long")
    assert(10 >= post2.to_param.size, "permalink of post2 is too long")

    # This is implementation detail and should not really be tested. It's just
    # that I feel better, when it is.
    assert_equal "thisoneisa",   post1.permalink
    assert_equal "thisonei-1",   post2.permalink
  end

  def test_permalink_should_be_truncated_without_trailing_dash
    Post.class_eval "make_permalink :with => :title, :param_size => 9"
    post = Post.create(:title => "this one is a very long title")
    assert_equal "this-one",    post.to_param
    assert_equal post.to_param, post.permalink
  end

  def test_should_search_field_for_to_param_field
    User.class_eval "make_permalink :with => :login"
    user = User.create(:login=>"bumi")
    assert_equal user, User.find_by_param("bumi")
    assert_equal user, User.find_by_param!("bumi")
  end

  def test_should_validate_presence_of_the_field_used_to_create_the_param
    User.class_eval "make_permalink :with => :login"
    user = User.create(:login=>nil)
    assert_equal false, user.valid?
  end

  def test_to_param_should_perpend_id
    Article.class_eval "make_permalink :with => :title, :prepend_id=>true "
    article = Article.create(:title=>"hey ho let's go!")
    assert_equal article.to_param, "#{article.id}-hey-ho-let-s-go"
  end

  def test_should_increment_counter_if_not_unique
    Post.class_eval "make_permalink :with => :title"
    Post.create(:title=>"my awesome title!")

    post = Post.create(:title=>"my awesome title!")
    assert_equal "my-awesome-title-1", post.to_param
    assert_equal post.permalink, post.to_param

    post = Post.create(:title=>"my awesome title!")
    assert_equal "my-awesome-title-2", post.to_param
    assert_equal post.permalink, post.to_param
  end

  def test_should_record_not_found_error
    assert_raise(ActiveRecord::RecordNotFound) { Post.find_by_param!("isnothere") }
  end

  def test_should_return_nil_if_not_found
    assert_equal nil, Post.find_by_param("isnothere")
  end

  def test_should_strip_special_chars
    assert_equal "he-l-l-o-ni-ce-duaode", Post.new.send(:escape_permalink, "+*(he/=&l$l<o !ni^?ce-`duäöde;:@")
  end

  def test_does_not_leak_options
    Post.class_eval "make_permalink :with => :title, :forbidden => 'foo'"
    assert_equal( {:param => "permalink",
                   :param_size => 50,
                   :field => "permalink",
                   :with => :title,
                   :prepend_id => false,
                   :escape => true,
                   :validate => true,
                   :forbidden_strings => ["foo"]}, Post.permalink_options)

    User.class_eval "make_permalink :with => :login, :forbidden => %w{foo bar}"
    assert_equal( {:param => :login,
                   :param_size => 50,
                   :field => "permalink",
                   :with => :login,
                   :prepend_id => false,
                   :escape => true,
                   :validate => true,
                   :forbidden_strings => ["foo", "bar"]}, User.permalink_options)

    Article.class_eval "make_permalink :with => :title, :prepend_id => true, :forbidden => /baz$/"
    assert_equal( {:param => :title,
                   :param_size => 50,
                   :field => "permalink",
                   :with => :title,
                   :prepend_id => true,
                   :escape => true,
                   :validate => true,
                   :forbidden_match => /baz$/}, Article.permalink_options)

    Author.class_eval "make_permalink :with => :full_name, :validate => false"
    assert_equal( {:param => "permalink",
                   :param_size => 50,
                   :field => "permalink",
                   :with => :full_name,
                   :prepend_id => false,
                   :escape => true,
                   :validate => false}, Author.permalink_options)
  end
end

