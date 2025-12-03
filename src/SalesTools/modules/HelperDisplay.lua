-- HelperDisplay.lua modifications

-- Basic imports(s)/setup
local L = LibStub("AceLocale-3.0"):GetLocale("SalesTools") -- Localization support
local SalesTools = LibStub("AceAddon-3.0"):GetAddon("SalesTools")
local HelperDisplay = SalesTools:NewModule("HelperDisplay", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0")

-- ADD A NEW FUNCTION TO UPDATE WARBAND BUTTON STATE
function HelperDisplay:UpdateWarbandButtonState()
    if (self.HelperFrame and self.HelperFrame.WarbandBankButton) then
        local wgold_full = SalesTools.BalanceList and SalesTools.BalanceList:GetWarbandMoney() or 0
        -- Note: wgold_full might be the string "No Warband Access"
        local gold_to_copy = type(wgold_full) == 'number' and math.floor(wgold_full / 100 / 100) or 0
        local button = self.HelperFrame.WarbandBankButton
        local fontString = button:GetFontString()

        if gold_to_copy > 0 then
            -- Warband has gold, set to a default enabled color (e.g., gold/yellow or green)
            fontString:SetTextColor(1.0, 0.82, 0.0) -- Gold/Yellow color
            button:SetText(L["HelperDisplay_Warband_Button_Text"])
            button:Enable()
            -- You could also set a different button texture here if you had one for an 'enabled' state
        else
            -- Warband has zero gold or no access, set to greyed out/disabled
            fontString:SetTextColor(0.5, 0.5, 0.5) -- Grey color
            button:SetText(L["HelperDisplay_Warband_Button_Text"])
            button:Disable()
            -- You could also set a different button texture here if you had one for a 'disabled' state
        end
    end
end

function HelperDisplay:OnEnable()
    -- Run when the module is enabled
    SalesTools:Debug("HelperDisplay:OnEnable")

    -- Our databases/user settings
    self.GlobalSettings = SalesTools.db.global
    self.CharacterSettings = SalesTools.db.char

    -- Register any command(s) this module uses
    SalesTools.AddonCommands.help = {
        desc = L["HelpDisplay_Toggle_Command_Desc"],
        action = function()
            if (SalesTools.HelperDisplay) then
                SalesTools.HelperDisplay:Toggle()
            end
        end,
    }
    SalesTools.AddonCommands.name = {
        desc = L["HelpDisplay_Toggle_NameDisplay_Command_Desc"],
        action = function()
            if (SalesTools.HelperDisplay) then
                SalesTools.HelperDisplay:ToggleName()
            end
        end,
    }
    SalesTools.AddonCommands.gold = {
        desc = L["HelpDisplay_Toggle_GoldDisplay_Command_Desc"],
        action = function()
            if (SalesTools.HelperDisplay) then
                SalesTools.HelperDisplay:ToggleGold()
            end
        end,
    }
    SalesTools.AddonCommands.realm = {
        desc = L["HelpDisplay_Toggle_RealmDisplay_Command_Desc"],
        action = function()
            if (SalesTools.HelperDisplay) then
                SalesTools.HelperDisplay:ToggleRealm()
            end
        end,
    }
    
    -- Hide the helper windows by default if the player level is below or equal to 49
    if self.CharacterSettings.ShowHelperDisplays == nil then
        if (UnitLevel("player") <= 49) then
            self.CharacterSettings.ShowHelperDisplays = true
        else
            self.CharacterSettings.ShowHelperDisplays = false
        end
    end

    if self.CharacterSettings.ShowNameDisplay == nil then
        if (UnitLevel("player") <= 49) then
            self.CharacterSettings.ShowNameDisplay = true
        else
            self.CharacterSettings.ShowNameDisplay = false
        end
    end

    if self.CharacterSettings.ShowRealmDisplay == nil then
        if (UnitLevel("player") <= 49) then
            self.CharacterSettings.ShowRealmDisplay = true
        else
            self.CharacterSettings.ShowRealmDisplay = false
        end
    end

    if self.CharacterSettings.ShowGoldDisplay == nil then
        if (UnitLevel("player") <= 49) then
            self.CharacterSettings.ShowGoldDisplay = true
        else
            self.CharacterSettings.ShowGoldDisplay = false
        end
    end

    -- If enabled, show/draw our helper windows
    if self.CharacterSettings.ShowHelperDisplays then
        if self.HelperFrame == nil then
            HelperDisplay:DrawHelpWindow()
        else
            self.HelperFrame:Show()
            -- Initial update for the warband button state
            self:UpdateWarbandButtonState()
        end
    end

    -- Register our events
    HelperDisplay:RegisterEvent("PLAYER_MONEY", "UpdateGold")
    -- Register an event that might indicate a change in warband money (if BalanceList uses it)
    -- FIX: Replaced obsolete "BANK_BAG_SLOTS_CHANGED" with "PLAYERBANKSLOTS_CHANGED"
    HelperDisplay:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "UpdateWarbandButtonState")
    
