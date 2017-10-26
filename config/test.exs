use Mix.Config

config :mime, :types, %{
  "application/x-protobuf" => ["proto"]
}

config :plug, :validate_header_keys_during_test, false
