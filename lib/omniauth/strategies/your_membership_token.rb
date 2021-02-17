require'omniauth'
require'your_membership'

module OmniAuth
  module Strategies
    class YourMembershipToken
      include OmniAuth::Strategy

      E_YM_SESSION_ID_BLANK = <<~EOS
        Assertion failed: YourMembership ID blank during callback_phase. This ID
        was stored in the Rack session during the request_phase but has not
        survived to (is no longer present in) the callback_phase.
      EOS
      RACK_SESSION_KEY = 'omniauth_ym_session_id'.freeze

      # The UID is going to be the member's API id (member_id)
      # We'll also store the session ID
      option :fields, [:member_id, :ym_session]
      option :uid_field, :member_id

      def request_phase

        # We're doing this because the callback_url is built from the
        # options.name attribute which is built by down-casing the name of the
        # class. This returns an un-capitalized url which Rails will not
        # recognize as the same path as the devise controller. This is a forced
        # way to do this and probably has a more elegant solution.
        options.name = 'yourMembershipToken'
        # Build an Access Token
        session = YourMembership::Session.create
        token_hash = session.createToken(:RetUrl => callback_url)

        # Store the YourMembership session id somewhere it can be retrieved
        # during the callback_phase.
        #
        # In OmniAuth 1, we were able to do:
        #
        #     request.params['ym_session'] = session.to_s
        #
        # but this seems no longer possible in OmniAuth 2 (as described in
        # https://github.com/omniauth/omniauth/issues/975). So, the only thing I
        # can think of is to use `env['rack.session']`. If a better solution
        # is discovered, we can revisit this decision.
        env['rack.session'][RACK_SESSION_KEY] = session.to_s

        # Redirect to token url
        redirect token_hash['GoToUrl']
      end

      # See discussion in `request_phase` re: the use of `env['rack.session']`.
      def callback_phase
        ym_session_id = env['rack.session'][RACK_SESSION_KEY]
        fail!(E_YM_SESSION_ID_BLANK) if ym_session_id.blank?
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
