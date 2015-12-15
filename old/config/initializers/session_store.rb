# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_test-histories_session',
  :secret      => '976110e6794dcc5e6956bc251357ba6c273ec25399218d0a42c2d9ade21d2da2d343e36ea036afb40a05d4f748a191801cf235c92ee4a679be55401b61ee03b7'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
