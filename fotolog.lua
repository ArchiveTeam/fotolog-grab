dofile("urlcode.lua")
dofile("table_show.lua")

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')
local item_dir = os.getenv('item_dir')
local warc_file_base = os.getenv('warc_file_base')

local profilepic = nil
local abortgrab = false

local downloaded = {}
local addedtolist = {}
local profiles = {}

for ignore in io.open("ignore-list", "r"):lines() do
  downloaded[ignore] = true
end

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local html = urlpos["link_expect_html"]
  
  if string.match(url, "^https?://[^/]*fotolog%.com/[^/]+") and not string.match(url, "^https?://sp[0-9a-zA-Z]*%.fotolog%.com") then
    profiles[string.match(url, "^https?://[^/]*fotolog%.com/([^/]+)")] = true
  end

  if (downloaded[url] ~= true and addedtolist[url] ~= true) and (string.match(url, "^https?://[^/]*fotolog%.com") and string.match(url, item_value) or html == 0) and not (string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/twitter_register") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/login/%?redirect=") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/lang_switch") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/friend_add") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/share_overlay") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/report_overlay") or string.match(url, "^https?://[^/]*fotolog%.com/account/photos/edit") or string.match(url, " ") or string.match(url, "%%20")) then
    if string.match(url, "^https?://sp[0-9a-zA-Z]*%.fotolog%.com") and string.match(url, item_value) then
      addedtolist[url] = true
      return true
    elseif not string.match(url, "^https?://sp[0-9a-zA-Z]*%.fotolog%.com") then
      addedtolist[url] = true
      return true
    else
      return false
    end
  else
    return false
  end
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil

  downloaded[url] = true
  
  local function check(urla)
    local url = string.match(urla, "^([^#]+)")
    if string.match(url, "^https?://[^/]*fotolog%.com/[^/]+") and not string.match(url, "^https?://sp[0-9a-zA-Z]*%.fotolog%.com") then
      profiles[string.match(url, "^https?://[^/]*fotolog%.com/([^/]+)")] = true
    end
    if (downloaded[url] ~= true and addedtolist[url] ~= true) and string.match(url, "^https?://[^/]*fotolog%.com") and string.match(url, item_value) and not (string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/twitter_register") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/login/%?redirect=") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/lang_switch") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/friend_add") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/share_overlay") or string.match(url, "^https?://[^/]*fotolog%.com[^/]*/act/report_overlay") or string.match(url, "^https?://[^/]*fotolog%.com/account/photos/edit") or string.match(url, " ") or string.match(url, "%%20")) then
      if string.match(url, "&amp;") then
        table.insert(urls, { url=string.gsub(url, "&amp;", "&") })
        addedtolist[url] = true
        addedtolist[string.gsub(url, "&amp;", "&")] = true
      else
        table.insert(urls, { url=url })
        addedtolist[url] = true
      end
    end
  end

  local function checknewurl(newurl)
    if string.match(newurl, "^https?://") then
      check(newurl)
    elseif string.match(newurl, "^//") then
      check("http:"..newurl)
    elseif string.match(newurl, "^/") then
      check(string.match(url, "^(https?://[^/]+)")..newurl)
    end
  end

  local function checknewshorturl(newurl)
    if not (string.match(newurl, "^https?://") or string.match(newurl, "^/") or string.match(newurl, "^javascript:") or string.match(newurl, "^mailto:") or string.match(newurl, "^%${")) then
      check(string.match(url, "^(https?://.+/)")..newurl)
    end
  end

  if string.match(url, "^https?://sp[0-9a-zA-Z]*%.fotolog%.com") and string.match(url, "_[a-z]%.?[0-9a-zA-Z]*$") then
    check(string.gsub(url, "_[a-z](%.?[a-zA-Z]*)$", "_f%1"))
    check(string.gsub(url, "_[a-z](%.?[a-zA-Z]*)$", "_m%1"))
    check(string.gsub(url, "_[a-z](%.?[a-zA-Z]*)$", "_t%1"))
  end
  
  if item_type == 'profile' and string.match(url, "^https?://[^/]*fotolog%.com") and not string.match(url, "^https?://sp[A-Za-z0-9]*%.fotolog%.com") then
    html = read_file(file)
    if profilepic == nil then
      profilepic = string.match(html, '([0-9]+)_t%.?[0-9a-zA-Z]*"%s+alt="Avatar%s+'.. item_value ..'"')
    end
    for newurl in string.gmatch(html, '([^"]+)') do
      checknewurl(newurl)
    end
    for newurl in string.gmatch(html, "([^']+)") do
      checknewurl(newurl)
    end
    for newurl in string.gmatch(html, ">([^<]+)") do
      checknewurl(newurl)
    end
    for newurl in string.gmatch(html, "href='([^']+)'") do
      checknewshorturl(newurl)
    end
    for newurl in string.gmatch(html, 'href="([^"]+)"') do
      checknewshorturl(newurl)
    end
    if string.match(html, "Sorry,%s+Fotolog%s+is%s+over%s+capacity%.") or string.match(html, "Please%s+try%s+again%s+later,%s+in%s+the%s+meantime%s+why%s+don't%s+you%s+go%s+out%s+and%s+take%s+some%s+pictures%s*%?") or string.match(html, "erreur%-500") or string.match(html, "error_box") then
      io.stdout:write("Fotolog is overloaded! ABORTING.\n")
      io.stdout:flush()
      abortgrab = true
    end
  end

  return urls
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()

  if downloaded[url["url"]] == true then
    return wget.actions.EXIT
  end

  if status_code ~= 200 and status_code ~= 404 and url["url"] == "http://www.fotolog.com/"..item_value.."/" then
    return wget.actions.ABORT
  end

  if abortgrab == true then
    return wget.actions.ABORT
  end

  if string.match(url["url"], "%%20https?://[^/]*fotolog%.com[^/]*/") or string.match(url["url"], "%s+https?://[^/]*fotolog%.com[^/]*/") then
    return wget.actions.EXIT
  end

  if (status_code >= 200 and status_code <= 399) then
    if string.match(url.url, "https://") then
      local newurl = string.gsub(url.url, "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url.url] = true
    end
  end
  
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404) or
    status_code == 0 then
    io.stdout:write("Server returned "..http_stat.statcode.." ("..err.."). Sleeping.\n")
    io.stdout:flush()
    os.execute("sleep 1")
    tries = tries + 1
    if profilepic ~= nil then
      if string.match(url["url"], profilepic) then
        return wget.actions.EXIT
      end
    end
    if tries >= 5 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      tries = 0
      if string.match(url["url"], "^https?://[^/]*fotolog%.com") then
        return wget.actions.ABORT
      else
        return wget.actions.EXIT
      end
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  local sleep_time = 0

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end

wget.callbacks.finish = function(start_time, end_time, wall_time, numurls, total_downloaded_bytes, total_download_time)
  local usersfile = io.open(item_dir..'/'..warc_file_base..'_data.txt', 'w')
  for url, _ in pairs(profiles) do
    usersfile:write(url.."\n")
  end
  usersfile:close()
end

wget.callbacks.before_exit = function(exit_status, exit_status_string)
  if abortgrab == true then
    io.stdout:write("Fotolog is overloaded! ABORTING.\n")
    io.stdout:flush()
    return wget.exits.IO_FAIL
  end
  return exit_status
end