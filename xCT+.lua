--[[   ____ _____
__  __/ ___|_   _|_
\ \/ / |     | |_| |_
 >  <| |___  | |_   _|
/_/\_\\____| |_| |_|
World of Warcraft (4.3)

Title: xCT+
Author: Dandruff
Version: 3.0.0 beta
Description:
  xCT+ is an extremely lightwight scrolling combat text addon.  It replaces Blizzard's default
scrolling combat text with something that is more concised and organized.  xCT+ is the continuation
of xCT (by Affli) that has been outdated since WoW 4.0.6.

]]

-- Lua code below.  Do NOT edit below this point!
-- If you didn't listen, then that means you know what you are doing, please continue. :)

local ADDON_NAME, engine = ...
local xCTEvents, xCT, _ = unpack(engine)  -- xCTEvents, xCT, xCTOptions (assigned later)
local s_format  = string.format
local s_lower   = string.lower
local ActiveProfile = nil
local C = xCT.Colors
local L = xCT.Localization
local EnergyTypes = nil
local XCT_BLANK_ICON = "Interface\\Addons\\xCT\\blank"
xCTShared = engine

-- ==============================================================
-- xCT+   The Frames
-- ==============================================================
local F = { }
local FrameMT = {
  __index = function(t, k)
    local fakeFrame = { AddMessage = function(...)
          -- Debug
          xCT.Debug("Attempted to put a message in frame: '"..k.."' which does not exist")
        end,
      }
    t[k] = fakeFrame
    return fakeFrame
  end,
}
setmetatable(F, FrameMT)
local FramesLocked = true

-- ==============================================================
-- xCT+   Load Saved Variables
-- ==============================================================
local frame = CreateFrame"Frame"
frame:RegisterEvent"ADDON_LOADED"
frame:SetScript("OnEvent", function(self, event, addon)
  if addon == ADDON_NAME then
    if not xCTOptions or xCT.DEFAULT_PROFILE.BypassProfileManager then   -- Default Options
      xCTOptions = { Profiles = { }, }
      xCT.CreateProfile(xCT.Player.Name)
    else 
      xCT.ChangeProfile()
    end
    engine[3] = xCTOptions
    xCT.InvokeEvent("OptionsLoaded")
    xCT.Print("is now your default Combat Text handler.")
  end
end)

-- ==============================================================
-- xCT+   On Loaded Variables Handler (Setup)
-- ==============================================================
xCTEvents["OptionsLoaded"] = function()
  ActiveProfile = xCT.ActiveProfile
  
  -- Assign some aliases
  EnergyTypes = ActiveProfile.EnergyTypes
  
  -- Load the Frames
  for FrameName, Frame in pairs(ActiveProfile.Frames) do
    if Frame.Enabled then
      local f = CreateFrame("ScrollingMessageFrame", _, UIParent)
      
      -- Unconfig values
      f:SetClampedToScreen(true)
      f:SetMovable(true)
      f:SetResizable(true)
      f:SetShadowColor(0, 0, 0, 0)
      f:SetTimeVisible(3)
      f:SetSpacing(2)
      f:SetMinResize(64, 64)
      f:SetMaxResize(768, 768)

      -- Config Values
      f:SetFont(Frame.Font.Name, Frame.Font.Size, Frame.Font.Style)
      f:SetClampRectInsets(0, 0, Frame.Font.Size, 0)
      f:SetWidth(Frame.Width)
      f:SetHeight(Frame.Height)
      f:ClearAllPoints() -- Don't use Blizzard's Frame saver
      f:SetPoint(Frame.Point.Relative, Frame.Point.X, Frame.Point.Y)
      f:SetJustifyH(Frame.Justify)
      
      f:SetMaxLines(Frame.Height / Frame.Font.Size)
      
      F[FrameName] = f  -- store the frame
    end
  end
  
  -- Set Secondary Frames
  for FrameName, Frame in pairs(ActiveProfile.Frames) do
    if not Frame.Enabled and Frame.Secondary then      
      F[FrameName] = F[Frame.Secondary]  -- store the frame
    end
  end
  
  if not ActiveProfile.ShowHeadNumbers then  
    -- Move the options up
    local defaultFont, defaultSize = InterfaceOptionsCombatTextPanelTargetEffectsText:GetFont()
    
    -- Show Combat Options Title
    local fsTitle = InterfaceOptionsCombatTextPanel:CreateFontString(nil, "OVERLAY")
    fsTitle:SetTextColor(1.00, 0.82, 0.00, 1.00)
    fsTitle:SetFont(defaultFont, defaultSize + 2)
    fsTitle:SetText("xCT+ Combat Text Options")
    fsTitle:SetPoint("TOPLEFT", 16, -80)
    
    -- Show Version Number
    local fsVersion = InterfaceOptionsCombatTextPanel:CreateFontString(nil, "OVERLAY")
    fsVersion:SetFont(defaultFont, 11)
    fsVersion:SetText("|cff5555FFPowered By:|r \124cffFF0000x\124rCT\124cffFFFFFF+\124r (Version "
      .. GetAddOnMetadata("xCT+", "Version")..")")
    fsVersion:SetPoint("BOTTOMRIGHT", -8, 8)
    
    -- Move the Effects and Floating Options
    InterfaceOptionsCombatTextPanelTargetEffects:ClearAllPoints()
    InterfaceOptionsCombatTextPanelTargetEffects:SetPoint("TOPLEFT", 18, -370)
    InterfaceOptionsCombatTextPanelEnableFCT:ClearAllPoints()
    InterfaceOptionsCombatTextPanelEnableFCT:SetPoint("TOPLEFT", 8, -66)
    
    -- Hide some options
    InterfaceOptionsCombatTextPanelTargetDamage:Hide()
    InterfaceOptionsCombatTextPanelPeriodicDamage:Hide()
    InterfaceOptionsCombatTextPanelPetDamage:Hide()
    InterfaceOptionsCombatTextPanelHealing:Hide()
    InterfaceOptionsCombatTextPanelEnableFCT:Hide()
    InterfaceOptionsCombatTextPanelFCTDropDown:Hide()
    
    -- Disallow these options (head numbers)
    SetCVar("enableCombatText", 1)
    SetCVar("CombatLogPeriodicSpells", 0)
    SetCVar("PetMeleeDamage", 0)
    SetCVar("CombatDamage", 0)
    SetCVar("CombatHealing", 0)
  end
  
  -- Start the Spell Merge Update Frame
  if ActiveProfile.SpellMerge then
    xCT.MergeFrame = CreateFrame"frame"
    xCT.MergeFrame:SetScript("OnUpdate", xCT.MergeUpdate)
  end
  
  xCT.InvokeEvent("FramesLoaded")
