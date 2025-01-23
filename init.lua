local vote = {}
local voters = {}
local votes = {
  yes = 0,
  no = 0,
  abstain = 0
}
local vote_in_progress = false
local hud_ids = {}
local vote_end_time = 0

local function reset_votes()
  votes.yes = 0 
  votes.no = 0 
  votes.abstain = 0 
  voters = {}
  hud_ids = {}
end

local function update_hud(player)
  local remaining_time = math.max(0, math.floor(vote_end_time - os.time()))
  local hud_text = string.format("Vote status: Yea: %d Nah: %d abstain: %d\ntime left: %d s", votes.yes, votes.no, votes.abstain, remaining_time)
  local hud_id = hud_ids[player:get_player_name()]
  
  if hud_id then
    player:hud_change(hud_id, "text", hud_text)
  else
    hud_id = player:hud_add({
      hud_elem_type = "text",
      position = {x=0.7, y=0.1},
      offset = {x=0, y=0},
      text = hud_text,
      alignment = {x=1, y=0},
      scale = {x=100, y=100},
      number = 0xFFFFFF,
    })
    hud_ids[player:get_player_name()] = hud_id
  end
end

local function update_all_huds()
  if not vote_in_progress then return end
  for _, player in ipairs(minetest.get_connected_players()) do
    update_hud(player)
  end
  minetest.after(1, update_all_huds)
end

vote.new_vote = function(name, def)
  if vote_in_progress then
    minetest.chat_send_player(name, "A vote is already running!")
    return
  end 
  vote_in_progress = true
  vote_end_time = os.time() + def.duration
  minetest.chat_send_all(name .. " " .. def.descrip .. "/vy for yes, /vn for no, /va for abstain.")
  reset_votes()
  for _, player in ipairs(minetest.get_connected_players()) do
    update_hud(player)
  end
  update_all_huds()
  minetest.after(def.duration, function()
    vote_in_progress = false
    local total_votes = votes.yes + votes.no + votes.abstain
    minetest.chat_send_all("Vote is finished. Yes: " .. votes.yes .. " No: " .. votes.no .. " abstain: " .. votes.abstain .. " total: " .. total_votes)
    if votes.yes > votes.no then
      minetest.chat_send_all("Vote has been passed successfully. The sun rises.")
      minetest.set_timeofday(0.3)
    else
      minetest.chat_send_all("No majority was found. Nothing will happen.")
    end
    for _, player in ipairs(minetest.get_connected_players()) do
      local hud_id = hud_ids[player:get_player_name()]
      if hud_id then
        player:hud_remove(hud_id)
        hud_ids[player:get_player_name()] = nil
      end
    end
  end)
end

local function has_voted(name)
  return voters[name] ~= nil
end

minetest.register_chatcommand("vday", {
  description = "Initinate a vote to set day time",
  privs = {interact = true},
  params = "",
  func = function(name, param)
    vote.new_vote(name, {
      descrip = "has started a day vote. ",
      duration = 60,
    })
    votes.yes = votes.yes + 1 
    voters[name] = true
    for _, player in ipairs(minetest.get_connected_players()) do 
      update_hud(player)
    end
  end,
})

minetest.register_on_joinplayer(function(player)
  if vote_in_progress then
    update_hud(player)
  end
end)

minetest.register_chatcommand("vy", {
  description = "Vote with yes while day vote.",
  func = function(name)
    if not vote_in_progress then
      minetest.chat_send_player(name, "There is no vote running right now.")
      return
    end
    if has_voted(name) then
      minetest.chat_send_player(name, "You have already voted.")
      return
    end
    votes.yes = votes.yes + 1 
    voters[name] = true
    minetest.chat_send_player(name, "you voted yes.")
    for _, player in ipairs(minetest.get_connected_players()) do 
      update_hud(player)
    end
  end,
})

minetest.register_chatcommand("vn",{
  description = "Vote with no while day vote.",
  func = function(name)
    if not vote_in_progress then
      minetest.chat_send_player(name, "There is no vote running right now.")
      return
    end
    if has_voted(name) then
      minetest.chat_send_player(name, "you have already voted.")
      return
    end
    votes.no = votes.no + 1
    voters[name] = true
    minetest.chat_send_player(name, "You voted no.")
    for _, player in ipairs(minetest.get_connected_players()) do 
      update_hud(player)
    end
    return
  end,
})

minetest.register_chatcommand("va", {
  description = "Abstain while a day vote.",
  func = function(name)
    if not vote_in_progress then
      minetest.chat_send_player(name, "There is no vote running right now.")
      return
    end
    if has_voted(name) then
      minetest.chat_send_player(name, "You have already voted.")
      return
    end
    votes.abstain = votes.abstain + 1
    voters[name] = true
    minetest.chat_send_player(name, "You abstained.")
    for _, player in ipairs(minetest.get_connected_players()) do 
      update_hud(player)
    end
    return
  end,
})
