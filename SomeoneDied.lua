print("SomeoneDied loaded")

-- Create addon namespace
local addonName, addon = ...

-- Create frame and register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("ADDON_LOADED")

-- Default settings
addon.defaults = {
    classEnabled = {
        WARRIOR = true,
        PALADIN = true,
        HUNTER = true,
        ROGUE = true,
        PRIEST = true,
        DEATHKNIGHT = true,
        SHAMAN = true,
        MAGE = true,
        WARLOCK = true,
        DRUID = true
    }
}

-- Table of class-specific sound files
local classSounds = {
    WARRIOR = "Interface\\AddOns\\SomeoneDied\\sounds\\warrior_death.ogg",
    PALADIN = "Interface\\AddOns\\SomeoneDied\\sounds\\paladin_death.ogg",
    HUNTER = "Interface\\AddOns\\SomeoneDied\\sounds\\hunter_death.ogg",
    ROGUE = "Interface\\AddOns\\SomeoneDied\\sounds\\rogue_death.ogg",
    PRIEST = "Interface\\AddOns\\SomeoneDied\\sounds\\priest_death.ogg",
    DEATHKNIGHT = "Interface\\AddOns\\SomeoneDied\\sounds\\dk_death.ogg",
    SHAMAN = "Interface\\AddOns\\SomeoneDied\\sounds\\shaman_death.ogg",
    MAGE = "Interface\\AddOns\\SomeoneDied\\sounds\\mage_death.ogg",
    WARLOCK = "Interface\\AddOns\\SomeoneDied\\sounds\\warlock_death.ogg",
    DRUID = "Interface\\AddOns\\SomeoneDied\\sounds\\druid_death.ogg"
}

-- Class colors for the menu
local classColors = {
    WARRIOR = "C79C6E",
    PALADIN = "F58CBA",
    HUNTER = "ABD473",
    ROGUE = "FFF569",
    PRIEST = "FFFFFF",
    DEATHKNIGHT = "C41F3B",
    SHAMAN = "0070DE",
    MAGE = "69CCF0",
    WARLOCK = "9482C9",
    DRUID = "FF7D0A"
}

-- Create options panel
local function CreateOptionsPanel()
    -- Create the main options panel
    local panel = CreateFrame("Frame", "SomeoneDiedOptionsPanel", UIParent)
    panel.name = "SomeoneDied"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addonName .. " Options")

    -- Create checkboxes for each class
    local lastCheckbox = title
    local yOffset = -40

    for class, _ in pairs(classSounds) do
        local checkbox = CreateFrame("CheckButton", "SomeoneDied" .. class .. "Check", panel, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 20, yOffset)
        
        -- Set the checkbox label with class color
        local label = _G[checkbox:GetName() .. "Text"]
        label:SetText("|cff" .. classColors[class] .. class .. "|r")
        
        -- Set up the checkbox logic
        checkbox:SetChecked(SomeoneDiedDB.classEnabled[class])
        checkbox:SetScript("OnClick", function(self)
            SomeoneDiedDB.classEnabled[class] = self:GetChecked()
        end)
        
        yOffset = yOffset - 25
    end

    -- Add a "Select All" button
    local selectAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    selectAll:SetText("Select All")
    selectAll:SetWidth(100)
    selectAll:SetPoint("TOPLEFT", 20, yOffset - 10)
    selectAll:SetScript("OnClick", function()
        for class, _ in pairs(classSounds) do
            SomeoneDiedDB.classEnabled[class] = true
            _G["SomeoneDied" .. class .. "Check"]:SetChecked(true)
        end
    end)

    -- Add a "Deselect All" button
    local deselectAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    deselectAll:SetText("Deselect All")
    deselectAll:SetWidth(100)
    deselectAll:SetPoint("LEFT", selectAll, "RIGHT", 10, 0)
    deselectAll:SetScript("OnClick", function()
        for class, _ in pairs(classSounds) do
            SomeoneDiedDB.classEnabled[class] = false
            _G["SomeoneDied" .. class .. "Check"]:SetChecked(false)
        end
    end)

    -- Register the panel
    local function RegisterOptionsPanel(panel)
        -- Add the panel to the Interface Options with correct settings handling
        panel.okay = function(self) end
        panel.cancel = function(self) end
        panel.default = function(self) end
        panel.refresh = function(self) end

        -- Register the panel as an AddOn category using a canvas layout
        local category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
        Settings.RegisterAddOnCategory(category)
    end

    RegisterOptionsPanel(panel)
    return panel
end

-- Event handler function
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- Initialize saved variables
        if not SomeoneDiedDB then
            SomeoneDiedDB = addon.defaults
        end
        
        -- Create the options panel
        CreateOptionsPanel()
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, environmentalType = CombatLogGetCurrentEventInfo()

        -- Check for death events (including environmental deaths)
        if subevent == "UNIT_DIED" or subevent == "PARTY_KILL" or subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "ENVIRONMENTAL_DAMAGE" then
            -- Get information about the unit that died
            local unitType, _, serverID, instanceID, zoneID, id, spawn_uid = strsplit("-", destGUID)

            -- Check if it's a player death and part of your raid/party
            if unitType == "Player" and (UnitInParty(destName) or UnitInRaid(destName)) then
                -- Get the class of the dead player
                local _, class = GetPlayerInfoByGUID(destGUID)

                -- Play the corresponding sound if we have one for this class and it's enabled
                if class and classSounds[class] and SomeoneDiedDB.classEnabled[class] then
                    PlaySoundFile(classSounds[class], "Master")
                end
            end

            -- Check for environmental death (fall damage)
            if subevent == "ENVIRONMENTAL_DAMAGE" and environmentalType == "FALLING" then
                print(destName .. " died from fall damage!")

                -- Optionally, play a specific sound for fall damage
                PlaySoundFile("Interface\\AddOns\\SomeoneDied\\sounds\\fall_death.ogg", "Master")
            end
        end
    end
end)


-- Slash command to open the options panel
SLASH_SomeoneDied1 = "/SomeoneDied"
SlashCmdList["SomeoneDied"] = function()
    local panel = _G["SomeoneDiedOptionsPanel"]
    
    if panel then
        -- Use the new Settings API to open the category
        Settings.OpenToCategory(panel)
    else
        print("SomeoneDied options not found")
    end
end