require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

describe "forgotten password" do
  include AcceptanceHelper

  it "can't find an account that doesn't exist" do
    visit "/forgot_password"
    fill_in "email", :with => "someone@somewhere.com"
    click_button "Send"

    assert_match "Your account could not be found, please check your email and try again.", page.body
  end

  it "sets the reset password token" do
    u = Factory(:user, :email => "someone@somewhere.com")
    Notifier.expects(:send_forgot_password_notification)
    assert_nil u.perishable_token

    visit "/forgot_password"
    fill_in "email", :with => "someone@somewhere.com"
    click_button "Send"

    u = User.first(:email => "someone@somewhere.com")
    refute u.perishable_token.nil?
    assert_match "A link to reset your password has been sent to someone@somewhere.com.", page.body
  end
end
