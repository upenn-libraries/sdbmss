
module SDBMSS

  module Capybara

    # Provides handling of confirm/alert dialogs, which capybara and
    # poltergeist simply ignore by default.
    #
    # Adapted from:
    # <https://gist.github.com/michaelglass/8610317>

    module Login    
      def login(user, password)
        visit root_path
        find('#dismiss-welcome').click
        fill_in 'user_login', :with => user.username
        fill_in 'user_password', :with => password
        click_button 'Log in'
        expect(page).to have_content 'Signed in successfully'
      end
    end

    module AlertConfirmer

      def reject_confirm_from &block
        handle_js_modal 'confirm', false, &block
      end

      def accept_confirm_from &block
        handle_js_modal 'confirm', true, &block
      end

      def accept_alert_from &block
        handle_js_modal 'alert', true, &block
      end

      def get_alert_text_from &block
        handle_js_modal 'alert', true, true, &block
        get_modal_text 'alert'
      end

      def get_modal_text(name)
        page.evaluate_script "window.#{name}Msg;"
      end

      private

      def handle_js_modal name, return_val, wait_for_call = false, &block
        modal_called = "window.#{name}.called"
        page.execute_script "
window.original_#{name}_function = window.#{name};
window.#{name} = function(msg) { window.#{name}Msg = msg; window.#{name}.called = true; return #{!!return_val}; };
#{modal_called} = false;
window.#{name}Msg = null;"

        block.call

        if wait_for_call
          timed_out = false
          timeout_after = Time.now + ::Capybara.default_wait_time
          loop do
            if page.evaluate_script(modal_called).nil?
              raise 'appears that page has changed since this method has been called, please assert on page before calling this'
            end
            break if page.evaluate_script(modal_called) ||
                     (timed_out = Time.now > timeout_after)
            sleep 0.001
          end
          raise "#{name} should have been called" if timed_out
        end
      ensure
        page.execute_script "window.#{name} = window.original_#{name}_function"
      end

    end
  end
end
