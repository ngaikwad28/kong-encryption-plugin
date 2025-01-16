local ngx = ngx
local kong = kong
local openssl_pkey = require("resty.openssl.pkey")
local resty_str = require("resty.string")

local EncryptionPlugin = {}

-- Constructor
function EncryptionPlugin:new()
  local obj = {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end

-- Header filter phase to remove Content-Length for encrypted responses
function EncryptionPlugin:header_filter()
  ngx.header["Content-Length"] = nil
  ngx.header["Content-Encoding"] = nil -- Remove any existing encoding
end

-- Body filter phase to encrypt the response body
function EncryptionPlugin:body_filter()
  local chunk = ngx.arg[1]
  local eof = ngx.arg[2]

  -- Initialize buffer
  if not ngx.ctx.buffer then
    ngx.ctx.buffer = ""
  end

  if chunk then
    ngx.ctx.buffer = ngx.ctx.buffer .. chunk
    ngx.arg[1] = nil -- Clear the chunk to avoid outputting unencrypted data
  end

  if eof then
    -- Fetch the public key from the plugin configuration
    local public_key = self.public_key
    if not public_key then
      kong.log.err("Public key is not configured in the plugin")
      ngx.arg[1] = ngx.ctx.buffer -- Output the original response if encryption fails
      return
    end

    -- Load the public key
    local pkey, err = openssl_pkey.new(public_key, "public")
    if not pkey then
      kong.log.err("Failed to load public key: ", err)
      ngx.arg[1] = ngx.ctx.buffer -- Output the original response if encryption fails
      return
    end

    -- Encrypt the buffered response
    local ok, encrypted = pcall(function()
      return pkey:encrypt(ngx.ctx.buffer)
    end)

    if not ok or not encrypted then
      kong.log.err("Failed to encrypt response: ", encrypted)
      ngx.arg[1] = ngx.ctx.buffer -- Output the original response if encryption fails
      return
    end

    -- Encode the encrypted data in Base64 and output it
    ngx.arg[1] = ngx.encode_base64(encrypted)
  end
end

-- Access phase to set up the plugin configuration
function EncryptionPlugin:access(conf)
  self.public_key = conf.public_key -- Assign the public key from the plugin configuration
end

-- Define the plugin priority and version
EncryptionPlugin.PRIORITY = 10
EncryptionPlugin.VERSION = "1.0.0"

return EncryptionPlugin