end

-- ==============================================================
-- xCT+   Output Formats
-- ==============================================================
xCT.Formats = {
  Healing = function(msg, name)
    if name and COMBAT_TEXT_SHOW_FRIENDLY_NAMES == "1" then
      return name.." +"..msg
    else
      return "+"..msg end
    end,
  HealingCrit = function(msg, name)
    if name and COMBAT_TEXT_SHOW_FRIENDLY_NAMES == "1" then
      return name.." "..ActiveProfile.CritPrefix.."+"..msg..ActiveProfile.CritPostfix
    else
      return ActiveProfile.CritPrefix.."+"..msg..ActiveProfile.CritPostfix end
    end,
  Damage = function(msg)
      return "-"..msg
    end,
  DamageCrit = function(msg)
      return ActiveProfile.CritPrefix.."-"..msg..ActiveProfile.CritPostfix
    end,
  DamageOut = function(amount, crit, icon)
    if crit then
      return s_format("%s%s%s %s", ActiveProfile.CritPrefix, amount, ActiveProfile.CritPostfix, icon)
    else
      return s_format("%s %s", amount, icon) end
    end,
  Icon = function(spellID, pet)
    local name, _, icon = GetSpellInfo(spellID or 0)
    local size = ActiveProfile.IconSize
    if ActiveProfile.ShowOutgoingIcons or ActiveProfile.UseTextIcons then
      if ActiveProfile.UseTextIcons then
        if pet then
          return "["..L.Pet.."]"
        else
          if not name then
            name = L.Swing end
        return "["..name.."]" end
      else
        if pet then
          return " \124T"..PET_ATTACK_TEXTURE..":"..size..":"..size..":0:0:64:64:5:59:5:59\124t"
        else
          if not icon then
            return " \124T"..XCT_BLANK_ICON..":"..size..":"..size..":0:0:64:64:5:59:5:59\124t"
          else
            return " \124T"..icon..":"..size..":"..size..":0:0:64:64:5:59:5:59\124t" end
        end end
      else
        return "" end
    end,
  Resist = function(amount, msg, resisted)
    if resisted then
      if COMBAT_TEXT_SHOW_RESISTANCES == "1" then
        return s_format("-%s (%s %s)", amount, msg, resisted)
      else
        return "-"..amount end
    elseif COMBAT_TEXT_SHOW_RESISTANCES == "1" then
      return msg end
    return ""
    end,
  Energize = function(amount, energy, ...)
    if EnergyTypes[energy] and amount > 0 then
      return s_format("+%s %s", amount, L[energy]) end
    return ""
    end,
  Money = function(money, g, s, c)
    if ActiveProfile.ColorBlind then
      return s_format("%s: %d%s %d%s %d%s", L.MONEY, g, L.GOLD_LETTER, s, L.SILVER_LETTER, c, L.COPPER_LETTER)
    else
      return s_format("%s: %s", L.MONEY, GetCoinTextureString(money)) end
    end,
}
local X = xCT.Formats