end

function HelperDisplay:UpdateGold(event, ...)
    -- Handler for PLAYER_MONEY events
    SalesTools:Debug("HelperDisplay:UpdateGold")

    if (self.HelperFrame ~= nil) then
        local gold = math.floor(GetMoney() / 100 / 100)
        -- MODIFICATION HERE: Change text to use 'g' instead of the localized " Gold" text
        self.HelperFrame.GoldDisplay:SetText(SalesTools:CommaValue(gold) .. "g")

        -- Update the warband button state as player money events might occur around relevant times
        self:UpdateWarbandButtonState()
    end
end

function HelperDisplay:DrawHelpWindow()
    -- Draw our helper frame
    SalesTools:Debug("HelperDisplay:DrawHelpWindow")

    local frame = CreateFrame("FRAME", nil)
    local name, realm = UnitFullName("player")
    -- Get the player's faction (English)
    local englishFaction = UnitFactionGroup("player")

    -- Define Faction Colors (Normalized 0-1)
    local r, g, b = 1, 1, 1 -- Default color is White
    
    if englishFaction == "Alliance" then
        -- Official Alliance Color: R: 0, G: 71, B: 255 (0.0, 0.28, 1.0)
        r, g, b = 0.0, 0.28, 1.0 
    elseif englishFaction == "Horde" then
        -- Official Horde Color: R: 255, G: 26, B: 26 (1.0, 0.1, 0.1)
        r, g, b = 1.0, 0.1, 0.1
    end

    -- 1. Realm Display (Large Font)
    frame.RealmDisplay = frame:CreateFontString("realmDisplay")
    frame.RealmDisplay:SetFontObject("GameFontNormalMed2")
    frame.RealmDisplay:SetTextColor(1, 1, 1, 1) -- Keep realm white for contrast
    frame.RealmDisplay:SetJustifyH("CENTER")
    frame.RealmDisplay:SetJustifyV("MIDDLE")
    -- Display only the Realm
    frame.RealmDisplay:SetText(realm) 
    frame.RealmDisplay:ClearAllPoints()
    frame.RealmDisplay:SetPoint("TOP", UIParent, "TOP", 0, -5) -- Adjusted slightly down for better centering with faction
    frame.RealmDisplay:SetScale(3)


    -- 2. Faction Display (Normal Font, Colored)
    frame.FactionDisplay = frame:CreateFontString("factionDisplay")
    frame.FactionDisplay:SetFontObject("GameFontNormal") -- Standard, smaller font
    -- Set the color based on the faction
    frame.FactionDisplay:SetTextColor(r, g, b, 1) 
    frame.FactionDisplay:SetJustifyH("CENTER")
    frame.FactionDisplay:SetJustifyV("MIDDLE")
    -- Display only the Faction
    frame.FactionDisplay:SetText(englishFaction)
    frame.FactionDisplay:ClearAllPoints()
    -- Position below the RealmDisplay
    frame.FactionDisplay:SetPoint("TOP", frame.RealmDisplay, "TOP", 0, 10) 
    

    -- Button showing the current character's gold
    frame.GoldDisplay = CreateFrame("Button", "GoldCopyButton", frame, "GameMenuButtonTemplate")
    frame.GoldDisplay:SetSize(130, 22) -- New width: 130
    
    -- Positioning for leftmost button (Now relative to the FactionDisplay, which is the lowest element of the header)
    frame.GoldDisplay:SetPoint("TOP", frame.RealmDisplay, "BOTTOM", -135, 0) 

    local gold = math.floor(GetMoney() / 100 / 100)
    -- MODIFICATION HERE: Change text to use 'g' instead of the localized " Gold" text
    frame.GoldDisplay:SetText(SalesTools:CommaValue(gold) .. "g")
    frame.GoldDisplay:SetScript("OnClick", function()
        local gold = math.floor(GetMoney() / 100 / 100)
        SalesTools:Copy(gold, L["HelperDisplay_Copy_Gold_Title"])
    end)
    
    -- NEW BUTTON: Warband Bank Button (Centered)
    frame.WarbandBankButton = CreateFrame("Button", "WarbandBankCopyButton", frame, "GameMenuButtonTemplate")
    frame.WarbandBankButton:SetSize(130, 22) -- New width: 130
    
    -- Position: Centered
    frame.WarbandBankButton:SetPoint("TOP", frame.RealmDisplay, "BOTTOM", 0, 0) 
    
    -- Set Initial Text
    frame.WarbandBankButton:SetText(L["HelperDisplay_Warband_Button_Text"])
    
    -- Set Initial Color (will be updated by UpdateWarbandButtonState)
    frame.WarbandBankButton:GetFontString():SetTextColor(1.0, 0.82, 0.0)
    
    -- Click Handler: Copies the Warband Bank gold amount (in Gold pieces, as an integer)
    frame.WarbandBankButton:SetScript("OnClick", function()
        if SalesTools.BalanceList then
            local wgold_full = SalesTools.BalanceList:GetWarbandMoney() or 0
            -- Handle case where it returns "No Warband Access" string
            local gold_to_copy = type(wgold_full) == 'number' and math.floor(wgold_full / 100 / 100) or 0
            SalesTools:Copy(gold_to_copy, L["HelperDisplay_Copy_Warband_Gold_Title"])
        end
    end)


    -- Button showing the current character's name
    frame.NameCopyButton = CreateFrame("Button", "NameCopyButton", frame, "GameMenuButtonTemplate")
    frame.NameCopyButton:SetSize(130, 22) -- New width: 130
    
    -- Positioning for rightmost button
    frame.NameCopyButton:SetPoint("TOP", frame.RealmDisplay, "BOTTOM", 135, 0) 
    
    frame.NameCopyButton:SetText(name) 
    frame.NameCopyButton:SetScript("OnClick", function()
        SalesTools:Copy(name .. "-" .. realm, L["SalesTools_Popup_Title"])
    end)
    
    self.HelperFrame = frame

    if self.CharacterSettings.ShowNameDisplay == false then
        self.HelperFrame.NameCopyButton:Hide()
    end
    if self.CharacterSettings.ShowRealmDisplay == false then
        self.HelperFrame.RealmDisplay:Hide()
        -- Must hide the FactionDisplay if Realm is hidden to prevent floating text
        self.HelperFrame.FactionDisplay:Hide() 
    end
    if self.CharacterSettings.ShowGoldDisplay == false then
        self.HelperFrame.GoldDisplay:Hide()
        -- HIDE NEW BUTTON ON INITIAL DRAW
        frame.WarbandBankButton:Hide()
    else
        -- Initial update for the warband button state when gold display is enabled
        self:UpdateWarbandButtonState()
    end

