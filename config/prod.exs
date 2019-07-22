use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.

config :asteroid, AsteroidWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: System.get_env("APP_NAME") <> ".gigalixirapp.com", port: 443, scheme: "https"],
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE"),
  http: [port: 4000],
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"


# Do not print debug messages in production
config :logger, level: :debug

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :asteroid, AsteroidWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [
#         :inet6,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :asteroid, AsteroidWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases (distillery)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :asteroid, AsteroidWeb.Endpoint, server: true
#
# Note you can't rely on `System.get_env/1` when using releases.
# See the releases documentation accordingly.

config :phoenix, :json_library, Jason

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

# uncomment to enable the device authorization flow

#config :asteroid, :token_store_device_code, [
#  module: Asteroid.TokenStore.DeviceCode.Mnesia
#]

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
    {Corsica, [origins: "*"]},
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
    {Corsica, [origins: "*"]},
  ]

config :asteroid, :api_oauth2_endpoint_revoke_plugs,
  [
    # uncomment the following lines to enable CORS on the /api/oauth2/token endpoint
    {Corsica, [origins: "*"]}
  ]

config :asteroid, :api_oauth2_endpoint_register_plugs,
  [
  ]

config :asteroid, :api_oauth2_endpoint_device_authorization_plugs,
  [
  ]

config :asteroid, :discovery_plugs,
  [
    {Corsica, [origins: "*"]},
  ]

config :asteroid, :well_known_plugs,
  [
    {Corsica, [origins: "*"]},
  ]

####################### Crypto configuration #########################

config :asteroid, :crypto_keys, %{
  "key_auto" => {:auto_gen, [params: {:rsa, 2048}, use: :sig]}
}

config :asteroid, :crypto_keys_cache, {Asteroid.Crypto.Key.Cache.ETS, []}

####################### OAuth2 general configuration ################

config :asteroid, :oauth2_grant_types_enabled, [
  :authorization_code,
  #:implicit,
  :password,
  :client_credentials,
  :refresh_token,
  #:"urn:ietf:params:oauth:grant-type:device_code"
]

config :asteroid, :oauth2_response_types_enabled, [
  :code,
  #:token
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

config :asteroid, :oauth2_endpoint_authorize_response_type_code_before_send_redirect_uri_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_authorize_response_type_code_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_authorize_response_type_token_before_send_redirect_uri_callback,
  &Asteroid.Utils.id_first_param/2

config :asteroid, :oauth2_endpoint_authorize_response_type_token_before_send_conn_callback,
  &Asteroid.Utils.id_first_param/2

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

config :asteroid, :oauth2_flow_ropc_username_password_verify_callback,
  &Custom.Callback.test_ropc_username_password_callback/3

# client credentials

config :asteroid, :oauth2_flow_client_credentials_issue_refresh_token_init, false

config :asteroid, :oauth2_flow_client_credentials_issue_refresh_token_refresh, false

config :asteroid, :oauth2_flow_client_credentials_access_token_lifetime, 60 * 10

# authorization code

config :asteroid, :oauth2_flow_authorization_code_issue_refresh_token_init, true

config :asteroid, :oauth2_flow_authorization_code_issue_refresh_token_refresh, true

config :asteroid, :oauth2_flow_authorization_code_authorization_code_lifetime, 60

config :asteroid, :oauth2_flow_authorization_code_refresh_token_lifetime, 3600 * 24 * 7 # 1 week

config :asteroid, :oauth2_flow_authorization_code_access_token_lifetime, 60 * 10

config :asteroid, :oauth2_flow_authorization_code_pkce_policy, :optional

config :asteroid, :oauth2_flow_authorization_code_pkce_allowed_methods, [:S256]

config :asteroid, :oauth2_flow_authorization_code_pkce_client_callback,
  &Asteroid.OAuth2.Client.must_use_pkce?/1

config :asteroid, :oauth2_flow_authorization_code_web_authorization_callback,
  &AsteroidWeb.AccountSelectController.start_webflow/2

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

config :asteroid, :scope_config, [
  scopes: %{
    "read_balance" => [
      label: %{
        "en" => "Read my account balance",
        "fr" => "Lire mes soldes de compte",
        "ru" => "Читать баланс счета"
      }
    ],
    "read_account_information" => [
      optional: true,
      label: %{
        "en" => "Read my account transactions",
        "fr" => "Consulter la liste de mes transactions bancaires",
        "ru" => "Читать транзакции по счету"
      }
    ],
    "interbank_transfer" => [
      max_refresh_token_lifetime: 3600 * 24 * 30 * 3,
      max_access_token_lifetime: 3 * 60,
      label: %{
        "en" => "Make bank transfers",
        "fr" => "Réaliser des virements",
        "ru" => "Делать банковские переводы"
      }
    ]
  }
]

config :asteroid, :oauth2_scope_config, []

config :asteroid, :oauth2_flow_authorization_code_scope_config, []

config :asteroid, :oauth2_flow_implicit_scope_config, []

config :asteroid, :oauth2_flow_client_credentials_scope_config, []

config :asteroid, :oauth2_flow_ropc_scope_config, []

config :asteroid, :oauth2_flow_device_authorization_scope_config, []