-- ==============================================================
-- xCT+   Current Player Information Cache
-- ==============================================================
xCT.Player = {
  Name = GetUnitName("player"),
  Class = select(2, UnitClass("player")),
  Power = select(2, UnitPowerType("player")),
  GUID = UnitGUID("player"),
  Unit = "player",
  GoodSourceFlags = bit.bor( COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_GUARDIAN ),
  IsLowHealth = function(self)
    if UnitHealth(self.Unit) / UnitHealthMax(self.Unit) <= COMBAT_TEXT_LOW_HEALTH_THRESHOLD then
      if not self.lowHealth then
        self.lowHealth = true
        return true end
    else
      self.lowHealth = nil end
      return false
    end,
  IsLowMana = function(self)
      if self.Power == "MANA" then
        if UnitPower(self.Unit) / UnitPowerMax(self.Unit) <= COMBAT_TEXT_LOW_MANA_THRESHOLD then
          if not self.lowMana then
            self.lowMana = true
            return true
          end
          return false
        else
          self.lowMana = nil
        end
      end
      return false
    end,
  SetUnit = function(self)
    if UnitHasVehicleUI("player") then
      self.Unit = "vehicle"
      self.GUID = UnitGUID("vehicle")
      self.Power = select(2, UnitPowerType("vehicle"))
      CombatTextSetActiveUnit("vehicle")
    else
      self.Unit = "player"
      self.GUID = UnitGUID("player")
      self.Power = select(2, UnitPowerType("player"))
      CombatTextSetActiveUnit("player") end
    end,
}

local PlayerMT = {
  __newindex = function(self, index)
    xCT.InvokeEvent("PlayerChanged", self, index)
  end,
}
setmetatable(xCT.Player, PlayerMT)
local Player = xCT.Player

