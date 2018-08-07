# 0.1.0 -> 0.2.0
* Rename all references of `HyperBuffs` to `Hyperbuffs`
  * Note capitalization change
  * This may require a clean build, e.g. `mix clean` and `MIX_ENV=test mix clean`
* Removes all `defs: ...` from `use Hyperbuffs.View`
* Add `use Hyperbuffs.Router` and preferable start using the `service` route function
* Use [protobuf-elixir](https://github.com/tony612/protobuf-elixir) instead of ExProtobufs
  * Install `protobuf-elixir`
  * Move proto definitions to `priv/protos`
  * Run `protoc` to generate protobufs