local typedefs = require "kong.db.schema.typedefs"

return {
  name = "encryption-plugin",
  fields = {
    { consumer = typedefs.no_consumer }, -- This plugin does not apply to specific consumers
    { protocols = typedefs.protocols_http }, -- Applies only to HTTP and HTTPS
    {
      config = {
        type = "record",
        fields = {
          { public_key = { type = "string", required = true } }, -- Public key for encryption
        },
      },
    },
  },
}
