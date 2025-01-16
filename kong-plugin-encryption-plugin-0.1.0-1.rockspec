package = "kong-plugin-encryption-plugin"
version = "1.0.0-1"
source = {
  url = "https://your-repo-url/encryption-plugin.tar.gz",
}
description = {
  summary = "A Kong plugin to encrypt responses with a public key",
  homepage = "https://your-repo-url",
  license = "MIT",
}
dependencies = {
  "lua-resty-openssl >= 0.7.2",
  "kong >= 3.0",
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.encryption-plugin.handler"] = "encryption-plugin.lua",
    ["kong.plugins.encryption-plugin.schema"] = "schema.lua",
  },
}
