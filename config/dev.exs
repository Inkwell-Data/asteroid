use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
#
config :asteroid, AsteroidWeb.Endpoint,
  http: [port: 4000],
  #url: [scheme: "https", host: "www.example.com", path: "/account/auth", port: 443],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :asteroid, AsteroidWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/asteroid_web/views/.*(ex)$},
      ~r{lib/asteroid_web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :mnesia,
   dir: 'Mnesia.#{node()}-#{Mix.env}'

# Hammer is used for cache in some plugs (rate-limiting) and for the OAuth2 device flow

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

# to use Riak uncomment and configure the following lines

#config :pooler,
#  pools: [
#    [
#      name: :riak,
#      group: :riak,
#      max_count: 10,
#      init_count: 5,
#      start_mfa: {Riak.Connection, :start_link, ['127.0.0.1', 8087]}
#    ]
#  ]

######################################################################
######################################################################
################## Asteroid configuration ############################
######################################################################
######################################################################

####################### Token stores #################################

config :asteroid, :token_store_access_token, [
  module: Asteroid.TokenStore.AccessToken.Mnesia
]

config :asteroid, :token_store_refresh_token, [
  module: Asteroid.TokenStore.RefreshToken.Mnesia
]

config :asteroid, :token_store_authorization_code, [
  module: Asteroid.TokenStore.AuthorizationCode.Mnesia
]

config :asteroid, :token_store_device_code, [
  module: Asteroid.TokenStore.DeviceCode.Mnesia
]

config :asteroid, :token_store_request_object, [
  module: Asteroid.TokenStore.GenericKV.Mnesia,
  opts: [table_name: :request_object]
]

config :asteroid, :token_store_refresh_token_before_store_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :token_store_access_token_before_store_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :token_store_authorization_code_before_store_callback,
  &Asteroid.Utils.id_first_param/2

####################### Attribute repositories #######################

# defaults to Mnesia in-memory backend
#
# To enable persistence, add the current node (or another) to the `disc_copies` mnesia option:
#
#   init_opts: [instance: :client, mnesia_config: [disc_copies: [node()]]],
#
# However, before doing that, make sure you understand that it stores sensitive information on
# the disc, such as personal user informations and application passwords, which must be properly
# protected.

config :asteroid, :attribute_repositories,
[
  subject: [
    module: AttributeRepositoryMnesia,
    init_opts: [instance: :subject],
    run_opts: [instance: :subject]
  ],
  client: [
    module: AttributeRepositoryMnesia,
    init_opts: [instance: :client],
    run_opts: [instance: :client]
  ],
  device: [
    module: AttributeRepositoryMnesia,
    init_opts: [instance: :device],
    run_opts: [instance: :device]
  ]
]

####################### API plugs ###################################

config :asteroid, :browser_plugs,
  [
  ]

config :asteroid, :api_oauth2_plugs,
  [
    {APIacAuthBasic,
      realm: "Asteroid",
      callback: &Asteroid.OAuth2.Client.get_client_secret/2,
      set_error_response: &APIacAuthBasic.save_authentication_failure_response/3,
      error_response_verbosity: :debug}#,
    # uncomment the above `#` and the following lines to enable client_secret_post client
    # authentication for all OAuth2 endpoints
    #{APIacAuthClientSecretPost,
    #  realm: "Asteroid",
    #  callback: &Asteroid.Utils.always_nil/2,
    #  set_error_response: &APIacAuthBasic.save_authentication_failure_response/3,
    #  error_response_verbosity: :debug}
  ]

config :asteroid, :api_oauth2_endpoint_token_plugs,
  [
    # uncomment the following lines to enable CORS on the /api/oauth2/token endpoint
    #{Corsica, [origins: "*"]},
    # uncomment the following line to enable throttling for public clients on the
    # /api/oauth2/token endpoint
    #{APIacFilterThrottler,
    #  key: &APIacFilterThrottler.Functions.throttle_by_ip_path/1,
    #  scale: 60_000,
    #  limit: 50,
    #  exec_cond: &Asteroid.Utils.conn_not_authenticated?/1,
    #  error_response_verbosity: :debug},
  ]

config :asteroid, :api_oauth2_endpoint_introspect_plugs,
  [
  ]

config :asteroid, :api_oauth2_endpoint_revoke_plugs,
  [
    # uncomment the following lines to enable CORS on the /api/oauth2/token endpoint
    #{Corsica, [origins: "*"]}
  ]

config :asteroid, :api_oauth2_endpoint_register_plugs,
  [
  ]

config :asteroid, :api_oauth2_endpoint_device_authorization_plugs,
  [
  ]

config :asteroid, :api_request_object_plugs,
  [
    {APIacAuthBasic,
      realm: "Asteroid",
      callback: &Asteroid.OAuth2.Client.get_client_secret/2,
      set_error_response: &APIacAuthBasic.send_error_response/3,
      error_response_verbosity: :debug}
  ]

config :asteroid, :discovery_plugs,
  [
  ]

config :asteroid, :well_known_plugs,
  [
  ]

####################### Crypto configuration #########################

config :asteroid, :crypto_keys, %{
  "key_auto" => {:auto_gen, [params: {:rsa, 2048}, use: :sig, advertise: false]}
}

config :asteroid, :crypto_keys_cache, {Asteroid.Crypto.Key.Cache.ETS, []}

####################### OAuth2 general configuration ################

config :asteroid, :oauth2_grant_types_enabled, [
  :authorization_code,
  :implicit,
  :password,
  :client_credentials,
  :refresh_token,
  :"urn:ietf:params:oauth:grant-type:device_code"
]

config :asteroid, :oauth2_response_types_enabled, [
  :code,
  :token
]

config :asteroid, :api_error_response_verbosity, :normal

config :asteroid, :oauth2_scope_callback,
  &Asteroid.OAuth2.Scope.grant_for_flow/2

config :asteroid, :oauth2_access_token_lifetime_callback,
  &Asteroid.Token.AccessToken.lifetime/1

config :asteroid, :oauth2_refresh_token_lifetime_callback,
  &Asteroid.Token.RefreshToken.lifetime/1

config :asteroid, :oauth2_authorization_code_lifetime_callback,
  &Asteroid.Token.AuthorizationCode.lifetime/1

config :asteroid, :oauth2_issue_refresh_token_callback,
  &Asteroid.Token.RefreshToken.issue_refresh_token?/1

config :asteroid, :oauth2_access_token_serialization_format_callback,
  &Asteroid.Token.AccessToken.serialization_format/1

config :asteroid, :oauth2_access_token_signing_key_callback,
  &Asteroid.Token.AccessToken.signing_key/1

config :asteroid, :oauth2_access_token_signing_alg_callback,
  &Asteroid.Token.AccessToken.signing_alg/1

####################### OAuth2 grant types ###########################

# ROPC

config :asteroid, :oauth2_endpoint_token_grant_type_password_before_send_resp_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_token_grant_type_password_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

# refresh token

config :asteroid, :oauth2_endpoint_token_grant_type_refresh_token_before_send_resp_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_token_grant_type_refresh_token_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

####################### OAuth2 endpoints #############################

# authorize

config :asteroid, :oauth2_endpoint_authorize_before_send_redirect_uri_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_authorize_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :web_authorization_callback,
  &AsteroidWeb.AuthorizeController.select_web_authorization_callback/2

# token

config :asteroid, :oauth2_endpoint_token_grant_type_client_credentials_before_send_resp_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_token_grant_type_client_credentials_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_token_grant_type_authorization_code_before_send_resp_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_token_grant_type_authorization_code_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_token_auth_methods_supported_callback,
  &Asteroid.OAuth2.Endpoint.token_endpoint_auth_methods_supported/0

# introspect

config :asteroid, :oauth2_endpoint_introspect_client_authorized,
  &Asteroid.OAuth2.Client.endpoint_introspect_authorized?/1

config :asteroid, :oauth2_endpoint_introspect_claims_resp, [
  "scope",
  "client_id",
  "username",
  "token_type",
  "exp",
  "iat",
  "nbf",
  "sub",
  "aud",
  "iss",
  "jti"
]

config :asteroid, :oauth2_endpoint_introspect_claims_resp_callback,
  &Asteroid.OAuth2.Introspect.endpoint_introspect_claims_resp/1

config :asteroid, :oauth2_endpoint_introspect_before_send_resp_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_introspect_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

# revoke

config :asteroid, :oauth2_endpoint_revoke_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

# dynamic client registration

config :asteroid, :oauth2_endpoint_register_authorization_callback,
  &Asteroid.OAuth2.Register.request_authorized?/2

config :asteroid, :oauth2_endpoint_register_authorization_policy, :authorized_clients

config :asteroid, :oauth2_endpoint_register_additional_metadata_field, []

config :asteroid, :oauth2_endpoint_register_before_send_resp_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_register_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_register_client_before_save_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_register_gen_client_id_callback,
  &Asteroid.OAuth2.Register.generate_client_id/2

config :asteroid, :oauth2_endpoint_register_gen_client_resource_id_callback,
  &Asteroid.OAuth2.Register.generate_client_resource_id/2

config :asteroid, :oauth2_endpoint_register_client_type_callback,
  &Asteroid.OAuth2.Register.client_type/1

# metadata

config :asteroid, :oauth2_endpoint_metadata_before_send_resp_callback,
  &Asteroid.Utils.id/1

config :asteroid, :oauth2_endpoint_metadata_before_send_conn_callback,
  &Asteroid.Utils.id/1

# discovery

config :asteroid, :oauth2_endpoint_discovery_keys_before_send_resp_callback,
  &Asteroid.Utils.id/1

config :asteroid, :oauth2_endpoint_discovery_keys_before_send_conn_callback,
  &Asteroid.Utils.id/1


####################### OAuth2 flows #################################

# ROPC

config :asteroid, :oauth2_flow_ropc_issue_refresh_token_init, true

config :asteroid, :oauth2_flow_ropc_issue_refresh_token_refresh, false

config :asteroid, :oauth2_flow_ropc_refresh_token_lifetime, 60 * 60 * 24 * 7 # 1 week

config :asteroid, :oauth2_flow_ropc_access_token_lifetime, 60 * 10

# client credentials

config :asteroid, :oauth2_flow_client_credentials_issue_refresh_token_init, false

config :asteroid, :oauth2_flow_client_credentials_issue_refresh_token_refresh, false

config :asteroid, :oauth2_flow_client_credentials_access_token_lifetime, 60 * 10

# authorization code

config :asteroid, :oauth2_flow_authorization_code_issue_refresh_token_init, true

config :asteroid, :oauth2_flow_authorization_code_issue_refresh_token_refresh, false

config :asteroid, :oauth2_flow_authorization_code_authorization_code_lifetime, 60

config :asteroid, :oauth2_flow_authorization_code_refresh_token_lifetime, 3600 * 24 * 7 # 1 week

config :asteroid, :oauth2_flow_authorization_code_access_token_lifetime, 60 * 10

config :asteroid, :oauth2_flow_authorization_code_pkce_policy, :optional

config :asteroid, :oauth2_flow_authorization_code_pkce_allowed_methods, [:S256]

config :asteroid, :oauth2_flow_authorization_code_pkce_client_callback,
  &Asteroid.OAuth2.Client.must_use_pkce?/1

# implicit

config :asteroid, :oauth2_flow_implicit_access_token_lifetime, 60 * 60

# device authorization

config :asteroid, :oauth2_endpoint_device_authorization_before_send_resp_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_device_authorization_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :token_store_device_code_before_store_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_flow_device_authorization_device_code_lifetime, 60 * 15

config :asteroid, :oauth2_flow_device_authorization_user_code_callback,
  &Asteroid.OAuth2.DeviceAuthorization.user_code/1

config :asteroid, :oauth2_flow_device_authorization_issue_refresh_token_init, true

config :asteroid, :oauth2_flow_device_authorization_issue_refresh_token_refresh, false

config :asteroid, :oauth2_flow_device_authorization_refresh_token_lifetime, 10 * 365 * 24 * 3600

config :asteroid, :oauth2_flow_device_authorization_access_token_lifetime, 60 * 10

config :asteroid, :oauth2_endpoint_token_grant_type_device_code_before_send_resp_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_token_grant_type_device_code_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_flow_device_authorization_rate_limiter,
  {Asteroid.OAuth2.DeviceAuthorization.RateLimiter.Hammer, []}

config :asteroid, :oauth2_flow_device_authorization_rate_limiter_interval, 5

####################### Scope configuration ##########################

config :asteroid, :scope_config, []

config :asteroid, :oauth2_scope_config, []

config :asteroid, :oauth2_flow_authorization_code_scope_config, []

config :asteroid, :oauth2_flow_implicit_scope_config, []

config :asteroid, :oauth2_flow_client_credentials_scope_config, []

config :asteroid, :oauth2_flow_ropc_scope_config, []

config :asteroid, :oauth2_flow_device_authorization_scope_config, []

####################### OAuth2 JAR #################################

config :asteroid, :oauth2_jar_enabled, :enabled

config :asteroid, :oauth2_jar_request_object_signing_alg_values_supported, ["RS256", "ES384"]

config :asteroid, :oauth2_jar_request_object_lifetime, 60

config :asteroid, :oauth2_jar_request_uri_get_opts, [
  follow_redirect: false,
  max_body_length: 1024 * 20, # 20 ko
  timeout: 1000
]

####################### OIDC general configuration ################

config :asteroid, :oidc_id_token_lifetime_callback,
  &Asteroid.Token.IDToken.lifetime/1

config :asteroid, :oidc_id_token_signing_key_callback,
  &Asteroid.Token.IDToken.signing_key/1

config :asteroid, :oidc_id_token_signing_alg_callback,
  &Asteroid.Token.IDToken.signing_alg/1

config :asteroid, :token_id_token_before_serialize_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oidc_issue_id_token_on_refresh_callback,
  &Asteroid.Token.IDToken.issue_id_token?/1
