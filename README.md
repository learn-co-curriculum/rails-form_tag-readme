# Rails form_tag

## Rails Forms

Welcome to the world of Rails forms, which give users the ability to submit data
into form fields. This can be used for: creating new database records, building
a contact form, integrating a search engine field, and pretty much every other
aspect of the application that requires user input. When it comes to forms in
Rails, you will discover that you will have the flexibility to utilize:

- Built-in form helper methods

- Plain HTML form elements

This lesson is going to begin by integrating HTML form elements and then slowly
start refactoring the form using Rails methods. It would be very easy to
integrate form helpers (and we could have our form working in a few minutes).
However, fully understanding what Rails is doing behind the scenes is more
important than getting the form working right away. We're going to build the
system from the ground up. When we're finished, you should be able to understand
all of the processes that are necessary in order to process forms in an
application properly and securely.

**Note:** For the next few labs, we're not going to use mass assignment, we'll assign each
attribute individually. For example, instead of
`Student.create(params[:students]) we'll write Student.create(first_name: params[:first_name], last_name: params[:last_name])` and name our fields in the
view files without the "student" preface. We'll discuss why in the upcoming
reading on Strong Params.

## Rendering the Form View

Today we'll be giving the user the ability to create a new post in our BlogFlash
application. Let's first create a Capybara spec to ensure that going to
`posts/new` takes us to our form. If you think back to the
[Rails URL Helpers lesson][helpers], we know that we don't need to hard-code the
route into our tests any longer. Let's use the standard RESTful convention of
`new_post_path` for the route helper name:

```ruby
# spec/features/post_spec.rb

require 'rails_helper'

describe 'new post' do
  it 'ensures that the form route works with the /new action' do
    visit new_post_path
    expect(page.status_code).to eq(200)
  end
end
```

As expected, this results in a failure saying that we don't have a `new_post_path` method, so let's create that in our `routes.rb` file:

```ruby
resources :posts, only: [:index, :new]
```

Now it gives this failure: `The action 'new' could not be found for PostsController`. To correct this, let's add a `new` action in
`PostsController`:

```ruby
def new
end
```

Lastly, it says we're missing a template. Let's create
`app/views/posts/new.html.erb`. Now that our routing test is passing, let's add
a matcher spec to ensure that the template is properly displaying HTML on the
new post page:

```ruby
# spec/features/post_spec.rb

require 'rails_helper'

describe 'new post' do

  ...

  it 'renders HTML in the /new template' do
    visit new_post_path
    expect(page).to have_content('Post Form')
  end
end
```

Running this spec gets a matcher error. We can get this passing by adding
`<h3>Post Form</h3>` to the `new.html.erb` view template.

## Building the form in HTML

Our first pass at the form will be in plain HTML. In this reading, we're not
concerned with creating any records in the database. Our focus is on the form
process. We'll simply be printing out the submitted form params on the show
page.

Let's create a spec for this. It's going to take a while for this to pass since
we're going to be spending some time on the HTML creation process, but it's a
good practice to ensure all new features are tested before the implementation
code is added.

As you are updating the code, make sure to test it out in the browser – don't
just rely on the tests. It's important to see the errors in both the tests and
the browser since you'll want to become familiar with both types of failure
messages.

```ruby
# spec/features/post_spec.rb

require 'rails_helper'

describe 'new post' do

  ...

  it "displays a new post form that redirects to the index page, which then contains the submitted post's title and description" do
    visit new_post_path
    fill_in 'post_title', with: 'My post title'
    fill_in 'post_description', with: 'My post description'

    click_on 'Submit Post'

    expect(page.current_path).to eq(posts_path)
    expect(page).to have_content('My post title')
    expect(page).to have_content('My post description')
  end
end
```

This fails for obvious reasons. Let's follow the TDD process, letting the
failures help build our form. The first error says that Capybara can't find the
form field `post_title`. To fix that, let's create an HTML form in the
`new.html.erb` view template:

```erb
<form>
  <label>Post title:</label><br>
  <input type="text" id="post_title" name="post[title]"><br>

  <label>Post description:</label><br>
  <textarea id="post_description" name="post[description]"></textarea><br>

  <input type="submit" value="Submit Post">
</form>

<%= params.inspect %>
```

