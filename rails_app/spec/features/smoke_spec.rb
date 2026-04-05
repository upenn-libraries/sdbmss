require "rails_helper"

# Fast smoke suite: ~10 tests, ~5-8 min.
# Validates core infrastructure + all before:each regressions fixed in Phase 2.
# Run with: RAILS_ENV=test bundle exec rspec spec/features/smoke_spec.rb

describe "Smoke Tests", :js => true do

  before :each do
    @admin = User.where(role: "admin").first
    @contributor = User.where(role: "contributor").first
  end

  # --- Infrastructure ---

  it "logs in successfully" do
    login(@admin, 'somethingunguessable')
    visit root_path
    expect(page).to have_content(@admin.username)
  end

  it "searches entries via Solr" do
    login(@admin, 'somethingunguessable')
    # Entries were indexed in before(:suite); after truncation+reseed the same
    # AUTO_INCREMENT IDs are restored so the Solr index stays valid.
    visit root_path
    click_button "Search"
    expect(page).to have_content(Entry.last.public_id)
  end

  # --- manage_places: before:each fix ---

  it "shows places created in before:each" do
    place = Place.create!(name: "SmokeTestPlace", created_by: @admin)
    login(@admin, 'somethingunguessable')
    # Place.index stages all places for indexing; commit makes them searchable.
    Place.index
    Sunspot.commit
    visit places_path
    expect(page).to have_content("SmokeTestPlace")
  end

  # --- groups: before:each fix ---

  it "shows group created in before:each" do
    group = Group.create!(name: "SmokeTestGroup", public: true, created_by: @admin)
    GroupUser.create!(group: group, user: @admin, role: 'Manager', confirmed: true)
    login(@admin, 'somethingunguessable')
    visit groups_path
    expect(page).to have_content("SmokeTestGroup")
  end

  # --- manage_comments: before:each fix ---

  it "shows comment created in before:each" do
    Comment.create!(comment: "SmokeTestObservation", commentable: Entry.first, created_by: @admin)
    # Commit so the comment is searchable via Solr when the page loads.
    Sunspot.commit
    login(@admin, 'somethingunguessable')
    visit comments_path
    expect(page).to have_content("SmokeTestObservation")
  end

  # --- bookmarks: before:each fix ---

  it "shows bookmark with tag created in before:each" do
    Bookmark.create!(user_id: @admin.id, user_type: 'User', document_id: Entry.last.id.to_s, document_type: 'Entry', tags: 'smoke-tag')
    login(@admin, 'somethingunguessable')
    visit bookmarks_path
    expect(page).to have_content("smoke-tag")
  end

  # --- notify_user: before:each fix ---

  it "notification settings survive truncation" do
    @admin.notification_setting.update!(on_comment: true, on_update: true)
    expect(@admin.notification_setting.on_comment).to be_truthy
    expect(@admin.notification_setting.on_update).to be_truthy
  end

  # --- advanced_search: Solr re-index after truncation ---

  it "advanced search finds entries after truncation" do
    login(@admin, 'somethingunguessable')
    visit advanced_search_path
    find_by_id('advanced-search-submit').click
    expect(page).to have_content("You searched for:")
  end

  # --- data_edit: source.last.id fix ---

  it "redirects to login when accessing new entry without session" do
    visit new_entry_path(source_id: Source.last.id)
    expect(page).to have_content("You need to sign in")
  end

  # --- paper_trail: Entry.last from seed data ---

  it "loads entry history page for seed data entry" do
    login(@admin, 'somethingunguessable')
    e = Entry.last
    visit history_entry_path(e)
    expect(page).to have_content("History of changes to #{e.public_id}")
  end

end
