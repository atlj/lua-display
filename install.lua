local repo_url = "https://raw.githubusercontent.com/atlj/lua-display/refs/heads/main/"
local repo_pattern = "https://raw.githubusercontent.com/atlj/lua%-display/refs/heads/main/"

local files_request, fail_message = http.get {
  url = repo_url .. "files.txt",
}

if files_request == nil then
  print("Error fetching files " .. fail_message)
  os.exit(1)
end

local pending_requests = 0

while true do
  local file_path = files_request.readLine(false)

  if file_path == nil then
    break
  end

  http.request {
    url = repo_url .. file_path
  }

  pending_requests = pending_requests + 1
end

---@type table<string, string>
local files_to_write = {}

while true do
  if pending_requests == 0 then
    break
  end

  local event, url, response = os.pullEvent()

  if event == 'http_failure' then
    print("http request failed")
    os.exit(1)
  end

  if event == 'http_success' then
    ---@cast url string
    ---@cast response ccTweaked.http.Response
    local file_path = string.gsub(url, repo_pattern, "")

    files_to_write[file_path] = response.readAll()

    pending_requests = pending_requests - 1
  end
end


fs.delete("display")
for path, contents in pairs(files_to_write) do
  local file_handle = io.open(path, "w")

  file_handle:write(contents)
  file_handle:close()
end

print("Fetched all the files")