-- ==============================================================
-- xCT+   General Combat Events
-- ==============================================================
local xCTCombatEvents = {
  COMBAT_TEXT_UPDATE = {  -- Sub-Events
    DAMAGE = function(amount)
        F.Damage:AddMessage(X.Damage(amount), unpack(C.Damage))
      end,
    DAMAGE_CRIT = function(amount)
        F.Damage:AddMessage(X.DamageCrit(amount), unpack(C.DamageCrit))
      end,
    SPELL_DAMAGE = function(amount)
        F.Damage:AddMessage(X.Damage(amount), unpack(C.SpellDamage))
      end,
    SPELL_DAMAGE_CRIT = function(amount)
        F.Damage:AddMessage(X.DamageCrit(amount), unpack(C.SpellDamageCrit))
      end,
    HEAL = function(name, amount)
        F.Healing:AddMessage(X.Healing(amount, name), unpack(C.Healing))
      end,
    HEAL_CRIT = function(name, amount)
        F.Healing:AddMessage(X.HealingCrit(amount, name), unpack(C.HealingCrit))
      end,
    PERIODIC_HEAL = function(name, amount)
        if amount >= ActiveProfile.HealThreshold then
          F.Healing:AddMessage(X.HealingCrit(amount, name), unpack(C.HealingCrit)) end
      end,
    SPELL_CAST = function(spell)
        F.Procs:AddMessage(spell, unpack(C.SpellCast))
      end,
    MISS = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.MISS, unpack(C.MissType)) end
      end,
    DODGE = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.DODGE, unpack(C.MissType)) end
      end,
    PARRY = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.PARRY, unpack(C.MissType)) end
      end,
    EVADE = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.EVADE, unpack(C.MissType)) end
      end,
    IMMUNE = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.IMMUNE, unpack(C.MissType)) end
      end,
    DEFLECT = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.DEFLECT, unpack(C.MissType)) end
      end,
    REFLECT = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.REFLECT, unpack(C.MissType)) end
      end,
    SPELL_MISS = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.MISS, unpack(C.MissType)) end
      end,
    SPELL_DODGE = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.DODGE, unpack(C.MissType)) end
      end,
    SPELL_PARRY = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.PARRY, unpack(C.MissType)) end
      end,
    SPELL_EVADE = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.EVADE, unpack(C.MissType)) end
      end,
    SPELL_IMMUNE = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.IMMUNE, unpack(C.MissType)) end
      end,
    SPELL_DEFLECT = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.DEFLECT, unpack(C.MissType)) end
      end,
    SPELL_REFLECT = function()
      if COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
        F.Damage:AddMessage(L.REFLECT, unpack(C.MissType)) end
      end,
    RESIST = function(amount, resisted)
        F.Damage:AddMessage(X.Resist(amount, L.RESIST, resisted), unpack(C.MissType))
      end,
    BLOCK = function(amount, blocked)
        F.Damage:AddMessage(X.Resist(amount, L.BLOCK, blocked), unpack(C.MissType))
      end,
    ABSORB = function(amount, absorbed)
        F.Damage:AddMessage(X.Resist(amount, L.ABSORB, absorbed), unpack(C.MissType))
      end,
    SPELL_RESIST = function(amount, resisted)
        F.Damage:AddMessage(X.Resist(amount, L.RESIST, resisted), unpack(C.MissType))
      end,
    SPELL_BLOCK = function(amount, blocked)
        F.Damage:AddMessage(X.Resist(amount, L.BLOCK, blocked), unpack(C.MissType))
      end,
    SPELL_ABSORB = function(amount, absorbed)
        F.Damage:AddMessage(X.Resist(amount, L.ABSORB, absorbed), unpack(C.MissType))
      end,
    ENERGIZE = function(amount, energy)
      if COMBAT_TEXT_SHOW_ENERGIZE == "1" then
        F.PowerGains:AddMessage(X.Energize(amount, energy), C.PowerBarColor[energy].r, C.PowerBarColor[energy].g, C.PowerBarColor[energy].b) end
      end,
    PERIODIC_ENERGIZE = function(amount, energy)
      if COMBAT_TEXT_SHOW_PERIODIC_ENERGIZE == "1" then
        F.PowerGains:AddMessage(X.Energize(amount, energy), C.PowerBarColor[energy].r, C.PowerBarColor[energy].g, C.PowerBarColor[energy].b) end
      end,
    SPELL_AURA_START = function(spell)
      if COMBAT_TEXT_SHOW_AURAS == "1" then
        F.General:AddMessage("+"..spell,  unpack(C.BuffStart)) end
      end,
    SPELL_AURA_END = function(spell)
      if COMBAT_TEXT_SHOW_AURAS == "1" then
        F.General:AddMessage("-"..spell,  unpack(C.BuffEnd)) end
      end,
    SPELL_AURA_START_HARMFUL = function(spell)
      if COMBAT_TEXT_SHOW_AURAS == "1" then
        F.General:AddMessage("+"..spell,  unpack(C.DebuffStart)) end
      end,
    SPELL_AURA_END_HARMFUL = function(spell)
      if COMBAT_TEXT_SHOW_AURAS == "1" then
        F.General:AddMessage("-"..spell,  unpack(C.DebuffEnd)) end
      end,
    HONOR_GAINED = function(gain)
      local num = tonumber(gain)
      if COMBAT_TEXT_SHOW_HONOR_GAINED == "1" and num and (abs(num) > 1 or floor(num) > 0) then
        F.General:AddMessage(L.HONOR.." +"..floor(num), unpack(C.Honor)) end
      end,
    FACTION = function(name, gain)
      if COMBAT_TEXT_SHOW_REPUTATION == "1" then
        F.General:AddMessage(name.." +"..gain, unpack(C.Reputation)) end
      end,
    SPELL_ACTIVE = function(spell)
      if COMBAT_TEXT_SHOW_REACTIVES == "1" then
        F.General:AddMessage(spell, unpack(C.SpellReactive)) end
      end,
  },
  UNIT_HEALTH = function(unit)
    if COMBAT_TEXT_SHOW_LOW_HEALTH_MANA == "1" and unit == Player.Unit then
      if Player:IsLowHealth() then
        F.General:AddMessage(L.HEALTH_LOW, unpack(C.LowHealth)) end
      end
    end,
  UNIT_MANA = function(unit)
    if COMBAT_TEXT_SHOW_LOW_HEALTH_MANA == "1" and unit == Player.Unit then
      if Player:IsLowMana() then
        F.General:AddMessage(L.MANA_LOW, unpack(C.LowMana)) end
      end
    end,
  PLAYER_REGEN_ENABLED = function()
    if COMBAT_TEXT_SHOW_COMBAT_STATE == "1" then
      F.General:AddMessage(L.LEAVING_COMBAT, unpack(C.LeavingCombat)) end
    end,
  PLAYER_REGEN_DISABLED = function()
    if COMBAT_TEXT_SHOW_COMBAT_STATE == "1" then
      --print("Frames:", F, "Frame(General):", F.General, "Message:", L.ENTERING_COMBAT, "Color:", unpack(C.EnteringCombat))
      F.General:AddMessage(L.ENTERING_COMBAT, unpack(C.EnteringCombat)) end
    end,
  UNIT_ENTERED_VEHICLE = function(unit)
    if unit == "player" then
      Player:SetUnit() end
    end,
  UNIT_EXITING_VEHICLE = function(unit)
    if unit == "player" then
      Player:SetUnit() end
    end,
  PLAYER_ENTERING_WORLD = function(name)
      Player:SetUnit()  -- might fix a bug with disappearing GUIDs
    end,
  UNIT_COMBO_POINTS = function(unit)
    if COMBAT_TEXT_SHOW_COMBO_POINTS == "1" and unit == Player.Unit then
      local color, comboPoints = C.ComboPoint, GetComboPoints(Player.Unit, "target")
      if comboPoints == MAX_COMBO_POINTS then
        color = C.MaxComboPoints end
      F.General:AddMessage(s_format(COMBAT_TEXT_COMBO_POINTS, comboPoints), unpack(color)) end
    end,
  RUNE_POWER_UPDATE = function(runeSlot)
    local usable = select(3, GetRuneCooldown(runeSlot))
    if usable then
      local runeType = GetRuneType(runeSlot)
      if runeType then
        F.General:AddMessage("+"..L.RUNES[runeType], unpack(C.Runes[runeType])) end
      end
    end,
  CHAT_MSG_MONEY = function(msg)
      local gold, silver, copper = tonumber(msg:match(L.GOLD_MATCH)) or 0, tonumber(msg:match(L.SILVER_MATCH)) or 0, tonumber(msg:match(L.COPPER_MATCH)) or 0
      local money = gold * 10000 + silver * 100 + copper
      if money >= ActiveProfile.minmoney then
        F.Loot:AddMessage(X.Money(money, gold, silver, copper), unpack(C.Money))
      end
    end,
  CHAT_MSG_LOOT = function(msg)
  
    end,
}

