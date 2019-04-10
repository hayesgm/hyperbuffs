use Mix.Config

config :mime, :types, %{
  "application/x-protobuf" => ["proto"]
}

config :phoenix,
  json_library: Jason,
  format_encoders: [],
  filter_parameters: []

config :plug, :validate_header_keys_during_test, false
