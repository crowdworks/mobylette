require 'spec_helper'

module Mobylette
  describe RespondToMobileRequests do
    describe 'Configuration' do

      class MockController < ActionController::Base
        include Mobylette::RespondToMobileRequests

        mobylette_config do |config|
          config[:fall_back] = :something
          config[:skip_xhr_requests] = :something
        end
      end

      subject { MockController.new }

      describe "basic configuration delegation" do

        describe "#mobilette_config" do
          it "should have options configured" do
            subject.mobylette_options[:fall_back].should == :something
            subject.mobylette_options[:skip_xhr_requests].should == :something
          end

          it "should set mobylette_options" do
            subject.class.mobylette_config do |config|
              config[:fall_back] = :js
              config[:skip_xhr_requests] = false
            end
            subject.mobylette_options[:fall_back].should == :js
            subject.mobylette_options[:skip_xhr_requests].should be_false
          end
        end

        describe "devices" do
          it "should register devices to Mobylette::Devices" do
            subject.class.mobylette_config do |config|
              config[:devices] = {phone1: %r{phone_1}, phone2: %r{phone_2}}
            end
            Mobylette::Devices.instance.device(:phone1).should == /phone_1/
            Mobylette::Devices.instance.device(:phone2).should == /phone_2/
          end
        end

        describe "fallbacks" do
          context "single fallback" do
            it "should configure the fallback device with only one fallback" do
              mobylette_resolver = double("resolver", replace_fallback_formats_chain: "")
              mobylette_resolver.should_receive(:replace_fallback_formats_chain).with({ mobile: [:mobile, :spec] })
              subject.class.stub(:mobylette_resolver).and_return(mobylette_resolver)
              subject.class.mobylette_config do |config|
                config[:fall_back] = :spec
              end
            end

            it "should not use the :fall_back option when :fallback_chains is present" do
              mobylette_resolver = double("resolver", replace_fallback_formats_chain: "")
              mobylette_resolver.should_not_receive(:replace_fallback_formats_chain).with({ mobile: [:mobile, :spec] })
              mobylette_resolver.should_receive(:replace_fallback_formats_chain).with({ mobile: [:mobile, :mp3] })
              subject.class.stub(:mobylette_resolver).and_return(mobylette_resolver)
              subject.class.mobylette_config do |config|
                config[:fall_back] = :spec
                config[:fallback_chains] = { mobile: [:mobile, :mp3] }
              end
            end
          end

          context "chained fallback" do
            it "should use the fallback chain when present" do
              mobylette_resolver = double("resolver", replace_fallback_formats_chain: "")
              mobylette_resolver.should_receive(:replace_fallback_formats_chain).with({ iphone: [:iphone, :mobile], mobile: [:mobile, :html] })
              subject.class.stub(:mobylette_resolver).and_return(mobylette_resolver)
              subject.class.mobylette_config do |config|
                config[:fallback_chains] = { iphone: [:iphone, :mobile], mobile: [:mobile, :html] }
              end
            end
          end

        end
      end
    end
  end
end