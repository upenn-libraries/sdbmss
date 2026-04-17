# NOTE: because of how asychnronous this is, it seems to be basically untestable using capybara, so....

require "rails_helper"

describe "Groups", :js => true do
  let(:group_owner) { create(:admin) }
  let!(:contributor) { create(:user, role: "contributor") }
  let(:group_name) { "The Society of the Friends of the Constitution" }
  let(:group_description) { "Meeting at the monastary of the Jacobins on Rue St. Honore" }
  let!(:group) do
    Group.create!(
      name: group_name,
      description: group_description,
      public: true,
      created_by: group_owner
    )
  end

  context "when user is logged in " do
    before :each do
      GroupUser.create!(group: group, user: group_owner, role: 'Manager', confirmed: true)
      login(group_owner, 'somethingreallylong')
    end

    it "should allow the user to create a group" do
      visit groups_path

      click_link 'Add New'
      expect(page).to have_content('New Group')
      fill_in 'group_name', with: group_name
      fill_in 'group_description', with: group_description
      check 'group_public'
      click_button 'Save Group'

      expect(page).to have_content(group_name)
    end

    it "should allow the user to invite other users to join" do
      visit groups_path
      find(:link, group_name, match: :first).click

      expect(page).to have_content(group_name)
      expect(page).to have_content('This group does not have permission to edit any entries at the moment.')

      # the multiselect dropdown would be a nightmare to do properly, so....
      expect(page).to have_content('None selected')
      click_button 'None selected'
      find("#select_users option[value='#{contributor.id}']", visible: false).select_option
      find('.multiselect', match: :first).trigger 'click'

      click_button 'Invite'

      expect(page).to have_content('Invitations sent!')
    end

    it "should allow users to accept group invitations" do
      GroupUser.create!(group: group, user: contributor, role: 'Member', confirmed: false, created_by: group_owner)
      page.reset!
      login(contributor, 'somethingreallylong')
      visit groups_path
      expect(page).to have_content(group_name)
      find(:link, 'Accept Invitation', match: :first).click
      expect(page).to have_content(group_name)
      expect(page).not_to have_content 'Accept Invitation'
    end

    it "should allow a user to add a single entry to a user group" do
      visit entry_path(Entry.first)
      expect(page).to have_content('This entry is not being worked on by any user groups at the moment.')
      # select group.id.to_s, from: 'group_id'  # for some reason this doesn't work, but my one group is by default selected anyway so...
      check 'editable'
      click_button 'Add'

      expect(page).to have_content "This entry is being edited by #{group_name} (Editable)"
    end

    it "should allow many entries to be added to a group from the manage table" do
      visit entries_path
      expect(page).to have_content(Entry.first.public_id)
      find('#select-all', match: :first).click
      click_link 'Add/Remove Groups'

      expect(page).to have_content('Add/Remove Records From Your Groups')
      # but don't check 'editable!'
      click_button 'Add'
      expect(page).to have_content('Records Added To Group')
    end

    it "should confer/restrict editing privileges on all members of a group as appropriate" do
      GroupUser.create!(group: group, user: contributor, role: 'Member', confirmed: true, created_by: group_owner)
      GroupRecord.create!(group: group, record: Entry.first, editable: true)
      page.reset!
      login(contributor, 'somethingreallylong')
      visit entry_path(Entry.first)
      expect(page).to have_content("Edit #{Entry.first.public_id}")

      visit entry_path(Entry.last)
      expect(page).not_to have_content("Edit #{Entry.last.public_id}")
    end

    it "should allow a user to remove records from a group" do
      visit entries_path
      expect(page).to have_content(Entry.last.public_id)
      find('#select-all', match: :first).click
      click_link 'Add/Remove Groups'
      expect(page).to have_content('Add/Remove Records From Your Groups')
      
      click_button 'Remove'
      expect(page).to have_content("records removed from '#{group_name}'")
    end

    it "should allow a group manager to remove a user from their group" do
      GroupUser.create!(group: group, user: contributor, role: 'Member', confirmed: true, created_by: group_owner)
      visit edit_group_path(group)
      expect(page).to have_content(contributor.to_s)
      accept_data_confirm_modal_from do
        click_link 'Delete'
      end
      expect(page).not_to have_content(contributor.to_s)
    end

    it "should allow a user to request admission to a group" do
      page.reset!
      login(contributor, 'somethingreallylong')
      visit group_path(group)
      expect(page).to have_content('Request Membership')
      find('#collapse-control').click
      find(:link, 'Request Membership', match: :first).click
      expect(page).to have_content('You have requested membership in this group')
      
      page.reset!
      login(group_owner, 'somethingreallylong')
      visit edit_group_path(group)
      expect(page).to have_content('Request Pending')
      click_link 'Confirm'
      visit group_path(group)
      expect(page).to have_content(contributor.to_s)
    end

    it "should allow a user to update group details" do
      visit edit_group_path(group)
      fill_in 'group_description', with: '(The Jacobins)'
      click_button 'Save Group'
      visit group_path(group)
      expect(page).to have_content('(The Jacobins)')
    end

    it "should allow a user to destroy a group" do
      visit groups_path
      accept_data_confirm_modal_from do
        within(all("tr", text: group.name, visible: true).first) do
          click_link "Delete"
        end
      end
      expect(Group.where(id: group.id)).to be_empty
      visit groups_path
      expect(page).not_to have_content group_name
    end

  end

end
