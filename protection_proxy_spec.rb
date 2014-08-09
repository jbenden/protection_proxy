require 'rspec/given'
require 'rspec'
require 'gimme'
RSpec.configure do |config|
      config.mock_framework = Gimme::RSpecAdapter
end
require 'protection_proxy'

describe ProtectionProxy do
  class User
    attr_accessor :name, :email, :membership_level

    def initialize(name, email, membership_level)
      @name = name
      @email = email
      @membership_level = membership_level
    end

    def update_attributes(attrs)
      attrs.each do |attr, value|
        send("#{attr}=", value)
      end
    end
  end

  class ProtectedUser < ProtectionProxy
    role :owner do
      writable :membership_level
    end
    role :browser do
      writable :name, :email
      writable :password
    end
  end

  Given!(:user) { User.new("Jim", "jim@somewhere.com", "Beginner") }

  context "when user the owner role" do
    Given!(:proxy) { ProtectedUser.find_proxy(user, :owner) }

    Then { expect(proxy.name).to eq("Jim") }

    context "when I change a writable attribute" do
      When { proxy.membership_level = "Advanced" }
      Then { expect(proxy.membership_level).to eq("Advanced") }
    end

    context "when I change a protected attribute" do
      When { proxy.name = "Joe" }
      Then { expect(proxy.name).to eq("Jim") }
    end

    context "when I use update attributes" do
      When { proxy.update_attributes(name: "Joe", membership_level: "Advanced") }
      Then { expect(proxy.name).to eq("Jim") }
      Then { expect(proxy.membership_level).to eq("Advanced") }
    end

    describe "the interaction with the original update_attributes" do
      Given!(:user) { gimme(User) }
      When { proxy.update_attributes(name: "Joe", membership_level: "Advanced") }
      Then { verify(user).update_attributes(membership_level: "Advanced").inspect }
    end
  end

  context "when user the browser role" do
    Given!(:proxy) { ProtectedUser.find_proxy(user, :browser) }

    Then { expect(proxy.name).to eq("Jim") }

    context "when I change a writable attribute" do
      When { proxy.name = "Joe" }
      Then { expect(proxy.name).to eq("Joe") }
    end

    context "when I change a protected attribute" do
      When { proxy.membership_level = "SuperUser" }
      Then { expect(proxy.membership_level).to eq("Beginner") }
    end

    context "when I use update attributes" do
      When { proxy.update_attributes(name: "Joe", membership_level: "Advanced") }
      Then { expect(proxy.name).to eq("Joe") }
      Then { expect(proxy.membership_level).to eq("Beginner") }
    end

    describe "the interaction with the original update_attributes" do
      Given!(:user) { gimme(User) }
      When { proxy.update_attributes(name: "Joe", membership_level: "Advanced") }
      Then { verify(user).update_attributes(name: "Joe").inspect }
    end
  end

end
