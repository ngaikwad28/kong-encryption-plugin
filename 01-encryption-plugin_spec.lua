local PLUGIN_NAME = "encryption-plugin"
local helpers = require "spec.helpers"

describe(PLUGIN_NAME .. ": (plugin)", function()
  local client

  setup(function()
    local bp = helpers.get_db_utils(nil, {
      "routes",
      "services",
      "plugins",
    }, { PLUGIN_NAME })

    local route = bp.routes:insert({
      hosts = { "test.com" },
    })

    bp.plugins:insert({
      name = PLUGIN_NAME,
      route = { id = route.id },
      config = {
        public_key = "-----BEGIN PUBLIC KEY-----\nYOUR_PUBLIC_KEY_HERE\n-----END PUBLIC KEY-----",
      },
    })

    assert(helpers.start_kong({
      plugins = "bundled," .. PLUGIN_NAME,
    }))
  end)

  teardown(function()
    helpers.stop_kong()
  end)

  before_each(function()
    client = helpers.proxy_client()
  end)

  after_each(function()
    if client then
      client:close()
    end
  end)

  it("encrypts the response body", function()
    local res = client:get("/", {
      headers = { host = "test.com" },
    })
    assert.response(res).has.status(200)

    local body = assert.response(res).has.header("content-length")
    assert.is_string(body)
    assert.is_not.equals("plain text body", body) -- Ensure it's encrypted
  end)
end)