-- ==============================================================
-- xCT+   Outgoing Combat Events (DMG)
-- ==============================================================
local xCTDamageEvents = {
  SWING_DAMAGE = function(_, pet, _, ...)
    local amount, _, _, _, _, _, critical = select(12, ...)
    local frame = F.Outgoing
    if critical then
      frame = F.Critical end
    if pet then
      frame:AddMessage(X.DamageOut(amount, critical, X.Icon(nil, true)), unpack(C["1"]))
    else
      frame:AddMessage(X.DamageOut(amount, critical, X.Icon(6603)), unpack(C["1"])) end
    end,
  SPELL_PERIODIC_HEAL = function(_, _, ...)
    local spellId, _, _, amount, _, _, critical = select(12, ...)
    if xCT.IsSpellMergeable(spellId) then
      xCT.AddSpellEntry(spellId, amount, C.Healing)
    else
      local color, frame = C.Healing, F.Outgoing
      if critical then
        color = C.HealingCrit
        frame = F.Critical end
      frame:AddMessage(X.DamageOut(amount, critical, X.Icon(spellId)), unpack(color))
    end
  end,
  SPELL_HEAL = function(_, _, ...)
    local spellId, _, _, amount, _, _, critical = select(12, ...)
    if xCT.IsSpellMergeable(spellId) then
      xCT.AddSpellEntry(spellId, amount, C.Healing)
    else
      local color, frame = C.Healing, F.Outgoing
      if critical then
        color = C.HealingCrit
        frame = F.Critical end
      frame:AddMessage(X.DamageOut(amount, critical, X.Icon(spellId)), unpack(color))
    end
  end,
  RANGE_DAMAGE = function(_, _, _, ...)
    local spellId, _, _, amount, _, _, _, _, _, critical = select(12, ...)
    local frame = F.Outgoing
    if critical then
      frame = F.Critical end
    frame:AddMessage(X.DamageOut(amount, critical, X.Icon(spellId)), unpack(C["1"]))
    end,
  SPELL_DAMAGE = function(_, _, _, ...)
    local spellId, _, spellSchool, amount, _, _, _, _, _, critical = select(12, ...)
    local color, frame = C["1"], F.Outgoing
    if ActiveProfile.DamageColors then
        color = C[tostring(spellSchool)] or C["1"] end
    if xCT.IsSpellMergeable(spellId) then
      xCT.AddSpellEntry(spellId, amount, color)
    else  
      if critical then
        frame = F.Critical end
      frame:AddMessage(X.DamageOut(amount, critical, X.Icon(spellId)), unpack(color))
    end
  end,
  SPELL_PERIODIC_DAMAGE = function(_, _, _, ...)
    local spellId, _, spellSchool, amount, _, _, _, _, _, critical = select(12, ...)
    local color, frame = C["1"], F.Outgoing
    if ActiveProfile.DamageColors then
      color = C[tostring(spellSchool)] or C["1"] end
    if xCT.IsSpellMergeable(spellId) then
      xCT.AddSpellEntry(spellId, amount, color)
    else  
      if critical then
        frame = F.Critical end
      frame:AddMessage(X.DamageOut(amount, critical, X.Icon(spellId)), unpack(color))
    end
  end,
  SWING_MISSED = function(_, pet, _, ...)
    local missType = select(12, ...)
    if pet then
      F.Outgoing:AddMessage(X.DamageOut(L[missType], false, X.Icon(nil, true)), unpack(C.MissType))
    else
      F.Outgoing:AddMessage(X.DamageOut(L[missType], false, X.Icon(6603)), unpack(C.MissType)) end
  end,
  SPELL_MISSED = function(_, _, _, ...)
    local spellId, _, _, missType, _ = select(12, ...)
    F.Outgoing:AddMessage(X.DamageOut(L[missType], false, X.Icon(spellId)), unpack(C.MissType))
  end,
  RANGE_MISSED = function(_, _, _, ...)
    local spellId, _, _, missType, _ = select(12, ...)
    F.Outgoing:AddMessage(X.DamageOut(L[missType], false, X.Icon(spellId)), unpack(C.MissType))
  end,
  SPELL_DISPEL = function(_, _, _, ...)
    local target, _, _, id, effect, _, etype = select(12, ...)
    local color = C.DispellDebuff
    if etype == "BUFF" then
      color = C.DispellBuff end
    F.General:AddMessage(L.ACTION_DISPEL..": "..effect..X.Icon(id), unpack(color))
  end,
  SPELL_INTERRUPT = function(_, _, _, ...)
    local target, _, _, id, effect = select(12, ...)
    F.General:AddMessage(L.ACTION_INTERRUPT..": "..effect..X.Icon(id), unpack(C.Interrupt))
  end,
  PARTY_KILL = function(_, _, _, ...)
    local name = select(9, ...)
    local color = C.UnitKilled
    local unitclass = select(2,UnitClass("target"))
    if ActiveProfile.ClassKilled then
      if unitclass and RAID_CLASS_COLORS[unitclass] then
        local classcolor = RAID_CLASS_COLORS[unitclass]
        color = { classcolor.r, classcolor.g, classcolor.b }
      end
    end
    F.General:AddMessage(L.ACTION_KILLED..": "..name, unpack(color))
  end,
}


