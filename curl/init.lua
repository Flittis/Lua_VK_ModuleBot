local ffi = require 'ffi'
local C = ffi.C
local lib = ffi.load 'libcurl'
local h = io.open('./curl/easy.h', 'r')
if h then
	ffi.cdef(h:read'*a')
	h:close()
else error('Can\'t open cURL header file.') end

local writefunc = ffi.cast('curl_write_callback', function(buf, size, num, ud)
	local realsize = size * num
	local struct = ffi.cast('struct mycurlbuffer *', ud)
	local bufsize = realsize + 1

	if struct.buf == 0 then
		struct.buf = C.malloc(bufsize)
	else
		bufsize = struct.size + bufsize
		struct.buf = C.realloc(struct.buf, bufsize)
		struct.buf[struct.size] = 0
	end

	ffi.copy(struct.buf + struct.size, buf, realsize)
	struct.size = struct.size + realsize
	return realsize
end)

local cbuftyp = ffi.typeof('struct mycurlbuffer')
local cbufsz = ffi.sizeof(cbuftyp)
local allocbuffer = function()
	local mem = C.malloc(cbufsz)
	C.memset(mem, 0, cbufsz)
	return ffi.cast('struct mycurlbuffer *', mem)
end

function curl_request(url, ua)
	local data = allocbuffer()
	local h = lib.curl_easy_init()
	local res = lib.curl_easy_setopt(h, lib.CURLOPT_URL, url)

	if res == lib.CURLE_OK then res = lib.curl_easy_setopt(h, lib.CURLOPT_WRITEFUNCTION, writefunc)
		if res == lib.CURLE_OK then res = lib.curl_easy_setopt(h, lib.CURLOPT_WRITEDATA, data)
			if res == lib.CURLE_OK then res = lib.curl_easy_setopt(h, lib.CURLOPT_USERAGENT, ua)
				if res == lib.CURLE_OK then res = lib.curl_easy_perform(h) end
			end
		end
	end

	if res == lib.CURLE_OK then
		lib.curl_easy_cleanup(h)
		local str = ffi.string(data.buf)
		C.free(data.buf)
		C.free(data)
		return str
	else return nil, ffi.string(lib.curl_easy_strerror(res)) end
end

function curl_post_request(url, ua, uploadfile)
	local data = allocbuffer()
	local h = lib.curl_easy_init()
	local res = lib.curl_easy_setopt(h, lib.CURLOPT_URL, url)

	local form = lib.curl_mime_init(h);
  local field = lib.curl_mime_addpart(form);
  lib.curl_mime_name(field, 'file');
  lib.curl_mime_filedata(field, uploadfile);

	if res == lib.CURLE_OK then res = lib.curl_easy_setopt(h, lib.CURLOPT_WRITEFUNCTION, writefunc)
		if res == lib.CURLE_OK then res = lib.curl_easy_setopt(h, lib.CURLOPT_WRITEDATA, data)
			if res == lib.CURLE_OK then res = lib.curl_easy_setopt(h, lib.CURLOPT_MIMEPOST, form)
				if res == lib.CURLE_OK then res = lib.curl_easy_perform(h) end
			end
		end
	end

	if res == lib.CURLE_OK then
		lib.curl_easy_cleanup(h)
		lib.curl_mime_free(form)
		local str = ffi.string(data.buf)
		C.free(data.buf)
		C.free(data)
		return str
	else return nil, ffi.string(lib.curl_easy_strerror(res)) end
end
