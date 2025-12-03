-- Basic imports(s)/setup
local L = LibStub("AceLocale-3.0"):GetLocale("SalesTools") -- Localization support

local SalesTools = LibStub("AceAddon-3.0"):GetAddon("SalesTools")
local CollectorMenu = SalesTools:NewModule("CollectorMenu", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0")
local StdUi = LibStub("StdUi")

function CollectorMenu:OnEnable()
    -- Run when the module is enabled
    SalesTools:Debug("CollectorMenu:OnEnable")

    -- Our databases/user settings
    self.GlobalSettings = SalesTools.db.global
    self.CharacterSettings = SalesTools.db.char

    -- Write our defaults to the DB if they don't exist
    if (self.GlobalSettings.PrimaryCollectorChar == nil) then
        self.GlobalSettings.PrimaryCollectorChar = "ExampleChar-Illidan"
    end

    if (self.GlobalSettings.RequestInviteMessage == nil) then
        self.GlobalSettings.RequestInviteMessage = "inv"
    end

    -- Register the options relevant to this module
    SalesTools.AddonOptions.CollectorMenu = {
        name = L["CollectorMenu"],
        type = "group",
        args= {
            PrimaryCollectorChar = {
                name = L["CollectorMenu_Primary_Char_Option_Name"],
                desc = "|cffaaaaaa" .. L["CollectorMenu_Primary_Char_Option_Desc"] .. "|r",
                width = "full",
                type = "input",
                set = function(info, val)
                    if val ~= "" then
                        SalesTools.db.global.PrimaryCollectorChar = val
        
                    else
                        SalesTools:Print(L["CollectorMenu_Options_No_Empty"])
                    end
                end,
                get = function(info)
                    return SalesTools.db.global.PrimaryCollectorChar
                end
            },
            RequestInviteMessage = {
                name = L["CollectorMenu_Invite_Request_Option_Name"],
                desc = "|cffaaaaaa" .. L["CollectorMenu_Invite_Request_Option_Desc"] .. "|r",
                width = "full",
                type = "input",
                set = function(info, val)
                    if val ~= "" then
                        SalesTools.db.global.RequestInviteMessage = val
        
                    else
                        SalesTools:Print(L["CollectorMenu_Options_No_Empty"])
                    end
                end,
                get = function(info)
                    return SalesTools.db.global.RequestInviteMessage
                end
            },
        },
    }

    -- Register any command(s) this module uses
    SalesTools.AddonCommands.collect = {
        desc = L["CollectorMenu_Toggle_Command_Desc"],
        action = function()
            if (SalesTools.CollectorMenu) then
                SalesTools.CollectorMenu:Toggle()
            end
        end,
    }

    -- Register our events
    CollectorMenu:RegisterEvent("PLAYER_MONEY", "UpdateGold")
    CollectorMenu:RegisterEvent("TRADE_MONEY_CHANGED", "AcceptTrade")

    -- Default the panel to invisible if the player level is below or equal to 49
    if self.CharacterSettings.CollectorMenuEnabled == nil then
        if (UnitLevel("player") <= 49) then
            self.CharacterSettings.CollectorMenuEnabled = true
        else
            self.CharacterSettings.CollectorMenuEnabled = false
        end

    end

    -- If the panel is enabled, draw it
    if (self.CollectorMenuFrame == nil and self.CharacterSettings.CollectorMenuEnabled == true) then
        CollectorMenu:DrawCollectorWindow()
    end

end

function CollectorMenu:UpdateGold(event, ...)
    -- Event for PLAYER_MONEY
    -- Update the gold display
    SalesTools:Debug("CollectorMenu:UpdateGold")
    
    local currentGold = SalesTools:CommaValue(math.floor(GetMoney() / 100 / 100))
    local capRequired = SalesTools:CommaValue(9999999 - math.floor(GetMoney() / 100 / 100))

    -- If our menu exists update the relevant texts
    if (self.CollectorMenuFrame ~= nil) then
        -- MODIFIED: Use localized format string for Gold label
        self.CollectorMenuFrame.GoldLabel:SetText(string.format(L["CollectorMenu_Gold_Label"], currentGold .. 'g'))
        -- MODIFIED: Use localized format string for Cap Req label
        self.CollectorMenuFrame.GoldCapLabel:SetText(string.format(L["CollectorMenu_Cap_Req_Label"], capRequired .. 'g'))
    end
end

function CollectorMenu:AcceptTrade(event, ...)
    -- Auto accept trade
    SalesTools:Debug("CollectorMenu:AcceptTrade")

    AcceptTrade()
end

function CollectorMenu:DrawCollectorWindow()
    -- Draw our GC Menu/Collectors Window
    SalesTools:Debug("CollectorMenu:DrawCollectorWindow")

    -- LOCAL FIX: Ensure L["TradeLog_Window_Title"] exists before TradeLog.lua tries to use it.
    L["TradeLog_Window_Title"] = L["TradeLog_Window_Title"] or "Trade Log Viewer" 

    if self.CollectorMenuFrame == nil then
        local frame = StdUi:Window(UIParent, 260, 250, L["CollectorMenu"])
        frame:SetPoint('TOP', UIParent, 'TOP', 500, 0)

        frame.closeBtn:Hide()
        frame:SetMovable(true);
        frame:EnableMouse(true);

        -- Invite Current Target Button
        if frame.InviteTargetButton == nil then
            local InviteTargetButton = StdUi:Button(frame, 124, 30, L["CollectorMenu_Invite_Target_Button"])
            StdUi:GlueTop(InviteTargetButton, frame, -64, -30, 'CENTER')
            frame.InviteTargetButton = InviteTargetButton
            frame.InviteTargetButton:SetScript("OnClick", function()
                if GetUnitName("target") ~= nil then
                    C_PartyInfo.InviteUnit(GetUnitName("target", true))
                end
            end)
        end

-- Trade Log Button
if frame.TradeLog == nil then
    local tradelogButton = StdUi:Button(frame, 124, 30, L["CollectorMenu_TradeLog_Button"])
    StdUi:GlueTop(tradelogButton, frame.InviteTargetButton, 0, -30, 'CENTER')
    frame.TradeLog = tradelogButton
    frame.TradeLog:SetScript("OnClick", function()
        if (SalesTools.TradeLog) then
            SalesTools.TradeLog:Toggle()
        end
    end)
end

-- Info Panel Button (Replaces Mass Invite Button)
if frame.InfoPanelButton == nil then
    local InfoPanelButton = StdUi:Button(frame, 124, 30, L["CollectorMenu_InfoPanel_Button"])
    StdUi:GlueTop(InfoPanelButton, frame.TradeLog, 0, -30, 'CENTER')
    frame.InfoPanelButton = InfoPanelButton
    frame.InfoPanelButton:SetScript("OnClick", function()
        -- Changed to execute /sales help command
        SalesTools:ToggleHelpPanel()
    end)
end


    
        -- Target Trade Button
        if frame.TradeTargetButton == nil then
            local TradeTargetButton = StdUi:Button(frame, 124, 30, L["CollectorMenu_Trade_Target_Button"])
            StdUi:GlueTop(TradeTargetButton, frame.InviteTargetButton, 126, 0, 'CENTER')
            frame.TradeTargetButton = TradeTargetButton
            frame.TradeTargetButton:SetScript("OnClick", function()
                if GetUnitName("target") ~= nil then
                    InitiateTrade("target")
                end
            end)

        end

        -- Mail Log Button
        if frame.MailLog == nil then
            local MailLogButton = StdUi:Button(frame, 124, 30, L["CollectorMenu_MailLog_Button"])
            StdUi:GlueTop(MailLogButton, frame.TradeTargetButton, 0, -30, 'CENTER')
            frame.MailLog = MailLogButton
            frame.MailLog:SetScript("OnClick", function()
                if (SalesTools.MailLog) then
                    SalesTools.MailLog:Toggle()
                end
            end)

        end

        -- Gold Log Button
        if frame.GoldLabelLog == nil then
            local goldLogButton = StdUi:Button(frame, 124, 30, L["CollectorMenu_BalanceList_Button"])
            StdUi:GlueTop(goldLogButton, frame.MailLog, 0, -30, 'CENTER')
            frame.GoldLabelLog = goldLogButton
            frame.GoldLabelLog:SetScript("OnClick", function()
                if (SalesTools.BalanceList) then
                    SalesTools.BalanceList:Toggle()
                end
            end)

        end

        -- Invite Request Button (Used as Close Menu button in the provided context)
        if frame.RequestInviteButton == nil then
            local RequestInviteButton = StdUi:Button(frame, 124, 30, L["CollectorMenu_CloseMenu_Button"])
            StdUi:GlueTop(RequestInviteButton, frame.GoldLabelLog, 0, -30, 'CENTER')
            frame.RequestInviteButton = RequestInviteButton
            frame.RequestInviteButton:SetScript("OnClick", function()
                -- Show a tip in chat on how to re-open the Collector Menu
                if SalesTools and SalesTools.Print then
                    SalesTools:Print(L["CollectorMenu_Reopen_Message"] .. " |cffffff00/sales collect|r")
                else
                    print("|cff33ff99[SalesTools]|r " .. L["CollectorMenu_Reopen_Message"] .. " |cffffff00/sales collect|r")
                end
                -- Run the existing toggle via slash command
                if ChatFrame1EditBox then
                    ChatFrame1EditBox:SetText("/sales collect")
                    ChatEdit_SendText(ChatFrame1EditBox, 0)
                end
            end)
        end



        -- Mass Whisper Button
        if frame.MassWhisperButton == nil then
            local MassWhisperButton = StdUi:Button(frame, 124, 30, L["CollectorMenu_MassWhisper_Button"])
            StdUi:GlueTop(MassWhisperButton, frame.InfoPanelButton, 0, -30, 'CENTER')
            frame.MassWhisperButton = MassWhisperButton
            frame.MassWhisperButton:SetScript("OnClick", function()
                SalesTools:ToggleInfoPanel()
end)
        end
    
    
        -- Gold Section
        local goldText = StdUi:Label(frame, L["CollectorMenu_Gold_Info_Title"], 16)
        StdUi:GlueTop(goldText, frame.RequestInviteButton, -63, -40, 'CENTER')
    
        local currentGold = SalesTools:CommaValue(math.floor(GetMoney() / 100 / 100))
        local capRequired = SalesTools:CommaValue(9999999 - math.floor(GetMoney() / 100 / 100))

        -- Label for how much gold the player has
        if frame.GoldLabel == nil then
            -- MODIFIED: Use localized format string for Gold label
            local GoldCopyButton = StdUi:Button(frame, 250, 30, string.format(L["CollectorMenu_Gold_Label"], currentGold .. 'g'))
            StdUi:GlueTop(GoldCopyButton, goldText, 0, -20, 'CENTER')
            frame.GoldLabel = GoldCopyButton
            frame.GoldLabel:SetScript("OnClick", function()
                local gold = math.floor(GetMoney() / 100 / 100)
                SalesTools:Copy(gold, L["CollectorMenu_Copy_Gold_Title"]) -- <--- MODIFIED to use new localized key
            end)
        end
    
        -- Label for the amount of gold needed to cap a character at 9,999,999
        if frame.GoldCapLabel == nil then
            -- MODIFIED: Use localized format string for Cap Req label
            local goldCapButton = StdUi:Button(frame, 250, 30, string.format(L["CollectorMenu_Cap_Req_Label"], capRequired .. 'g'))
            StdUi:GlueTop(goldCapButton, frame.GoldLabel, 0, -30, 'CENTER')
            frame.GoldCapLabel = goldCapButton
            frame.GoldCapLabel:SetScript("OnClick", function()
                local gold = 9999999 - math.floor(GetMoney() / 100 / 100)
                SalesTools:Copy(gold, L["CollectorMenu_Copy_Cap_Title"]) -- <--- MODIFIED to use new localized key
            end)
        end

        self.CollectorMenuFrame = frame

    end


end

function CollectorMenu:Toggle()
    -- Toggle Visibility of the collector window
    SalesTools:Debug("CollectorMenu:Toggle")

    if self.CharacterSettings.CollectorMenuEnabled == true then
        self.CharacterSettings.CollectorMenuEnabled = false
        if (self.CollectorMenuFrame ~= nil) then
            self.CollectorMenuFrame:Hide()
        end

    else
        self.CharacterSettings.CollectorMenuEnabled = true
        if (self.CollectorMenuFrame == nil) then
            CollectorMenu:DrawCollectorWindow()
        else
            self.CollectorMenuFrame:Show()
        end
        

    end

end