-- ==============================================================
-- xCT+   Event Handlers
-- ==============================================================
function xCT.CombatText_AddMessage(msg, _, r, g, b)
  F.General:AddMessage(message, r, g, b)
end

function xCT.CombatEventHandler(self, event, ...)
  local handler = xCTCombatEvents[event]
  if handler then
    if type(handler) == "function" then
      handler(...)
      return 
    end
    local subevent = ...
    if subevent and handler[subevent] then
      handler[subevent]( select(2, ...) )
    end
  end
end

function xCT.DamageEventHandler(self, event, ...)
  local timeStamp, eventType, hideCaster, scrGUID, scrName, scrFlags, scrFlags2, dstGUID = select(1, ...)
  local player = (scrGUID == Player.GUID and dstGUID ~= Player.GUID)
  local pet = (scrGUID == UnitGUID("pet") and ActiveProfile.PetDamage)
  local vehicle = (scrFlags == Player.GoodSourceFlags)
  --print("event", eventType,"player", player, "pet", pet, "vehicle", vehicle, "handler", handler, "args", select(9, ...))
  local handler = xCTDamageEvents[eventType]
  if handler and (player or pet or vehicle) then
    handler(player, pet, vehicle, ...)
  end
end


-- ==============================================================
-- xCT+   Event Registration
-- ==============================================================
do
  -- Combat Events
  local combat = CreateFrame"FRAME"
  combat:RegisterEvent"COMBAT_TEXT_UPDATE"
  combat:RegisterEvent"UNIT_HEALTH"
  combat:RegisterEvent"UNIT_MANA"
  combat:RegisterEvent"PLAYER_ENTERING_WORLD"
  combat:RegisterEvent"PLAYER_REGEN_DISABLED"
  combat:RegisterEvent"PLAYER_REGEN_ENABLED"
  combat:RegisterEvent"UNIT_ENTERED_VEHICLE"
  combat:RegisterEvent"UNIT_EXITING_VEHICLE"
  combat:RegisterEvent"UNIT_COMBO_POINTS"
  combat:RegisterEvent"RUNE_POWER_UPDATE"
  combat:RegisterEvent"CHAT_MSG_MONEY"
  combat:SetScript("OnEvent", xCT.CombatEventHandler)

  -- Outgoing Event Handlers
  local damage = CreateFrame"FRAME"
  damage:RegisterEvent"COMBAT_LOG_EVENT_UNFILTERED"
  damage:SetScript("OnEvent", xCT.DamageEventHandler)
    
  -- Turn Off Blizzard's CT
  CombatText:UnregisterAllEvents()
  CombatText:SetScript("OnLoad", nil)
  CombatText:SetScript("OnEvent", nil)
  CombatText:SetScript("OnUpdate", nil)
  Blizzard_CombatText_AddMessage = xCT.CombatText_AddMessage
end