end

function HelperDisplay:Toggle()
    -- Toggle visibility of the helper frame
    SalesTools:Debug("HelperDisplay:Toggle")
    
    if self.CharacterSettings.ShowHelperDisplays then
        self.CharacterSettings.ShowHelperDisplays = false
        if self.HelperFrame ~= nil then
            self.HelperFrame:Hide()
        end
    else
        self.CharacterSettings.ShowHelperDisplays = true
        if self.HelperFrame == nil then
            HelperDisplay:DrawHelpWindow()
        else
            self.HelperFrame:Show()
            -- Update warband button state on show
            self:UpdateWarbandButtonState()
        end
    end
end

function HelperDisplay:ToggleName()
    -- Toggle visibility of the name display
    SalesTools:Debug("HelperDisplay:ToggleName")

    if self.CharacterSettings.ShowNameDisplay then
        self.CharacterSettings.ShowNameDisplay = false
        if self.HelperFrame ~= nil then
            self.HelperFrame.NameCopyButton:Hide()
        end
    else
        self.CharacterSettings.ShowNameDisplay = true
        if self.HelperFrame == nil then
            HelperDisplay:DrawHelpWindow()
        else
            self.HelperFrame:Show()
            self.HelperFrame.NameCopyButton:Show()
        end
    end
end

function HelperDisplay:ToggleRealm()
    -- Toggle visibility of the realm display
    SalesTools:Debug("HelperDisplay:ToggleRealm")

    if self.CharacterSettings.ShowRealmDisplay then
        self.CharacterSettings.ShowRealmDisplay = false
        if self.HelperFrame ~= nil then
            self.HelperFrame.RealmDisplay:Hide()
            self.HelperFrame.FactionDisplay:Hide() -- Hide faction when realm is toggled off
        end
    else
        self.CharacterSettings.ShowRealmDisplay = true
        if self.HelperFrame == nil then
            HelperDisplay:DrawHelpWindow()
        else
            self.HelperFrame:Show()
            self.HelperFrame.RealmDisplay:Show()
            self.HelperFrame.FactionDisplay:Show() -- Show faction when realm is toggled on
        end
    end
end

function HelperDisplay:ToggleGold()
    -- Toggle visibility of the gold display
    SalesTools:Debug("HelperDisplay:ToggleGold")

    if self.CharacterSettings.ShowGoldDisplay then
        self.CharacterSettings.ShowGoldDisplay = false
        if self.HelperFrame ~= nil then
            self.HelperFrame.GoldDisplay:Hide()
            -- Hide the Warband Bank button
            self.HelperFrame.WarbandBankButton:Hide()
        end
    else
        self.CharacterSettings.ShowGoldDisplay = true
        if self.HelperFrame == nil then
            HelperDisplay:DrawHelpWindow()
        else
            self.HelperFrame:Show()
            self.HelperFrame.GoldDisplay:Show()
            -- Show the Warband Bank button and update its state
            self.HelperFrame.WarbandBankButton:Show()
            self:UpdateWarbandButtonState()
        end
    end
end