The `name` attributes in each `input` should look pretty familiar by now ––
they're good ole' nested hashes. Just like Sinatra, Rails takes the user input
entered into form fields and stores it in the `params` hash. The `name`
attribute for a given `input` field is used as the key within `params` at which
the entered data is stored. For instance, the input entered into the "Post
title:" field in the above form would be stored as the value of
`params[:post][:title]`. Traditionally, Rails apps use that `model[attribute]`
syntax for `name` attributes (e.g., `post[title]`). We'll talk more about that
in a later lesson.

You'll also notice that we're printing out `params` to the page. Until we set up
the form action, clicking `Submit Post` won't actually redirect to a page on
which the input values will be visible, but we'd still like to verify that the
`params` hash is being populated correctly.

If we run the tests again, we'll see that Capybara expected submitting the form
to redirect it to `/posts`, but instead it found itself back on `/posts/new`.
Capybara was able to fill in the form elements and click `Submit Post`, but we
need to update the form tag with an `action` attribute:

```erb
<form action="<%= posts_path %>">
```

Now the form redirects to `/posts`. However, we also need to add a `method`
attribute so that the application knows that we are submitting form data via the
`POST` HTTP verb:

```erb
<form action="<%= posts_path %>" method="POST">
```

If you open up the browser and submit the form, you will get the following
routing error: `No route matches [POST] "/posts"`. We need to draw a `create`
route so that the routing system knows what to do when a `POST` request is sent
to the `/posts` resource:

```ruby
# config/routes.rb

resources :posts, only: [:index, :new, :create]
```

If you run `rake routes`, you'll see we now have a `posts#create` action:

```bash
  Prefix Verb URI Pattern          Controller#Action
   posts GET  /posts(.:format)     posts#index
         POST /posts(.:format)     posts#create
new_post GET  /posts/new(.:format) posts#new
```

Running the spec tests again leads to an 'unknown action' error: `The action 'create' could not be found for PostsController`. Let's add a `create` action in
`PostsController` and have it create a new `Post` object with the values from
`params` and then redirect to the index page:

```ruby
def create
  Post.create(title: params[:post][:title], description: params[:post][:description])
  redirect_to posts_path
end
```

If you run the Rails server, navigate to the `posts/new` page, fill in the title
and description form elements, and click submit, you will find a new type of
error:

