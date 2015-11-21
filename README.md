# Rails form_tag


## Rails Forms

When it comes to forms in Rails you will discover that you will have the flexibility to utilize:

* Ruby form gems

* Built in form helper methods

* Plain HTML form elements

This lesson is going to begin with integrating HTML form elements and then slowly start to refactor the form using Rails methods. It would be very easy to integrate form helpers and we could have our form working in a few minutes, however to fully understand what Rails is doing behind the scenes is more important than getting this form working, so we're going to build the system from the ground up so when we're finished you should be able to understand all of the processes that are necessary in order to process forms in an application properly and securely.


## Rendering the form view

Let's first create a Capybara spec to ensure that going to ```posts/new``` takes us to our form:

```ruby
# specs/features/post_spec.rb

scenario 'form route works with new action' do
  visit new_post_path
  expect(page.status_code).to eq(200)
end
```

As expected this results in a failure saying that we don't have a ```new_post_path``` method, so let's create that in our route file:

```ruby
resources :posts, only: [:index, :new]
```

Now it gives the failure ```The action 'new' could not be found for PostsController```, to correct this let's add a ```new``` action in the post controller:

```ruby
def new
end
```

Lastly it says we're missing a template, let's add ```app/views/posts/new.html.erb```. The tests are all passing for our routing, let's add a matcher spec to make sure the form itself is being shown on this page:

```ruby
# specs/features/post_spec.rb

scenario 'form renders with the new action' do
  visit new_post_path
  expect(page).to have_content("Post Form")
end
```

Running this spec gets a matcher error, we can get this passing by adding the HTML ```<h3>Post Form</h3>``` to the ```new.html.erb``` view template.

Adding this gets our specs passing, now let's do a minor refactor, we're going to use a Rails partial so that we can call our form from other pages, such as an edit page. We'll have a full section and lab dedicated to partials in Rails, so don't worry if your'e not familiar with the syntax, make the following refactor:

```ERB
<% # app/views/posts/new.html.erb %>

<%= render "form" %>
```

Then create the partial by running ```touch app/views/posts/_form.html.erb``` and move the ```<h3>Post Form</h3>``` HTML code into the new partial. Running the tests again and everything should still be passing, and now we have abstracted our form so it can be used for more than just the ```new``` action in the future.


## Building the form in HTML

Our first pass at the form will be in plain HTML, and in this reading we're not concerned with creating any records in the database, our focus is simply on the form process, so we'll simply be printing out the submitted form params on the show page.

Let's create a spec for this, it's going to take a while for this to pass since we're going to be spending some time on the HTML creation process, but it's a good practice to ensure all new features are tested before the implementation code is added.

```ruby
# specs/features/post_spec.rb

scenario 'new form submits content and redirects to new page and prints out params' do
  visit new_post_path

  fill_in 'post_title', with: "My post title"
  fill_in 'post_description', with: "My post description"

  click_on "Submit Post"

  expect(page).to have_content("My post title")
end
```

This is a temporary spec since we eventually will want this to form to redirect to a newly created record page, but we'll use it to ensure our form is working properly. This fails for obvious reasons, let's follow the TDD process and let the failures help build our form. The first error says that it can't find the field ```post_title```. Let's add the following HTML form items into the ```_form.html.erb``` view template:

```ERB
<h3>Post Form</h3>

<form>
  <label>Post title:</label><br>
  <input type="text" id="post_title" name="post_title"><br>

  <label>Post Description</label><br>
  <textarea id="post_description" name="post_description"></textarea><br>

  <input type="submit" value="Submit Post">
</form>
```

In looking at both of the input elements, I'm using the standard Rails convention:

* ```id``` - This will have the model name followed by an underscore and then the attribute name

* ```name``` - This is where Rails looks for the parameters and stores it in a Hash. In a traditional Rails application this will be nested inside of the model with the syntax ```model[attribute]```, however we will work through that in a later lesson.

Ok, so the spec was able to fill in the form elements and submit, but it's giving an error because this form doesn't actually redirect to any page, let's first update the form so that it has an action:

```ERB
<form action="<%= posts_path %>">
```

This will now redirect to ```/posts```, however we also need to add a method so that the application knows that we are submitting form data via the POST HTTP verb:

```ERB
<form action="<%= posts_path %>" method="post">
```

Next we need to draw a route so that the routing system knows what to do when a POST request is sent to the ```/posts``` resource:

```ruby
resources :posts, only: [:index, :new, :create]
```

If you run rake routes, you will see we now have a ```posts#create``` action:

```
Prefix    Verb    URI                   Controller#Action
posts     GET     /posts(.:format)      posts#index
          POST    /posts(.:format)      posts#create
new_post  GET     /posts/new(.:format)  posts#new
post      GET     /post/:id(.:format)   posts#show
```

Now let's add in a ```create``` action in the posts' controller and have it grab the params, store them in an instance variable and then redirect to the new page:

