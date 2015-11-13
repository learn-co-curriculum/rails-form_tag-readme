# Rails form_tag

## Objectives

1. Build a functional Rails form using just HTML
2. Describe the purpose of the CSRF and how to embed it manually
3. Correctly assign a form action and form method.
4. Use a route helper as the value of a form tag's action
5. Map a form submission to a POST request to a controller/action
6. Use HTML <input> in a form
7. Explain how the input's name attribute corresponds to params
8. Raise params.inspect to test a form submission
9. Build a functional Rails form using form_tag
10. Pass a route helper as the argument to form_tag
11. Pass an options hash with method to form_tag
12. Use text_field_tag and other form controls to create inputs


## Notes

building forms in rails, first lets get the posts#new action setup

new will render form.html.erb

lets build the form with vanilla html

most important part of a form is the action, where does this form submit to?

we want the form to submit to POST /posts, let's draw that route, it's going to map to posts#create

lets use the posts_path helper to population the form tag action.

let's put a raise params.inspect in posts#create so that the game of catch is established - the new form will pass the data to create via params and we're setup to see if that works correctly.

its' going to break first because of CSRF so lets explain that and put the token in the form using the CSRF helper.

now it's going to break because of method, so let's make the forms method POST with the method= attribute

now we can build the form

how do form inputs map to params? via their name attribute

lets build a form input for a posts title and posts content (textarea)

introspect on params, it's all working.

lots of html, lots of interpolation, let's see what actionview can provide in terms of abstraction

form_tag form_tag accepts a string for action so we can pass it posts_path. it will default to POST and not require a method explictly though we can send an options hash as the second argument to form_Tag

then we get text_field_tag and textarea_tag and way less html and ruby mixed together.

and that's a basic rails form using form_tag

let's not even worry about what to do in create to actually save the new post, but know that we have all the new post data in params and thats step one.

in terms of naming our form fields here, I'd like to avoid the nested params right now and just have them use post_title and post_content and we'll get to nesting with post[content] later.
