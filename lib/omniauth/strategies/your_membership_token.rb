require'omniauth'
require'your_membership'

module OmniAuth
  module Strategies
    class YourMembershipToken
      include OmniAuth::Strategy

      # The UID is going to be the member's API id (member_id)
      # We'll also store the session ID
      option :fields, [:member_id, :ym_session]
      option :uid_field, :member_id

      def request_phase

        # We're doing this because the callback_url is built from the options.name attribute which is built by downcasing
        # the name of the class. This returns an uncapitalized url which Rails will not recognize as the same path as the
        # devise controller. This is a forced way to do this and probably has a more elegant solution.
        options.name = 'yourMembershipToken'
        # Build an Access Token
        session = YourMembership::Session.create
        #binding.pry
        token_hash = session.createToken(:RetUrl => callback_url)

        # Pass the YourMembership session id to the Callback
        request.params['ym_session'] = session.to_s
        # Redirect to token url
        redirect token_hash['GoToUrl']
      end

      def callback_phase
        # create session object

        ym_session_id = request.env['omniauth.params']['ym_session']

        ym_session  = YourMembership::Session.new(ym_session_id, 100)

        begin
          fail! 'Failed To Log In' unless ym_session.authenticated?
        rescue YourMembership::Error => e
          fail! e.error_description
        end

        @user_id = ym_session.user_id
        @access_token = ym_session.to_s

        super
      end

      uid do
        @user_id
      end

      extra do
        {'access_token' => @access_token}
      end
    end
  end
end
