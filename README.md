# Omniauth::Strategies::YourMembershipToken

This is an OmniAuth Strategy for authenticating to YourMembership implementations using token-based authentication.

## Installation

Add these lines to your application's Gemfile:

  gem 'omniauth'
  gem 'omniauth-your-membership-token'

And then execute:

    $ bundle install

## Usage

`OmniAuth::Strategies::YourMembershipToken` is simply a Rack middleware. Read the OmniAuth docs for detailed instructions: https://github.com/intridea/omniauth.

This strategy depends on the `your_membership` gem. You will need to configure your YourMembership environment before you can use this strategy for authentication. Read the documentation for that gem for instructions: https://github.com/ECHOInternational/your_membership

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb:`

```RUBY
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :yourMembershipToken
end
```

## Auth Hash

Here's an example Auth Hash available in `request.env['omniauth.auth']`:

```RUBY
{
  :provider => YourMembershipToken,
  :uid => 234235D-3234-2342252-AS432, # YourMembership API Member ID
  :extra => {
    :access_token => 453532-D234234-234234-D2132, # YourMembership Authenticated Session ID
  }
}
```

## Interacting with the returned Session ID

`request.env['omniauth.auth']['extra']['access_token']` provides the authenticated session ID as a way for the authenticated user to interact with the YourMembership API through the Ruby SDK.

Due to the fact that Rails (and most other frameworks) don't maintain object state between requests it is incumbent upon you to implement the storage and retrieval of the Session ID and an ever-incrementing call counter.

Upon authorization set the call counter to 10 or more to account for calls during authentication.

Here's an example of how to maintain a call counter in an ActiveRecord model. Your User table will need to have these fields at minimum:
+ provider
+ uid
+ remote_session_call_counter
+ remote_session

```RUBY
class User < ActiveRecord::Base

  # Create user if it doesn't exist (this probably isn't necessary if you're using Devise or another Auth Framework)
  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
    end
  end

  # An example API call
  def member
    # You need to increment the call_counter before every call or you'll get errors from YourMembership's API
    update_remote_session_call_counter
    YourMembership::Member.create_from_session ym_session
  end

  def ym_session
    # Cache the session object so that you aren't re-creating it with every call.
    @session ||= YourMembership::Session.new remote_session, remote_session_call_counter
  end

  def update_remote_session_call_counter
    # Make the database call_counter match that which is in the session object
    update(remote_session_call_counter: ym_session.call_id)
  end

  def abandon_remote_session
    begin
      update_remote_session_call_counter
      ym_session.abandon
    rescue YourMembership::Error => e
      logger.info "YourMembership returned error #{e.error_code}: #{e.error_description}"
    ensure
      update(remote_session: nil)
      update(remote_session_call_counter: 200)
      save
    end
  end
end
```

And you would want to do something like this in your session controller:

```RUBY
class SessionsController < ApplicationController
  # This will save you a headache when using remote authentication
  skip_before_filter :verify_authenticity_token, :only => :create
  
  # This is the standard way to access an OmniAuth strategy, this may change for your framework of choice.
  def new
    redirect_to '/auth/yourmembershiptoken'
  end

  def create
    auth = request.env["omniauth.auth"]
    user = User.where(:provider => auth['provider'],
                      :uid => auth['uid'].to_s).first || User.create_with_omniauth(auth)

    #Remember the current session so you can access it later
    user.remote_session = auth['extra']['access_token']
    user.remote_session_call_counter = 300
    user.save

    reset_session
    session[:user_id] = user.id
    redirect_to root_url, :notice => 'Signed in!'
  end

  def destroy
    current_user.abandon_remote_session
    reset_session
    redirect_to root_url, :notice => 'Signed out!'
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end

end
```

### Session Expiration

You'll need to watch out for sessions expiring. An easy way to recover from an expired session is to write a rescue_from method in your `application.rb`

Here's an example:

```Ruby
rescue_from YourMembership::Error do | error |
  case error.error_code
  when '202'
    reset_session
    redirect_to root_url, :notice => 'Your Session Timed Out.'
  else
    raise error
  end
end
```