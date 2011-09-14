module Mobylette
  module Controllers

    # Mobylette::Controllers::RespondToMobileRequests includes the respond_to_mobile_requests
    # to your ActionController::Base.
    #
    # The respond_to_mobile_requests method enables the controller mobile handling
    module RespondToMobileRequests
      extend ActiveSupport::Concern

      included do
        helper_method :is_mobile_request?
        helper_method :is_mobile_view?

        # List of mobile agents, from mobile_fu (https://github.com/brendanlim/mobile-fu)
        MOBILE_USER_AGENTS =  'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' +
                              'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' +
                              'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|' +
                              'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' +
                              'webos|amoi|novarra|cdm|alcatel|pocket|iphone|mobileexplorer|mobile'
      end

      module ClassMethods

        # This method enables the controller do handle mobile requests
        #
        # You must add this to every controller you want to respond differently to mobile devices,
        # or make it application wide calling it from the ApplicationController
        #
        # Options:
        # * :fall_back => :html
        #     You may pass a fall_back option to the method, it will force the render
        #     to look for that other format, in case there is not a .mobile file for the view.
        #     By default, it will fall back to the format of the original request.
        #     If you don't want fall back at all, pass :fall_back => false
        #
        def respond_to_mobile_requests(options = {})
          return if self.included_modules.include?(Mobylette::Controllers::RespondToMobileRequestsMethods)

          cattr_accessor :fall_back_format
          self.fall_back_format   = options[:fall_back]

          self.send(:include, Mobylette::Controllers::RespondToMobileRequestsMethods)
        end
      end

      module InstanceMethods

        private

        # :doc:
        # This helper returns exclusively if the request's  user_aget is from a mobile
        # device or not.
        def is_mobile_request?
          request.user_agent.to_s.downcase =~ /#{MOBILE_USER_AGENTS}/
        end

        # :doc:
        # This helper returns exclusively if the current format is mobile or not
        def is_mobile_view?
          true if (request.format.to_s == "mobile") or (params[:format] == "mobile")
        end

      end

    end

    # RespondToMobileRequestsMethods is included by respond_to_mobile_requests
    #
    # This will check if the request is from a mobile device and change
    # the request format to :mobile
    module RespondToMobileRequestsMethods
      extend ActiveSupport::Concern

      included do
        before_filter :handle_mobile
      end

      module InstanceMethods
        private

        # :doc:
        # Changes the request.form to :mobile, when the request is from
        # a mobile device
        def handle_mobile
          return if session[:mobylette_override] == :ignore_mobile
          if not request.xhr? and ((session[:mobylette_override] == :force_mobile) or (is_mobile_request?))
            original_format   = request.format.to_sym
            request.format    = :mobile
            if self.fall_back_format != false
              request.formats << Mime::Type.new((self.fall_back_format if self.fall_back_format) || original_format)
            end
          end
        end
      end
    end
  end
end