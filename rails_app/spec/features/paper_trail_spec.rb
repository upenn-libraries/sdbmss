# paper trail spec

require "rails_helper"

describe "Paper trail", :js => true do
  include PaperTrailHelpers
  let(:admin_user) { create(:admin) }


  before :each do
    @user = admin_user

    @source = Source.find_or_create_by(
      title: "A Sample Test Source With a Highly Unique Name",
      date: "2013-11-12",
      source_type: SourceType.auction_catalog,
    )
    unless @source.source_agents.exists?(role: SourceAgent::ROLE_SELLING_AGENT)
      SourceAgent.create!(
        source: @source,
        role: SourceAgent::ROLE_SELLING_AGENT,
        agent: Name.find_or_create_agent("Sotheby's")
      )
    end
  end

  context "when user is logged in" do

    let(:entry) { Entry.last }

    before :each do
      fast_login(@user)
    end

    after :each do
      page.reset!
    end

    describe '(for simple changes)' do

      it 'should load the history page successfully' do
        visit history_entry_path(entry)

        expect(page).to have_content("History of changes to #{entry.public_id}")
      end

      it "should register changes in the entry basic fields" do
        visit edit_entry_path(entry)

        fill_in 'folios', with: 10000
        find(".save-button", match: :first).click

        expect(page).to have_content(entry.public_id)

        visit history_entry_path(entry)

        expect(page).to have_content('Folios')
        expect(page).to have_content('10000')
      end

      it "should present the option to revert simple changes" do
        update_entry_folios(entry, 10000)
        visit history_entry_path(entry)

        open_history_revert('10000')
        
        expect(page).to have_content('Revert to Old Version')
        expect(page).to have_content('212')
        expect(page).to have_content(entry.public_id)
      end

      it "should successfully restore the previous version" do
        update_entry_folios(entry, 10000)
        visit history_entry_path(entry)

        open_history_revert('10000')
        
        click_button('Restore')

        sleep(1.1)

        visit entry_path(entry)
        expect(page).to have_content(entry.public_id)
        expect(page).to have_content(212)
        expect(page).not_to have_content(10000)
      end
    end

    describe '(for changes to associations)' do
      
      it "should show a change to an association in change history" do
        visit edit_entry_path(entry)
        fill_in 'title_0', with: 'Hiiipower'

        find('.save-button', match: :first).click
        sleep(1.5)

        visit entry_path(entry)

        expect(page).to have_content('Hiiipower')

        visit history_entry_path(entry)
        expect(page).to have_content('Opera minora')
        expect(page).to have_content('Hiiipower')

      end

      it "should show options to revert an 'association' change" do
        update_entry_title(entry, 'Hiiipower')
        visit history_entry_path(entry)

        open_history_revert('Hiiipower')

        expect(page).to have_content(entry.public_id)
        expect(page).to have_content('Hiiipower')
        expect(page).to have_content('Opera minora')
      end

      it "should successfully restore the previous association by overwriting the new field" do
        update_entry_title(entry, 'Hiiipower')
        old_count = entry.entry_titles.count

        visit history_entry_path(entry)

        open_history_revert('Hiiipower')

        click_button('Restore')
        sleep(1.1)

        visit entry_path(entry)
        expect(page).to have_content('Opera minora')
        expect(page).not_to have_content('Hiiipower')
        expect(old_count).to eq(entry.entry_titles.count)      
      end

      it "should save a 'revert' change in the record history" do
        update_entry_title(entry, 'Hiiipower')
        visit history_entry_path(entry)

        open_history_revert('Hiiipower')
        expect(page).to have_content('Hiiipower')
        expect(page).to have_content('Opera minora')
      end

      it "should recreate an associated field that was deleted" do
        old_count = entry.entry_titles.count

        visit edit_entry_path(entry)

        t = find('#title_0').value

        find_by_id("delete_title_0").click
        expect(page).to have_content("Are you sure you want to remove this field and its contents?")
        click_button "Yes"

        find(".save-button", match: :first).click
        
        sleep(1.1)

        new_count = entry.entry_titles.count
        expect(old_count).to eq(new_count + 1)

        visit history_entry_path(entry)
        open_history_revert('deleted Title')

        expect(page).to have_content(t)

        click_button('Restore')

        sleep(1.1)

        expect(page).to have_content(t)
        expect(entry.entry_titles.count).to eq(old_count)
        expect(entry.entry_titles.count).not_to eq(new_count)
      end

      it "should remove an associated field that was created" do
        old_count = entry.entry_titles.count

        add_entry_title(entry, 'Paper Trail Title')
        visit history_entry_path(entry)
        
        open_history_revert('added Title')

        expect(page).to have_content('Paper Trail Title')
        expect(page).to have_content('(Deleted)')
        click_button('Restore')

        sleep(1.1)

        #expect(page).not_to have_content('Book of Hours')
        expect(entry.entry_titles.count).to eq(old_count)
      end
      # revert successfully, add, and combine
    end

  end
end
