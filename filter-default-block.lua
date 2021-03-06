-- DNS based Internet Access Policy
-- Check Block List, Check Allow List, Default: Block

-- Configuration
ipv4_redirect_host = "127.0.0.1"
allow_list_file = "allow.db"
block_list_file = "block.db"

-- Load List File
function load_list_file(file)
	local list = {}
	
	for line in io.lines(file) do
		if string.len(line) > 0 and string.sub(line, 1, 1) ~= "#" then
			table.insert(list, line .. ".")
		end
	end
	
	return list
end

block_list = load_list_file(block_list_file)
allow_list = load_list_file(allow_list_file)

function check_iap_acl(acl_list, domain)
	for k,v in pairs(acl_list) do
		if string.sub(domain, -string.len(v)) == v then
			return true
		end
	end
	
	return false
end

-- Resolver Function Override
function preresolve(requestorip, domain, qtype)
	if qtype == pdns.A then
		if check_iap_acl(block_list, domain) then
			-- Redirect on Block List Match
			return 0, { {qtype=pdns.A, content=ipv4_redirect_host} }
		elseif check_iap_acl(allow_list, domain) then
			-- Continue on Allow List Match
			return -1, {}
		else
			-- Redirect on No List Match (Default Policy)
			return 0, { {qtype=pdns.A, content=ipv4_redirect_host} }
		end
	end
	
	-- Continue if not an A record.
	return -1, {}
end