-- ==============================================================
-- xCT+   Configuration Mode
-- ==============================================================
function xCT.StartConfigMode()
  if not InCombatLockdown() then
    for frameName, frame in pairs(F) do
      local FrameOptions = ActiveProfile.Frames[frameName]
      if FrameOptions.Enabled then
        frame.FrameOptions = FrameOptions
        
        frame:SetBackdrop( {
          bgFile    = "Interface/Tooltips/UI-Tooltip-Background",
          edgeFile  = "Interface/Tooltips/UI-Tooltip-Border",
          tile      = false,
          tileSize  = 0,
          edgeSize  = 2,
          insets = {
            left    = 0,
            right   = 0,
            top     = 0,
            bottom  = 0,
          }
        })
        frame:SetBackdropColor(.1, .1, .1, .8)
        frame:SetBackdropBorderColor(.1, .1, .1, .5)
        
        local HEX_COLOR_FORMAT = "\124Cff%2x%2x%2x%s\124r"
        
        -- Look for Secondary Frames
        local secondaries = " ("
        for secondName,secondFrame in pairs(ActiveProfile.Frames) do
          if secondFrame.Secondary == frameName then
            local SECOND_FRAME_STRING = string.format("\124C%2x%2x%2x%2x%s\124r", secondFrame.LabelColor[4]*255, secondFrame.LabelColor[1]*255, secondFrame.LabelColor[2]*255, secondFrame.LabelColor[3]*255,  secondFrame.Label)
            if secondaries ~= " (" then
              secondaries = secondaries.." & "..SECOND_FRAME_STRING
            else
              secondaries = secondaries..SECOND_FRAME_STRING
            end
          end
        end
        secondaries = secondaries..")"
        if secondaries == " ()" then secondaries = "" end
        
        -- Add the Frame's Title
        frame.fsTitle = frame:CreateFontString(nil, "OVERLAY")
        frame.fsTitle:SetFont(ActiveProfile.FontName, ActiveProfile.FontSize, ActiveProfile.FontStyle)
        frame.fsTitle:SetPoint("BOTTOM", frame, "TOP", 0, 0)
        frame.fsTitle:SetText(FrameOptions.Label..secondaries)
        frame.fsTitle:SetTextColor(unpack(FrameOptions.LabelColor))
        
        frame.texBackHighlight = frame:CreateTexture"ARTWORK"
        frame.texBackHighlight:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame.texBackHighlight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -19)
        frame.texBackHighlight:SetHeight(20)
        frame.texBackHighlight:SetTexture(.5, .5, .5)
        frame.texBackHighlight:SetAlpha(.3)

        frame.texResize = frame:CreateTexture"ARTWORK"
        frame.texResize:SetHeight(16)
        frame.texResize:SetWidth(16)
        frame.texResize:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        frame.texResize:SetTexture(.5, .5, .5)
        frame.texResize:SetAlpha(.3)

        frame.titleRegion = frame:CreateTitleRegion()
        frame.titleRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.titleRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.titleRegion:SetHeight(20)
        
        -- font string Position (location)
        frame.fsPosition = frame:CreateFontString(nil, "OVERLAY")
        frame.fsPosition:SetFont(ActiveProfile.FontName, ActiveProfile.FontSize, ActiveProfile.FontStyle)
        frame.fsPosition:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
        frame.fsPosition:SetText("")
        frame.fsPosition:Hide()
        
        -- font string width
        frame.fsWidth = frame:CreateFontString(nil, "OVERLAY")
        frame.fsWidth:SetFont(ActiveProfile.FontName, ActiveProfile.FontSize, ActiveProfile.FontStyle)
        frame.fsWidth:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
        frame.fsWidth:SetText("")
        frame.fsWidth:Hide()
        
        -- font string height
        frame.fsHeight = frame:CreateFontString(nil, "OVERLAY")
        frame.fsHeight:SetFont(ActiveProfile.FontName, ActiveProfile.FontSize, ActiveProfile.FontStyle)
        frame.fsHeight:SetPoint("LEFT", frame, "LEFT", 3, 0)
        frame.fsHeight:SetText("")
        frame.fsHeight:Hide()
        
        local ResX, ResY = GetScreenWidth(), GetScreenHeight()
        local midX, midY = ResX / 2, ResY / 2
        
        frame:SetScript("OnLeave", function(self, ...)
                self:SetScript("OnUpdate", nil)
                self.fsPosition:Hide()
                self.fsWidth:Hide()
                self.fsHeight:Hide()
            end)
        frame:SetScript("OnEnter", function(self, ...)
                self:SetScript("OnUpdate", function(self, ...)
                        self.fsPosition:SetText(math.floor(self:GetLeft() - midX + 1) .. ", " .. math.floor(self:GetTop() - midY + 2))
                        self.fsWidth:SetText(math.floor(self:GetWidth()))
                        self.fsHeight:SetText(math.floor(self:GetHeight()))
                    end)
                self.fsPosition:Show()
                self.fsWidth:Show()
                self.fsHeight:Show()
            end)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartSizing)
        frame:SetScript("OnSizeChanged", function(self)
            self:SetMaxLines(self:GetHeight() / self.FrameOptions.Font.Size)
            self:Clear()
          end)

        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
      end
    end
    FramesLocked = false
  end
end

function xCT.EndConfigMode()
  for frameName, frame in pairs(F) do
    local FrameOptions = ActiveProfile.Frames[frameName]
    
    if FrameOptions.Enabled then
      -- Unregister all the events
      frame:EnableMouse(false)
      frame:SetScript("OnDragStart", nil)
      frame:SetScript("OnDragStop", nil)
      frame:SetScript("OnSizeChanged", nil)
      frame:SetScript("OnLeave", nil)
      frame:SetScript("OnEnter", nil)
      frame:SetScript("OnUpdate", nil)

      -- Create Islands so they are GC'd
      frame:SetBackdrop(nil)
      frame.fsTitle:Hide()
      frame.fsTitle = nil
      frame.texBackHighlight:Hide()
      frame.texBackHighlight = nil
      frame.texResize:Hide()
      frame.texResize = nil
      frame.titleRegion = nil
      frame.fsPosition:Hide()
      frame.fsPosition = nil
      frame.fsWidth:Hide()
      frame.fsWidth = nil
      frame.fsHeight:Hide()
      frame.fsHeight = nil
    
      frame.FrameOptions = nil
    
      -- Save the Frames
      FrameOptions.Width = frame:GetWidth()
      FrameOptions.Height = frame:GetHeight()
      FrameOptions.Point.Relative, _, _, FrameOptions.Point.X, FrameOptions.Point.Y = frame:GetPoint(1)
 
      FramesLocked = true
    end
  end
end

-- ==============================================================
-- xCT+   In-Game Configuration Editor
-- ==============================================================
local function recursiveSetter(currentTable, args, itter)
  if type(currentTable[args[i][args[i+1]]]) == "table" then
    return recursiveSetter(key[args[i]], args, itter+1)
  end
  currentTable[args[i]] = currentTable[args[i][args[i+1]]]
  return true
end

-- ==============================================================
-- xCT+   Spell Merger
-- ==============================================================
local squeue = { }