```ruby
def create
  session[:form_params] = params.inspect
  redirect_to new_post_path
end
```

I'm storing the values from the form in the session so when we redirect back to the form we can print these values out on the page to ensure the params are processing properly. Lastly, let's update the ```new.html.erb``` view template so it prints out the form values:

```ERB
<%= render "form" %>

<%= session[:form_params] if session[:form_params] %>
```

This is temporary code that we will use to make sure our form is working properly, I'm storing the values in the session so it's more straightforward to test and pass between the controller actions. If you run the rails server and go to the ```posts/new``` page and fill in the title and description form elements and click submit you will find a new type of error:

![InvalidAuthenticityToken](http://reif.io/lib/flatiron/InvalidAuthenticityToken.png)

Which leads us to a very important part of Rails forms: CSRF.


## What is CSRF?

First and foremost, CSRF is an acronym for: Cross-Site Request Forgery (CSRF). Instead of giving a boring explanation of what happens during a CSRF request, let's walk through a real life example of a Cross-Site Request Forgery hack:

1. You go to your bank website and login, you check your balance and then open up a new tab in the browser and go to your favorite meme site.

2. Without you knowing the meme site is actually a hacking site that has scripts running the background as soon as you land on the page.

3. One of the scripts on the site hijacks the banking session that you have open in the other browser and submits a form request to transfer money to their account.

4. The banking form can't tell that the form request wasn't made by you, so it all goes through just like you were the one who made the request.

This is a Cross-Site Request Forgery request, one site makes a request to another site via a form. Rails blocks this from happening by default by requiring that a unique authenticity token is submitted with each form. This authenticity token is stored in the session and can't be hijacked by hackers since it performs a match check when the form is submitted and will throw an error if the token isn't there or doesn't match.

To fix this ```ActionController::InvalidAuthenticityToken``` error, we can integrate the ```form_authenticity_token``` helper into the form as a hidden field:

```ERB
<h3>Post Form</h3>

<form action="<%= posts_path %>" method="post">
  <label>Post title:</label><br>
  <input type="text" id="post_title" name="post[title]"><br>

  <label>Post Description</label><br>
  <textarea id="post_description" name="post[description]"></textarea><br>

  <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
  <input type="submit" value="Submit Post">
</form>
```

If you refresh the page you will see that not only is the error fixed, but the elements are now also being printed out on the page! Running the specs you will see that our spec is now passing, so our form is working, however this might be one of the ugliest Rails forms I've ever seen, so let's do some re-factoring.


## Using form helpers

The ActionView has a number of methods we can use to streamline our form. Let's start by integrating a Rails form_tag element:

```ERB
<%= form_tag posts_path do %>
  <label>Post title:</label><br>
  <input type="text" id="post_title" name="post[title]"><br>

  <label>Post Description</label><br>
  <textarea id="post_description" name="post[description]"></textarea><br>

  <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
  <input type="submit" value="Submit Post">
<% end %>
```

Running the tests you will see that all of the tests are still passing. If you go and look at the HTML that this generates you will see the following:

```html
<form action="/posts" accept-charset="UTF-8" method="post"><input name="utf8" type="hidden" value="&#x2713;" /><input type="hidden" name="authenticity_token" value="7B5m/x8roxG6bc1vbRxRhr/z+ql6D261+j6LwHeGjeial7hxyW+5zk6CTGLpY1aKUj9hzLPdtRhWfcX5i047Iw==" />
  <label>Post title:</label><br>
  <input type="text" id="post_title" name="post[title]"><br>

  <label>Post Description</label><br>
  <textarea id="post_description" name="post[description]"></textarea><br>

  <input type="hidden" name="authenticity_token" id="authenticity_token" value="JC6cMiNK9k8nuWJdKp/3E29C/bALDkK9N6it3TeFEb1Sp0K89Q7skNNW41Cu4PAfgo5m1cLcmRCb6+Pky02ndg==" />
  <input type="submit" value="Submit Post">
</form>
```

The ```form_tag``` Rails helper is smart enough to know that we want to pass the form params using the POST method and it automatically render the HTML that we were writing by hand before.

Now let's integrate some other form helpers to let Rails generate the input elements for us, for this form we'll be using the ```text_field_tag``` and ```text_area_tag``` tag and pass them the attributes with symbols. We'll also replace the HTML tag for the submit button with the ```submit_tag```:

```ERB
<%= form_tag posts_path do %>
  <label>Post title:</label><br>
  <%= text_field_tag :title %><br>

  <label>Post Description</label><br>
  <%= text_area_tag :description %><br>

  <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
  
  <%= submit_tag "Submit Post" %>
<% end %>
```

This is all working on the page, however it broke some of our tests since it streamlined the ID attribute in the form, so let's update our spec:

```ruby
fill_in 'title', with: "My post title"
fill_in 'description', with: "My post description"
```

Running the specs again and now we're back to everything passing and you now know how to build a Rails form from scratch and refactor it using Rails form helper methods, nice work!