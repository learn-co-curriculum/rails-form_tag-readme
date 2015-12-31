require 'rails_helper'

describe 'new post' do
  it 'ensures that the form route works with new action' do
    visit new_post_path
    expect(page.status_code).to eq(200)
  end

  it 'has the form render with the new action' do
    visit new_post_path
    expect(page).to have_content("Post Form")
  end

  it 'shows a new form that submits content and redirects to new page and prints out params' do
    visit new_post_path

    fill_in 'post_title', with: "My post title"
    fill_in 'post_description', with: "My post description"

    click_on "Submit Post"

    expect(page).to have_content("My post title")
  end
end