function xCT.AddSpellEntry(spellid, amount, color)
  if ammount == "Immune" and ActiveProfile.MergeImmunes then
    local immuneid = "i" .. spellid
    if not squeue[immuneid] then
      squeue[immuneid] = {
        t = GetTime(),      -- last update time stamp
        n = 0,              -- count
        c = color,          -- text color
      }
    end
    local entry = squeue[immuneid]
    entry.n = entry.n + 1
  elseif type(amount) == "number" then
    if not squeue[spellid] then
      squeue[spellid] = {
        t = GetTime(),      -- last update time stamp
        a = 0,              -- total amount
        n = 0,              -- count
        c = color,          -- text color
      }
    end
    local entry = squeue[spellid]
    entry.a = entry.a + amount
    entry.n = entry.n + 1
  end
end

local timePast = 0
function xCT.MergeUpdate(self, itime)
  timePast = timePast + itime
  if timePast > 1 then
    timePast = 0
    local currentTime = GetTime()
    for index, entry in pairs(squeue) do
      if entry.n > 0 and currentTime - entry.t > ActiveProfile.MergeTime then
        local immune, spellid = string.match(index, "(%a?)(%d+)")
      
        -- display entry
        if immune == "" then
          -- DamageOut(amount, critical, icon)
          F.Outgoing:AddMessage(X.DamageOut(entry.a, nil, X.Icon(spellid)) .. " x" .. entry.n, unpack(entry.c))
        else
          -- Immune
          F.Outgoing:AddMessage( string.format("%s %s x%d", L["IMMUNE"], X.Icon(spellid), entry.n), unpack(entry.c) )
        end
        
        -- reset entry
        entry.t = currentTime
        entry.a = 0
        entry.n = 0
      end
    end    
    
  end
end

-- ==============================================================
-- xCT+   Slash Commands
-- ==============================================================
SLASH_XCTPLUS1 = "/xct"
SlashCmdList["XCTPLUS"] = function(input)
  --input = s_lower(input)
  
  -- Get the Args
  local args = { }
  for v in input:gmatch("%w+") do
    args[#args+1] = v
  end
  
  -- Unlock the frames (show them) so that you can move them
  if args[1] == "unlock" then
    if FramesLocked then
        xCT.StartConfigMode()
        xCT.InvokeEvent("FramesUnlocked")
    else
        xCT.Print("Frames already unlocked.")
        
    end
  
  -- Hides the frames and saves their position
  elseif args[1] == "lock" then
    if FramesLocked then
        xCT.Print("Frames already locked.")
    else
        xCT.EndConfigMode()
        xCT.InvokeEvent("FramesLocked")
    end
  
  -- Erases ALL profiles and resets the addon back to default. for development only. this WILL BE REMOVED!
  elseif args[1] == "reset" then
    xCTOptions = nil
    ReloadUI()
  
  -- List all the profiles (and mark the one that's active)
  elseif args[1] == "profiles" then
    xCT.Print("User Profiles:")
    local counter = 1
    for profile,_ in pairs(xCTOptions.Profiles) do
      local active = ""
      if profile == xCTOptions._activeProfile then
        active = " (|cffFFFF00active|r)" end
      print(s_format("    [%d] - %s%s", counter, profile, active))
      counter=counter+1
    end
  
  -- Load a profile (syntax: /xct load ProfileName)
  elseif args[1] == "load" then
    if not args[2] then
      xCT.ChangeProfile("Default")
    else
      if xCTOptions.Profiles[args[2]] then
        xCT.ChangeProfile(args[2])
      else
        xCT.Print("'|cff5555FF"..args[2].."|r' is not a profile. Type '/xct profiles' to see a list.")
      end
    end
    
  elseif args[1] == "create" then
    if xCTOptions.Profiles[args[2]] then
      xCT.Print("'|cff5555FF"..args[2].."|r' is already a profile. Type '/xct profiles' to see a list.")
    else
      xCT.CreateProfile(args[2], args[3])
      xCT.Print("Created and loaded new profile.")
    end
    
  elseif args[1] == "set" then

  elseif args[1] == "test" then
    xCT.Print("attempted to start Test Mode.")
      
  else
    xCT.Print("You did not supply a valid commandline, here is what you said: ", unpack(args))
    xCT.Print("|cff888888Position Commands|r")
    print("    Use |cffFF0000/xct|r |cff5555FFunlock|r to move and resize the frames.")
    print("    Use |cffFF0000/xct|r |cff5555FFlock|r to lock the frames.")
    print("    Use |cffFF0000/xct|r |cff5555FFtest|r to toggle Test Mode (|cffFFFF00on|r/|cffFFFF00off|r).")
    print()
    xCT.Print("|cff888888Profile Commands|r")
    print("    Use |cffFF0000/xct|r |cff5555FFprofiles|r to print a list of all the profiles.")
    print("    Use |cffFF0000/xct|r |cff5555FFload|r (|cff5555FFNumber|r or |cff5555FFName|r) to load a profile.")
    print("    Use |cffFF0000/xct|r |cff5555FFcreate|r (|cff5555FFName|r) to create a new profile.")
  end
end