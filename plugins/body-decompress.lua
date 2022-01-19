function main()
	pcall(require, "m")
	local response_body = m.getvar("RESPONSE_BODY", "none")
	local data_size = string.len(response_body)
	if data_size > tonumber(m.getvar("tx.body-decompress-plugin_max_data_size_bytes")) then
		m.log(2, string.format("Body Decompress Plugin: Decompression aborted, data are too big (see 'tx.body-decompress-plugin_max_data_size_bytes' in body-decompress-config.conf), data size: %s bytes.", data_size))
	else
		if pcall(require, "zlib") then
			local f = zlib.inflate()
			status, response_body_decompressed = pcall(f, response_body)
			if status then
				m.setvar("tx.response_body_decompressed", response_body_decompressed)
			else
				m.log(2, "Body Decompress Plugin ERROR: Decompression of response body failed.")
			end
		else
			m.log(2, "Body Decompress Plugin ERROR: lua-zlib library not installed, please install it or disable this plugin.")
		end
	end
	return nil
end
