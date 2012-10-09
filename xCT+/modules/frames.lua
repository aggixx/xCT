--[[   ____    ______      
      /\  _`\ /\__  _\   __
 __  _\ \ \/\_\/_/\ \/ /_\ \___ 
/\ \/'\\ \ \/_/_ \ \ \/\___  __\
\/>  </ \ \ \L\ \ \ \ \/__/\_\_/
 /\_/\_\ \ \____/  \ \_\  \/_/
 \//\/_/  \/___/    \/_/
 
 [=====================================]
 [  Author: Dandruff @ Whisperwind-US  ]
 [  xCT+ Version 3.x.x                 ]
 [  �2012. All Rights Reserved.        ]
 [====================================]]

-- this file handles updating the frame settings and anything that changes the UI frames themselves
local ADDON_NAME, addon = ...

local LSM = LibStub("LibSharedMedia-3.0");
local ssub, pairs, tostring, math, unpack, print, type = string.sub, pairs, tostring, math, unpack, print, type

-- Shorten my handle
local x = addon.engine

-- store my frames
x.frames = { }

-- Static frame lookup
local frameIndex = {
  [1] = "general",
  [2] = "outgoing",
  [3] = "critical",
  [4] = "damage",
  [5] = "healing",
  [6] = "power",
  [7] = "procs",
  [8] = "loot",
}

-- Static Title Lookup
local frameTitles = {
  ["general"]   = COMBAT_TEXT_LABEL,
  ["outgoing"]  = SCORE_DAMAGE_DONE.." / "..SCORE_HEALING_DONE,
  ["critical"]  = TEXT_MODE_A_STRING_RESULT_CRITICAL:gsub("%(", ""):gsub("%)", ""), -- "(Critical)" --> "Critical"
  ["damage"]    = DAMAGE,
  ["healing"]   = SHOW_COMBAT_HEALING,
  ["power"]     = COMBAT_TEXT_SHOW_ENERGIZE_TEXT,
  ["class"]     = COMBAT_TEXT_SHOW_COMBO_POINTS_TEXT,
  ["procs"]     = COMBAT_TEXT_SHOW_REACTIVES_TEXT,
  ["loot"]      = LOOT,
}

-- =====================================================
-- AddOn:UpdateFrames(
--    specificFrame,  [string] - (Optional) the framename
--  )
--    If you specify a specificFrame then only that
--  frame will be updated, otherwise all the frames will
--  be updated.
-- =====================================================
function x:UpdateFrames(specificFrame)
  for framename, settings in pairs(x.db.profile.frames) do
    if specificFrame and specificFrame == framename or not specificFrame then
      local f = nil

      -- Create the frame (or retrieve it)
      if x.frames[framename] then
        f = x.frames[framename]
      else
        f = CreateFrame("ScrollingMessageFrame", nil, UIParent)
      end
      
      f.frameName = framename
      f.settings = settings
      --TODO: add time visible
      
      -- Set the position
      f:SetSpacing(2)
      f:ClearAllPoints()
      f:SetMovable(true)
      f:SetTimeVisible(3)
      f:SetResizable(true)
      f:SetMinResize(64, 64)
      f:SetMaxResize(768, 768)
      f:SetShadowColor(0, 0, 0, 0)
      f:SetWidth(settings.Width)
      f:SetHeight(settings.Height)
      print("Setting", framename, "lines to", settings.Height / settings.fontSize)
      f:SetMaxLines(settings.Height / settings.fontSize)
      
      f:SetClampedToScreen(true)
      f:SetPoint("CENTER", settings.X, settings.Y)
      f:SetClampRectInsets(0, 0, settings.fontSize, 0)

      -- Insert Direction
      if settings.insertText then
        f:SetInsertMode(settings.insertText)
      end
      
      -- Font Template
      f:SetFont(LSM:Fetch("font", settings.font), settings.fontSize, ssub(settings.fontOutline, 2))

      if settings.fontJustify then
        f:SetJustifyH(settings.fontJustify)
      end
      
      -- scrolling
      if settings.enableScrollable then
        f:SetMaxLines(settings.scrollableLines)
        f:EnableMouseWheel(true)
        f:SetScript("OnMouseWheel", function(self, delta)
            if delta > 0 then
              self:ScrollUp()
            elseif delta < 0 then
              self:ScrollDown()
            end
          end)
      else
        f:EnableMouseWheel(false)
        f:SetScript("OnMouseWheel", nil)
      end

      -- Special Cases
      if framename == "class" then
        f:SetMaxLines(1)
        f:SetFading(false)
      end
      
      x.frames[framename] = f
      
      
      -- Send a Test message
      if specificFrame then
        f:SetScript("OnUpdate", function(self, e)
          if self.frameName == "class" then
            x:AddMessage(self.frameName, "0", self.settings.fontColor or {1,1,0})
          else
            x:AddMessage(self.frameName, self.frameName.." test message", self.settings.fontColor or {1,1,1})
          end
          self:SetScript("OnUpdate", nil)
        end)
      end
      
    end
  end

end

-- =====================================================
-- AddOn:Clear(
--    specificFrame,  [string] - (Optional) the framename
--  )
--    If you specify a specificFrame then only that
--  frame will be cleared of its text, otherwise all
--  the frames will be cleared.
-- =====================================================
function x:Clear(specificFrame)
  if not specificFrame then
    for framename, settings in pairs(x.db.profile.frames) do
      local frame = x.frames[framename]
      frame:Clear()
    end
  else
    local frame = x.frames[specificFrame]
    frame:Clear()
  end
end

-- =====================================================
-- AddOn:AddMessage(
--    framename,  [string] - the framename
--    message,    [string] - the pre-formatted message to be sent
--    colorname,  [string or table] - the name of the color OR a
--                                    table containing the color
--                                    e.g. colorname={1,2,3} --r=1,b=2,g=3
--  )
--    Sends a message to the framename specified.
-- =====================================================
function x:AddMessage(framename, message, colorname)
  local frame = x.frames[framename]
  local frameOptions = x.db.profile.frames[framename]
  
  -- Make sure we have a valid frame
  if not frameOptions then print("xct+ frame name not found:", framename) return end
  
  local secondFrameName = frameIndex[frameOptions.secondaryFrame]
  local secondFrame = x.frames[secondFrameName]
  local secondFrameOptions = x.db.profile.frames[secondFrameName]
  
  if frame then
    -- Load the color
    local r, g, b = 1, 1, 1
    if type(colorname) == "table" then
      r, g, b = unpack(colorname)
    else
      if not x.colors[colorname] then
        print("FRAME:", framename,"  xct+ says there is no color named:", colorname)
      else
        r, g, b = unpack(x.colors[colorname])
      end
    end
    
    -- make sure the frame is enabled
    if frameOptions.enabledFrame then
      if frameOptions.customColor then      -- check for forced color
        r, g, b = unpack(frameOptions.fontColor or {1, 1, 1})
      end
      frame:AddMessage(message, r, g, b)
    elseif secondFrame and secondFrameOptions.enabledFrame then 
      if secondFrameOptions.customColor then      -- check for forced color
        r, g, b = unpack(secondFrameOptions.fontColor or {1, 1, 1})
      end
      secondFrame:AddMessage(message, r, g, b)
    end
  end
end

-- Starts the "config mode" so that you can move the frames
local function StartConfigMode()
  x.configuring = true

  for framename, settings in pairs(x.db.profile.frames) do
    if settings.enabledFrame then
      local f = x.frames[framename]
      f:SetBackdrop( {
         bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = false,
        tileSize = 0,
        edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
                   } )
      f:SetBackdropColor(.1, .1, .1, .8)
      f:SetBackdropBorderColor(.1, .1, .1, .5)
    
      -- Frame Title
      f.title = f:CreateFontString(nil, "OVERLAY")
      f.title:SetPoint("BOTTOM", f, "TOP", 0, 0)
      f.title:SetFont(LSM:Fetch("font", settings.font), settings.fontSize, settings.fontOutline)
      f.title:SetText(frameTitles[framename])
      
      f.t = f:CreateTexture("ARTWORK")
      f.t:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
      f.t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -19)
      f.t:SetHeight(20)
      f.t:SetTexture(.5, .5, .5)
      f.t:SetAlpha(.3)

      f.d = f:CreateTexture("ARTWORK")
      f.d:SetHeight(16)
      f.d:SetWidth(16)
      f.d:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
      f.d:SetTexture(.5, .5, .5)
      f.d:SetAlpha(.3)

      f.tr = f:CreateTitleRegion()
      f.tr:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
      f.tr:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
      f.tr:SetHeight(21)
      
      -- Moving Settings
      f:EnableMouse(true)
      f:RegisterForDrag("LeftButton")
      f:SetScript("OnDragStart", f.StartSizing)
      
      -- TODO: Add option to adjust the number of lines for memory purposes
      
      f:SetScript("OnDragStop", f.StopMovingOrSizing)
      
      -- TODO: Show Alignment Grid
      
      if framename == "class" then
        f.d:Hide()
      end
      
    end
  end
end

local function EndConfigMode()
  x.configuring = false
  
  for framename, settings in pairs(x.db.profile.frames) do
    local f = x.frames[framename]
    
    f:SetBackdrop(nil)
    if f.title then
      f.title:Hide()
      f.title = nil
    end
    if f.t then
      f.t:Hide()
      f.t = nil
    end
    
    if f.d then
      f.d:Hide()
      f.d = nil
    end
    
    f.tr = nil
    
    f:EnableMouse(false)
    
    f:SetScript("OnDragStart", nil)
    f:SetScript("OnDragStop", nil)
    
  end
end

function x.ToggleConfigMode()
  if x.configuring then
    return
  else
    -- Close the Options Dialog if it is Open
    LibStub("AceConfigDialog-3.0"):Close(ADDON_NAME)
    
    -- Thanks Elv :)
    GameTooltip:Hide() --Just in case you're mouseovered something and it closes.
    
    StaticPopup_Show("XCT_PLUS_CONFIGURING")
    
    
    StartConfigMode()
  end
end

function x:SaveAllFrames()
  for framename, settings in pairs(x.db.profile.frames) do
    local frame = x.frames[framename]
  
    local width   = frame:GetWidth()
    local height  = frame:GetHeight()
    settings.Width   = width
    settings.Height  = height
    
    -- Calculate the center of the screen
    local ResX, ResY = GetScreenWidth(), GetScreenHeight()
    local midX, midY = ResX / 2, ResY / 2
    
    -- Calculate the Top/Left of a frame relative to the center
    local left, top = math.floor(frame:GetLeft() - midX + 1), math.floor(frame:GetTop() - midY + 1)
    
    -- Calculate get the center of the screen from the left/top
    settings.X = math.floor(left + (width / 2) + 0.5)
    settings.Y = math.floor(top - (height / 2) + 0.5)
  end
end

local random = math.random
random(time()); random(); random(time())

local damageColorLookup = { [1] = 1, [2] = 2, [3] = 4, [4] = 8, [5] = 16, [6] = 32, [7] = 64, }

local function TestMoreUpdate(self, elapsed)
  if InCombatLockdown() then
    self:SetScript("OnUpdate", nil)
  else
    self.lastUpdate = self.lastUpdate + elapsed
  
    if not self.nextUpdate then
      self.nextUpdate = random(80, 600) / 1000
    end
    
    if self.nextUpdate < self.lastUpdate then
      self.nextUpdate = nil
      self.lastUpdate = 0
      
      if self == x.frames["general"] and random(3) % 3 == 0 then
        if not x.db.profile.frames["outgoing"].enabledFrame then x:Clear("general") return end
        x:AddMessage("general", COMBAT_TEXT_LABEL, {random(255) / 255, random(255) / 255, random(255) / 255})
      elseif self == x.frames["outgoing"] then
        if not x.db.profile.frames["outgoing"].enabledFrame then x:Clear("outgoing") return end
        local message = random(60000)
        if x.db.profile.frames["outgoing"].iconsEnabled then
          local spellID = random(10000)
          message = message .. x:GetSpellTextureFormatted(spellID, x.db.profile.frames["outgoing"].iconsSize)
        end
        x:AddMessage("outgoing", message, x.damagecolor[damageColorLookup[math.random(7)]])
      elseif self == x.frames["critical"] and random(2) % 2 == 0 then
        if not x.db.profile.frames["critical"].enabledFrame then x:Clear("critical") return end
        local message = x.db.profile.frames["critical"].critPrefix..random(80000, 200000)..x.db.profile.frames["critical"].critPostfix
        if x.db.profile.frames["critical"].iconsEnabled then
          local spellID = random(10000)
          message = message .. x:GetSpellTextureFormatted(spellID, x.db.profile.frames["critical"].iconsSize)
        end
        x:AddMessage("critical", message, x.damagecolor[damageColorLookup[math.random(7)]])
      elseif self == x.frames["damage"] and random(2) % 2 == 0 then
        if not x.db.profile.frames["damage"].enabledFrame then x:Clear("damage") return end
        x:AddMessage("damage", "-"..random(100000), {1, random(100) / 255, random(100) / 255})
      elseif self == x.frames["healing"] and random(2) % 2 == 0 then
        if not x.db.profile.frames["healing"].enabledFrame then x:Clear("healing") return end
        if COMBAT_TEXT_SHOW_FRIENDLY_NAMES == "1" then
          x:AddMessage("healing", UnitName("player") .. " +"..random(90000), {.1, ((random(3) + 1) * 63) / 255, .1})
        else
          x:AddMessage("healing", "+"..random(90000), {.1, ((random(3) + 1) * 63) / 255, .1})
        end
      elseif self == x.frames["power"]  and random(4) % 4 == 0 then
        if not x.db.profile.frames["power"].enabledFrame then x:Clear("power") return end
        local _, powerToken, r, g, b = UnitPowerType("player")
        x:AddMessage("power", "+"..random(500).." ".._G[powerToken], { r, g, b })
      elseif self == x.frames["class"] and random(4) % 4 == 0 then
        if not x.db.profile.frames["class"].enabledFrame then x:Clear("class") return end
        if not self.testCombo then
          self.testCombo = 0
        end
        self.testCombo = self.testCombo + 1
        if self.testCombo > 8 then
          self.testCombo = 1
        end
        x:AddMessage("class", tostring(self.testCombo), {1, .82, 0})
      elseif self == x.frames["procs"] and random(4) % 4 == 0 then
        if not x.db.profile.frames["procs"].enabledFrame then x:Clear("procs") return end
        x:AddMessage("procs", ERR_SPELL_COOLDOWN, {1, 1, 0})
      elseif self == x.frames["loot"] and random(3) % 3 == 0 then
        if not x.db.profile.frames["loot"].enabledFrame then x:Clear("loot") return end
        x:AddMessage("loot", MONEY .. ": " .. GetCoinTextureString(random(1000000)), {1, 1, 0}) -- yellow
      end
    end
  end
end

function x.ToggleTestMode()
  if x.configuring then
    return
  else
    if x.testing then
      x.EndTestMode()
    else
      x.testing = true
      
      -- Start the Test more
      for framename, settings in pairs(x.db.profile.frames) do
        local frame = x.frames[framename]
        frame.lastUpdate = 0
        frame:SetScript("OnUpdate", TestMoreUpdate)
      end
      
      -- Test more Popup
      LibStub("AceConfigDialog-3.0"):Close(ADDON_NAME)
      GameTooltip:Hide()
      StaticPopup_Show("XCT_PLUS_TESTMODE")
    end
  end
end

function x.EndTestMode()
  x.testing = false

  -- Stop the Test more
  for framename, settings in pairs(x.db.profile.frames) do
    local frame = x.frames[framename]
    frame:SetScript("OnUpdate", nil)
    frame:Clear()
  end
end

function x.RestoreAllDefaults()
  LibStub("AceConfigDialog-3.0"):Close(ADDON_NAME)
  GameTooltip:Hide()
  StaticPopup_Show("XCT_PLUS_RESET_SETTINGS")
end

-- Popups
StaticPopupDialogs["XCT_PLUS_CONFIGURING"] = {
  text          = "You can now move freely about the cabin.",
  timeout       = 0,
  whileDead     = 1,
  
  button1       = SAVE_CHANGES,
  button2       = CANCEL,
  OnAccept      = function() x:SaveAllFrames(); EndConfigMode(); LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME) end,
  OnCancel      = function() x:UpdateFrames(); EndConfigMode(); LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME) end,
  hideOnEscape  = false,
  
  -- Taint work around
  preferredIndex = 3,
}

StaticPopupDialogs["XCT_PLUS_TESTMODE"] = {
  text          = "xCT+ Test Mode",
  timeout       = 0,
  whileDead     = 1,
  
  button1       = SLASH_STOPWATCH_PARAM_STOP1,
  OnAccept      = function() x.EndTestMode(); LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME) end,
  hideOnEscape  = true,
  
  -- Taint work around
  preferredIndex = 3,
}

StaticPopupDialogs["XCT_PLUS_RESET_SETTINGS"] = {
  text          = "Are your certain you want to erase all your xCT+ settings?",
  timeout       = 0,
  whileDead     = 1,
  
  button1       = "ERASE ALL!!",
  button2       = CANCEL,
  OnAccept      = function() xCTSavedDB = nil; ReloadUI() end,
  OnCancel      = function() LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME) end,
  hideOnEscape  = true,
  
  -- Taint work around
  preferredIndex = 3,
}