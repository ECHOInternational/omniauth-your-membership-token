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
        # Build an Access Token
        session = YourMembership::Session.create
        token_hash = session.createToken(:RetUrl => callback_url)

        # Pass the YourMembership session id to the Callback
        request.params[:ym_session] = session.to_s

        # Redirect to token url
        redirect token_hash['GoToUrl']
      end

      def callback_phase
        # create session object

        ym_session  = YourMembership::Session.new(request.env['omniauth.params'][:ym_session], 100)

        fail! 'Failed To Log In' unless ym_session
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