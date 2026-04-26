Rails.application.config.session_store :cookie_store,
  key: "_stockflow_session",
  domain: :all,
  tld_length: 2