![InvalidAuthenticityToken](https://s3.amazonaws.com/flatiron-bucket/readme-lessons/InvalidAuthenticityToken.png)

Which leads us to a very important part of Rails forms: CSRF.

**Note:** If you are seeing an error along the lines of `Cannot render console from (<IP address here>)! Allowed networks: 127.0.0.1, ::1, 127.0.0.0/127.255.255.255` you'll want to add this code to `config/environments/development.rb`, and not `config/application.rb`, so it is only applied in your development environment.

```ruby
class Application < Rails::Application
  config.web_console.whitelisted_ips = '<IP address here>'
end
```

## What is CSRF?

"CSRF" stands for: Cross-Site Request Forgery. Instead of giving a boring
explanation of what happens during a CSRF request, let's walk through a
real-life example of a Cross-Site Request Forgery hack:

1.  You go to your bank website and log in. After checking your balance, you open
    up a new tab in the browser and go to your favorite meme site.

2.  Unbeknownst to you, the meme site is actually a hacking site that has scripts
    running in the background as soon as you land on their page.

3.  One of the scripts on the site hijacks the banking session that's open in the
    other browser tab and submits a form request to transfer money to their account.

4.  The banking form can't tell that the form request wasn't made by you, so it
    goes through the process as if you were the one who made the request.

One site making a request to another site via a form is the general flow of a
Cross-Site Request Forgery. Rails blocks this from happening by default by
requiring that a unique authenticity token be submitted with each form. This
authenticity token is stored in the session and can't be hijacked by hackers: it
performs a match check when the form is submitted, and it will throw an error if
the token isn't there or doesn't match.

To fix this `ActionController::InvalidAuthenticityToken` error, we can integrate
the `form_authenticity_token` helper into the form as a hidden field:

```erb
<form action="<%= posts_path %>" method="POST">
  <label>Post title:</label><br>
  <input type="text" id="post_title" name="post[title]"><br>

  <label>Post description:</label><br>
  <textarea id="post_description" name="post[description]"></textarea><br>

  <input type="hidden" name="authenticity_token" value="<%= form_authenticity_token %>">
  <input type="submit" value="Submit Post">
</form>
```

If we refresh the `posts/new` page, fill out the form, and click `Submit Post`,
the browser should load the index view with our newly-created post's title and
description in a bulleted list. All of the spec tests should now be passing, and
our form is functional. However, this is probably one of the ugliest and
least-elegant Rails forms that has ever existed, so let's do some refactoring.

## Using form helpers

`ActionView`, a sub-gem of Rails, provides a number of helper methods to assist
with streamlining view template code. Specifically, we can use `ActionView`
methods to improve our form! Let's start by integrating a Rails `form_tag`
element:

```erb
<%= form_tag posts_path do %>
  <label>Post title:</label><br>
  <input type="text" id="post_title" name="post[title]"><br>

  <label>Post description:</label><br>
  <textarea id="post_description" name="post[description]"></textarea><br>

  <input type="hidden" name="authenticity_token" value="<%= form_authenticity_token %>">
  <input type="submit" value="Submit Post">
<% end %>
```

Next, we'll replace that hidden authenticity token input field with a Rails
`hidden_field_tag`:

```erb
<%= form_tag posts_path do %>

  ...

  <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
  <input type="submit" value="Submit Post">
<% end %>
```

If we run the tests again, we'll see that they're all still passing. Let's take
a look at the HTML generated by our Rails `ActionView` methods:

```html
<form action="/posts" accept-charset="UTF-8" method="post"><input name="utf8" type="hidden" value="&#x2713;" /><input type="hidden" name="authenticity_token" value="zkOjrjTG8Lxn0CF8Lt/kFIgWdYyY3NTMbwh+Q9kPX1NrYztgq0GZNCjLFavBXka1Y5QhNjDlhX+dzQoZMzUjOA==" />
  <label>Post title:</label><br>
  <input type="text" id="post_title" name="post[title]"><br>

  <label>Post description:</label><br>
  <textarea id="post_description" name="post[description]"></textarea><br>

  <input type="hidden" name="authenticity_token" id="authenticity_token" value="7SuubeJGbqfm4rO+F5VTS6Wl1SNCTGOr/mrYZKOQLbtICzajfcEHL6n5h2n4FPHqTieBmep1MhgMr6w+SapR0A==" />
  <input type="submit" value="Submit Post">
</form>
```

The `form_tag` Rails helper is smart enough to know that we want to submit the
form via the `POST` method, and it automatically renders the HTML that we were
writing by hand before. The `form_tag` method also automatically generates the
necessary authenticity token, so we can remove the now-redundant
`hidden_field_tag`.

Next, let's integrate some other form helpers to let Rails generate the input
elements for us. For this form, we'll be using a `text_field_tag` and a
`text_area_tag` and passing each the corresponding `name` attribute as a symbol.
It's important to keep in mind that form helpers aren't magic –– they're simply
Ruby methods that accept arguments, such as the `name` attribute and any
additional parameters related to the form's elements. In addition to updating
the form fields, we'll also replace the HTML tag for the submit button with a
`submit_tag`.

```erb
<%= form_tag posts_path do %>
  <label>Post title:</label><br>
  <%= text_field_tag :'post[title]' %><br>

  <label>Post description:</label><br>
  <%= text_area_tag :'post[description]' %><br>

  <%= submit_tag "Submit Post" %>
<% end %>
```

Let's check out the raw HTML all these helper methods generate for us:

```html
<form action="/posts" accept-charset="UTF-8" method="post"><input name="utf8" type="hidden" value="&#x2713;" /><input type="hidden" name="authenticity_token" value="vq9SMVNk0CjwgZmYomFRhwbo5dfu7tI/2FiR7jOtlVgbj8r/zOO5oL+arU9N4PMm7WqxbUbXg4wqneW02ZfpMw==" />
  <label>Post title:</label><br>
  <input type="text" name="post[title]" id="post_title" /><br>

  <label>Post description:</label><br>
  <textarea name="post[description]" id="post_description">
</textarea><br>

  <input type="submit" name="commit" value="Submit Post" />
</form>
```

Run the spec tests one last time to verify that everything is still passing. You
now know how to build a Rails form from scratch and refactor it using Rails form
helper methods. Nice work!

[helpers]: https://learn.co/lessons/rails-url-helpers-readme

<p class='util--hide'>View <a href='https://learn.co/lessons/rails-form_tag-readme'>Rails form_tag</a> on Learn.co and start learning to code for free.</p>
