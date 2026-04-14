module PaperTrailHelpers
  def update_entry_folios(entry, folios)
    visit edit_entry_path(entry)
    fill_in 'folios', with: folios
    find(".save-button", match: :first).click
    sleep(1.1)
  end

  def update_entry_title(entry, title)
    visit edit_entry_path(entry)
    fill_in 'title_0', with: title
    find('.save-button', match: :first).click
    sleep(1.5)
  end

  def add_entry_title(entry, title)
    visit edit_entry_path(entry)
    find_by_id('add_title').click
    fill_in 'title_1', with: title
    find('.save-button', match: :first).click
    sleep(1.5)
  end

  def open_history_revert(item_text)
    # The history carousel renders duplicate/hidden DOM fragments, so this
    # keeps the helper deterministic without coupling the spec to carousel
    # internals anywhere else.
    item = page.evaluate_script(<<~JS)
      (function() {
        var items = Array.prototype.slice.call(document.querySelectorAll('.carousel-inner .item'));
        var target = items.find(function(el) {
          return el.textContent.indexOf(#{item_text.to_json}) !== -1;
        });
        if (!target) { return null; }
        var link = target.querySelector('.btn-undo');
        if (!link) { return null; }
        link.click();
        return true;
      })();
    JS

    raise Capybara::ElementNotFound, "Unable to find history item containing #{item_text.inspect}" unless item
  end
end
