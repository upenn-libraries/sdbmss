# NOTE: because of how asychnronous this is, it seems to be basically untestable using capybara, so....

require "rails_helper"

describe "Groups", :js => true do

  context "when user is logged in " do
    before :all do
      @admin = User.where(role: "admin").first
      @contributor = User.where(role: "contributor").first
    end

    before :each do
      login(@admin, 'somethingunguessable')
      page.evaluate_script('window.confirm = function() { return true; }')
    end

    it "should allow the user to create a group" do
      visit groups_path

      click_link 'Add New'
      expect(page).to have_content('New Group')
      fill_in 'group_name', with: 'The Society of the Friends of the Constitution'
      fill_in 'group_description', with: 'Meeting at the monastary of the Jacobins on Rue St. Honore'
      check 'group_public'
      click_button 'Save Group'

      expect(page).to have_content('The Society of the Friends of the Constitution')
    end

    it "should allow the user to invite other users to join" do
      visit groups_path
      first(:link, 'The Society of the Friends of the Constitution').click

      expect(page).to have_content('The Society of the Friends of the Constitution')
      expect(page).to have_content('This group does not have permission to edit any entries at the moment.')

      # the multiselect dropdown would be a nightmare to do properly, so....
      expect(page).to have_content('None selected')
      click_button 'None selected'
      first("input[value='#{@contributor.id}']").trigger "click"
      first('.multiselect').trigger 'click'

      click_button 'Invite'

      expect(page).to have_content('Invitations sent!')
    end

    it "should allow users to accept group invitations" do
      page.reset!
      login(@contributor, 'somethingunguessable')
      visit groups_path
      expect(page).to have_content('The Society of the Friends of the Constitution')
      first(:link, 'Accept Invitation').click
      expect(page).to have_content('The Society of the Friends of the Constitution')
      expect(page).not_to have_content 'Accept Invitation'
    end

    it "should allow a user to add a single entry to a user group" do
      visit entry_path(Entry.first)
      expect(page).to have_content('This entry is not being worked on by any user groups at the moment.')
      #select @admin.groups.first.id.to_s, from: 'group_id'  # for some reason this doesn't work, but my ONE group is by default selected anyway so...
      check 'editable'
      click_button 'Add'

      expect(page).to have_content 'This entry is being edited by The Society of the Friends of the Constitution (Editable)'
    end

    it "should allow many entries to be added to a group from the manage table" do
      visit entries_path
      expect(page).to have_content(Entry.last.public_id)
      first('#select-all').click
      click_link 'Add/Remove Groups'

      expect(page).to have_content('Add/Remove Records From Your Groups')
      # but don't check 'editable!'
      click_button 'Add'
      expect(page).to have_content('Records Added To Group')
    end

    it "should confer/restrict editing privileges on all members of a group as appropriate" do
      page.reset!
      login(@contributor, 'somethingunguessable')
      visit entry_path(Entry.first)
      expect(page).to have_content("Edit #{Entry.first.public_id}")

      visit entry_path(Entry.last)
      expect(page).not_to have_content("Edit #{Entry.last.public_id}")
    end

    it "should allow a user to remove records from a group" do
      visit entries_path
      expect(page).to have_content(Entry.last.public_id)
      first('#select-all').click
      click_link 'Add/Remove Groups'
      expect(page).to have_content('Add/Remove Records From Your Groups')
      
      click_button 'Remove'
      expect(page).to have_content("records removed from 'The Society of the Friends of the Constitution'")
    end

    it "should allow a group manager to remove a user from their group" do
      skip "Poltergeist won't let me click on the 'confirm' modal, so......."
      visit edit_group_path(Group.first)
      expect(page).to have_content(@contributor.to_s)
      click_link 'Delete'
      expect(page).to have_content('Are you sure you want to remove this user?')
      
      expect(page).to have_content('Confirm')
      click_button 'Confirm'
      #first('.btn-danger').click
      expect(page).not_to have_content(@contributor.to_s)
    end

    it "should allow a user to request admission to a group" do
      # manually remove contributor from group, since previous test is broken...
      GroupUser.where(user: @contributor).destroy_all
      page.reset!
      login(@contributor, 'somethingunguessable')
      visit group_path(Group.first)
      expect(page).to have_content('Request Membership')
      find('#collapse-control').click
      first(:link, 'Request Membership').click
      expect(page).to have_content('You have requested membership in this group')
      
      page.reset!
      login(@admin, 'somethingunguessable')
      visit edit_group_path(Group.first)
      expect(page).to have_content('Request Pending')
      click_link 'Confirm'
      visit group_path(Group.first)
      expect(page).to have_content(@contributor.to_s)
    end

    it "should allow a user to update group details" do
      visit edit_group_path(Group.first)
      fill_in 'group_description', with: '(The Jacobins)'
      click_button 'Save Group'
      visit group_path(Group.first)
      expect(page).to have_content('(The Jacobins)')
    end

    it "should allow a user to destroy a group" do
      skip "again, the confirm modal... god"
      visit groups_path
      first('.btn-danger').click
      expect(page).to have_content 'Are you sure'
      #click_button 'Confirm'
      expect(page).to have_content 'The Society of the Friends of the Constitution was deleted successfully.'
      visit groups_path
      expect(page).not_to have_content 'The Society of the Friends of the Constitution'
    end

  end

end
