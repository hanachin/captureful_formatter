require 'spec_helper'
require 'stringio'

describe CapturefulFormatter::Formatter do
  let(:capybara_session)     { double("current_session") }
  let(:formatter)            { CapturefulFormatter::Formatter.new(output) }
  let(:output)               { StringIO.new }

  let(:example)              { RSpec::Core::ExampleGroup.describe.example }
  let(:example_group)        { RSpec::Core::ExampleGroup }

  let(:step_defenition)      { Turnip::Builder::Step.new }

  let(:example_notification) { RSpec::Core::Notifications::ExampleNotification.for(example) }
  let(:group_notification)   { RSpec::Core::Notifications::GroupNotification.new(example_group) }
  let(:start_notification)   { RSpec::Core::Notifications::StartNotification.new }
  let(:step_notification)    { CapturefulFormatter::Notifications::StepNotification.from_step_object(step_defenition) }

  before do
    example
    allow(Capybara).to receive(:current_session).and_return(capybara_session)
    formatter.start start_notification
  end

  subject { formatter }
  it { is_expected.to be_a(CapturefulFormatter::Formatter) }

  context "example group is not :feature" do
    before do
      allow(RSpec::Core::ExampleGroup).to receive(:metadata).and_return({type: :model})
      formatter.example_group_started group_notification
    end

    describe "at step by steps" do
      it "do nothing" do
        expect(capybara_session).not_to receive(:save_screenshot)
        expect(capybara_session).not_to receive(:save_page)
        formatter.step_started step_notification
      end
    end
  end

  context "example group is :feature" do
    before do
      allow(RSpec::Core::ExampleGroup).to receive(:metadata).and_return({type: :feature})
      formatter.example_group_started group_notification
    end

    describe "at step by steps" do
      before { formatter.example_started example_notification }
      after  { formatter.example_passed  example_notification }

      it "save page and screen shot" do
        expect(capybara_session).to receive(:save_screenshot)
        expect(capybara_session).to receive(:save_page)
        formatter.step_started step_notification
      end
    end
  end
end
