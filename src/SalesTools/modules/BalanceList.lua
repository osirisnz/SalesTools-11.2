-- Basic imports(s)/setup
local L = LibStub("AceLocale-3.0"):GetLocale("SalesTools") -- Localization support
local SalesTools = LibStub("AceAddon-3.0"):GetAddon("SalesTools")
local BalanceList = SalesTools:NewModule("BalanceList", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")
local StdUi = LibStub('StdUi')
local LGBC = LibStub("LibGuildBankComm-1.0")

-- Define the strings required for the combined display
local WARBAND_BALANCE_STRING = L["BalanceList_Viewer_Warband_Balance"] .. ": %s" 
local ACCOUNT_BALANCE_STRING_FORMAT = L["BalanceList_AccountBalance_Format"] -- New key to fix the format error
local NO_ACCESS_TEXT = "No Warband Access" 

function BalanceList:OnEnable()
    -- Run when the module is enabled
    SalesTools:Debug("BalanceList:OnEnable")

    -- Our databases/user settings
    self.CharacterSettings = SalesTools.db.char
    self.GlobalSettings = SalesTools.db.global

    -- Register the module's minimap button
    table.insert(SalesTools.MinimapMenu, { text = L["BalanceList_Toggle"], notCheckable = true, func = function()
        if (SalesTools.BalanceList) then
            SalesTools.BalanceList:Toggle()
        end
    end })

    -- Write our defaults to the DB if they don't exist
    if (self.GlobalSettings.BalanceList == nil) then
        self.GlobalSettings.BalanceList = {}
    end

    -- Register any command(s) this module uses
    SalesTools.AddonCommands.balances = {
        desc = L["BalanceList_Command_Desc"],
        action = function()
            if (SalesTools.BalanceList) then
                SalesTools.BalanceList:Toggle()
            end
        end,
    }

    -- Register our events
    BalanceList:RegisterEvent("PLAYER_MONEY", "UpdateGold")
    BalanceList:RegisterEvent("GUILDBANKFRAME_CLOSED", "UpdateGold")
    BalanceList:RegisterEvent("GUILDBANKFRAME_OPENED", "UpdateGold")
    BalanceList:RegisterEvent("GUILDBANK_UPDATE_MONEY", "UpdateGold")
    BalanceList:RegisterEvent("ACCOUNT_MONEY", "UpdateWarbandGold")
    -- FIX: Register for GUILD_ROSTER_UPDATE to ensure guild name is retrieved correctly on login
    BalanceList:RegisterEvent("GUILD_ROSTER_UPDATE", "UpdateGold") 
    self:UpdateGold()

end

function BalanceList:Toggle()
    -- Toggle the visibility of the Balance List Window
    SalesTools:Debug("BalanceList:Toggle")

    if (self.BalanceFrame == nil) then
        self:DrawWindow()
        self:DrawSearchPane()
        self:DrawSearchResultsTable()
        self:SearchEntries("")
    elseif self.BalanceFrame:IsVisible() then
        self.BalanceFrame:Hide()
    else
        self.BalanceFrame:Show()
        self:SearchEntries("")
    end
end

function BalanceList:SearchEntries(filter)
    -- Very rough search, returns any row with any field containing the user input text
    SalesTools:Debug("BalanceList:SearchEntries")

    local SearchFilter = filter:lower()
    local FilteredResults = {}

    for playerName, CharBalanceInfo in pairs(self.GlobalSettings.BalanceList) do
        -- FIX: Ensure 'lastupdated' is always a number (default to 0 for old data)
        local lastUpdated = CharBalanceInfo["LastUpdated"] or 0
        
        if (playerName and playerName:lower():find(SearchFilter, 1, true)) then
            --if (SalesTools:FormatRawCurrency(CharBalanceInfo["Personal"]) >= 1 or SalesTools:FormatRawCurrency(CharBalanceInfo["Guild"]) >= 1) then
                table.insert(FilteredResults, { 
                    name = playerName, 
                    realm = CharBalanceInfo["Realm"], 
                    balance = CharBalanceInfo["Personal"], 
                    guildname = CharBalanceInfo["GuildName"], 
                    guildmoney = CharBalanceInfo["Guild"], 
                    lastupdated = lastUpdated, -- Use the guaranteed number
                    display_lastupdated = BalanceList:FormatRelativeTime(lastUpdated), -- NEW: Pre-formatted date string
                    -- Removed warbandmoney field as it's now displayed globally
                    deleteTexture = [=[Interface\Buttons\UI-GroupLoot-Pass-Down]=] 
                })

            --end

        end

    end

    BalanceList:ApplyDefaultSort(FilteredResults)

    self.CurrentView = FilteredResults
    self.BalanceFrame.SearchResults:SetData(self.CurrentView, true)

    BalanceList:UpdateStateText()
    BalanceList:UpdateResultsText()
end

function BalanceList:DrawWindow()
    -- Draw our Trade Logs Window
    SalesTools:Debug("BalanceList:DrawWindow")

    local BalanceFrame
    -- Define the desired permanent maximized dimensions and position
    local defaultWidth = 1400
    local defaultHeight = 720
    local defaultPosition = { point = "CENTER", relPoint = "CENTER", relX = 0, relY = 0 }

    -- CRITICAL FIX: Overwrite any saved custom size/position settings to force the default.
    self.CharacterSettings.BalanceFrameSize = { width = defaultWidth, height = defaultHeight }
    self.CharacterSettings.BalanceFramePosition = defaultPosition

    -- Now create the window using the forced settings
    BalanceFrame = StdUi:Window(UIParent, self.CharacterSettings.BalanceFrameSize.width, self.CharacterSettings.BalanceFrameSize.height, L["BalanceList_Window_Title"])
    
    BalanceFrame:SetPoint(self.CharacterSettings.BalanceFramePosition.point,
                self.CharacterSettings.BalanceFramePosition.UIParent,
                self.CharacterSettings.BalanceFramePosition.relPoint,
                self.CharacterSettings.BalanceFramePosition.relX,
                self.CharacterSettings.BalanceFramePosition.relY)
    

    BalanceFrame:SetScript("OnSizeChanged", function(self)
        BalanceList.CharacterSettings.BalanceFrameSize = { width = self:GetWidth(), height = self:GetHeight() } -- Save width/height to config db
    end)

    BalanceFrame:SetScript("OnMouseDown", function(self)
        self:SetFrameLevel(SalesTools:GetNextFrameLevel())
    end)

    BalanceFrame:SetScript('OnDragStop', function(self)
        self:StopMovingOrSizing()

        local point, _, relPoint, xOfs, yOfs = self:GetPoint() -- Get positional info

        BalanceList.CharacterSettings.BalanceFramePosition = { point = point, relPoint = relPoint, relX = xOfs, relY = yOfs } -- Save position to config db
    end)

    StdUi:MakeResizable(BalanceFrame, "BOTTOMRIGHT")
    StdUi:MakeResizable(BalanceFrame, "TOPLEFT")

    -- MODIFIED: Max width set to 1400. SetResizeBounds( MinWidth, MinHeight, MaxWidth, MaxHeight )
    BalanceFrame:SetResizeBounds(850, 250, 1400, 720)
    BalanceFrame:SetFrameLevel(SalesTools:GetNextFrameLevel())

    local IconFrame = StdUi:Frame(BalanceFrame, 32, 32)
    local IconTexture = StdUi:Texture(IconFrame, 32, 32, SalesTools.AddonIcon)
    StdUi:GlueTop(IconTexture, IconFrame, 0, 0, "CENTER")
    StdUi:GlueBottom(IconFrame, BalanceFrame, -10, 10, "RIGHT")

    BalanceFrame.ResultsLabel = StdUi:Label(BalanceFrame, nil, 16)
    StdUi:GlueBottom(BalanceFrame.ResultsLabel, BalanceFrame, 10, 5, "LEFT")

    local BalanceAuditButton = StdUi:Button(BalanceFrame, 128, 20, L["BalanceList_AuditButton"])
    StdUi:GlueBottom(BalanceAuditButton, BalanceFrame, 0, 10, "CENTER")

    BalanceAuditButton:SetScript("OnClick", function()
        if (BalanceList.BalanceAuditFrame == nil) then
            BalanceList:DrawReportWindow()
        else
            BalanceList.BalanceAuditFrame:Show()
        end
        local BalanceAuditString = ""
        local AccountBalance = 0

        for playerName, CharBalanceInfo in pairs(self.GlobalSettings.BalanceList) do
            --if (SalesTools:FormatRawCurrency(CharBalanceInfo["Personal"]) >= 1 or SalesTools:FormatRawCurrency(CharBalanceInfo["Guild"]) >= 1) then

                BalanceAuditString = BalanceAuditString .. playerName .. string.char(9) .. CharBalanceInfo["Realm"] .. string.char(9) .. CharBalanceInfo["Faction"] .. string.char(9) .. SalesTools:FormatRawCurrency(CharBalanceInfo["Personal"])  .. string.char(9) .. CharBalanceInfo["GuildName"] .. string.char(9) .. SalesTools:FormatRawCurrency(CharBalanceInfo["Guild"]).. string.char(10)
    
            --end
    
            
    
        end
        BalanceList.BalanceAuditFrame.EditBox:SetText(BalanceAuditString)

    end)

    self.BalanceFrame = BalanceFrame
end

function BalanceList:DrawReportWindow()
    -- Draw a window with an edit box for our gold audit
    SalesTools:Debug("BalanceList:DrawReportReportWindow")



    local BalanceAuditFrame = StdUi:Window(UIParent, 720, 960, L["BalanceList_Audit_Window_Title"])
    BalanceAuditFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)

    StdUi:MakeResizable(BalanceAuditFrame, "BOTTOMRIGHT")

    BalanceAuditFrame:SetResizeBounds(600, 800, 960, 1280)
    BalanceAuditFrame:SetFrameLevel(SalesTools:GetNextFrameLevel())

    BalanceAuditFrame:SetScript("OnMouseDown", function(self)
        self:SetFrameLevel(SalesTools:GetNextFrameLevel())
    end)

    local EditBox = StdUi:MultiLineBox(BalanceAuditFrame, 550, 550, nil)
    StdUi:GlueAcross(EditBox, BalanceAuditFrame, 10, -50, -10, 50)
    EditBox:SetFocus()

    local CloseAuditFrameButton = StdUi:Button(BalanceAuditFrame, 80, 30, L["BalanceList_Audit_Window_Close_Button"])
    StdUi:GlueBottom(CloseAuditFrameButton, BalanceAuditFrame, 0, 10, 'CENTER')
    CloseAuditFrameButton:SetScript('OnClick', function()
        BalanceList.BalanceAuditFrame:Hide()
    end)

    local IconFrame = StdUi:Frame(BalanceAuditFrame, 32, 32)
    local IconTexture = StdUi:Texture(IconFrame, 32, 32, SalesTools.AddonIcon)
    StdUi:GlueTop(IconTexture, IconFrame, 0, 0, "CENTER")
    StdUi:GlueBottom(IconFrame, BalanceAuditFrame, -10, 10, "RIGHT")

    self.BalanceAuditFrame = BalanceAuditFrame
    self.BalanceAuditFrame.CloseAuditFrameButton = CloseAuditFrameButton
    self.BalanceAuditFrame.EditBox = EditBox
end

function BalanceList:DrawSearchPane()
    -- Draw the search box
    SalesTools:Debug("BalanceList:DrawSearchPane")

    local BalanceFrame = self.BalanceFrame

    local SearchBox = StdUi:Autocomplete(BalanceFrame, 400, 30, "", nil, nil, nil)
    StdUi:ApplyPlaceholder(SearchBox, L["BalanceList_Search_Button"], [=[Interface\Common\UI-Searchbox-Icon]=])
    SearchBox:SetFontSize(16)

    local Search_Button = StdUi:Button(BalanceFrame, 80, 30, L["BalanceList_Search_Button"] )

    -- Calculate current total balance for initial display
    local AccountBalance = 0
    local WarbandBalance = BalanceList:GetWarbandMoney()
    
    for _, CharBalanceInfo in pairs(self.GlobalSettings.BalanceList) do
        AccountBalance = AccountBalance + CharBalanceInfo["Personal"]
    end
    
    local formattedTotalCombined
    local formattedWarbandBalance
    
    local TotalBalanceCombined = AccountBalance
    
    -- Check if WarbandBalance is a number (meaning access was granted)
    if type(WarbandBalance) == 'number' then
        -- Calculate Total Account Balance (Character Sum + Warband)
        TotalBalanceCombined = AccountBalance + WarbandBalance
        
        -- Format the balances
        formattedWarbandBalance = BalanceList:MoneyFormat(WarbandBalance)
        
        -- Format the combined balance
        formattedTotalCombined = BalanceList:MoneyFormat(TotalBalanceCombined)
        
        -- COMBINE GOLD BALANCE AND WARBAND GOLD INTO A SINGLE LABEL
        combinedText = string.format(
            ACCOUNT_BALANCE_STRING_FORMAT .. string.char(10) .. WARBAND_BALANCE_STRING,
            formattedTotalCombined,
            formattedWarbandBalance
        )
    else
        -- WarbandBalance is "No Access", do not add it to total
        
        -- Format the character sum balance
        formattedTotalCombined = BalanceList:MoneyFormat(AccountBalance)
        
        -- Display No Access for Warband
        combinedText = string.format(
            ACCOUNT_BALANCE_STRING_FORMAT .. string.char(10) .. WARBAND_BALANCE_STRING,
            formattedTotalCombined,
            NO_ACCESS_TEXT
        )
    end
    
    -- MODIFIED: Increased label width to 350 for max gold, adjusted height to 40.
    local GoldLabel = StdUi:Label(BalanceFrame, combinedText, 14, nil, 350, 40) 
    
    -- MODIFIED: Right align the text within the label
    GoldLabel:SetJustifyH("RIGHT") 

    StdUi:GlueTop(SearchBox, BalanceFrame, 10, -40, "LEFT")
    StdUi:GlueTop(Search_Button, BalanceFrame, 420, -40, "LEFT")
    
    -- MODIFIED: Adjusted position to glue near the right edge of the frame with 10px padding (-10)
    StdUi:GlueTop(GoldLabel, BalanceFrame, -10, -40, "RIGHT") 

    SearchBox:SetScript("OnEnterPressed", function()
        BalanceList:SearchEntries(SearchBox:GetText())
    end)
    Search_Button:SetScript("OnClick", function()
        BalanceList:SearchEntries(SearchBox:GetText())
    end)

    BalanceFrame.GoldLabel = GoldLabel
    BalanceFrame.SearchBox = SearchBox
    BalanceFrame.Search_Button = Search_Button


end

-- MODIFIED MODULE FUNCTION: Format timestamp into relative time ("x days ago", "x hours ago", etc.)
function BalanceList:FormatRelativeTime(timestamp)
    SalesTools:Debug("BalanceList:FormatRelativeTime", timestamp)
    if not timestamp or type(timestamp) ~= 'number' or timestamp == 0 then return "" end -- ADDED TYPE CHECK AND ZERO CHECK

    local diff = time() - timestamp
    
    -- Check if it's less than 1 minute (less than 60 seconds)
    if diff < 60 then
        return L["BalanceList_Time_JustNow"]
    end

    -- Check if it's less than 1 hour (3600 seconds)
    if diff < 3600 then
        local minutes = math.max(1, math.floor(diff / 60))
        return format(L["BalanceList_Time_MinAgo"], minutes)
    end
    
    -- Check if it's less than 24 hours (86400 seconds)
    if diff < 86400 then
        local hours = math.floor(diff / 3600)
        return format(L["BalanceList_Time_HoursAgo"], hours)
    end
    
    -- Check if it's less than 30 days (2592000 seconds)
    if diff < 2592000 then
        local days = math.floor(diff / 86400)
        return format(L["BalanceList_Time_DaysAgo"], days)
    end
    
    -- Fallback to the date format for older entries
    return date("%d/%m/%Y", timestamp)
end


function BalanceList:DrawSearchResultsTable()
    -- Draw the search results table
    SalesTools:Debug("BalanceList:DrawSearchResultsTable")

    local BalanceFrame = self.BalanceFrame
    
    local cols = {
        {
            name = L["BalanceList_Viewer_Character"],
            width = 150,
            align = "CENTER",
            index = "name",
            format = "string",
            defaultSort = "asc"
        },
        {
            name = L["BalanceList_Viewer_Realm"],
            width = 100,
            align = "CENTER",
            index = "realm",
            format = "string",
            defaultSort = "asc"
        },
        {
            name = L["BalanceList_Viewer_Balance"],
            width = 125,
            align = "CENTER",
            index = "balance",
            format = "money",
        },
        {
            name = L["BalanceList_Viewer_Guild"],
            width = 100,
            align = "CENTER",
            index = "guildname",
            format = "string",
            defaultSort = "asc"
        },
        {
            name = L["BalanceList_Viewer_Guild_Balance"],
            width = 125,
            align = "CENTER",
            index = "guildmoney",
            format = "money",
        },
        -- MODIFIED COLUMN: Set defaultSort to "desc" (newest at top)
        {
            name = L["BalanceList_Viewer_LastUpdated"], -- Localized header
            width = 140,
            align = "CENTER",
            index = "display_lastupdated", -- Use the pre-formatted string
            format = "string",
            defaultSort = "desc", -- Set default sort to descending
            -- Removed custom 'func' as data is now pre-processed in SearchEntries
        },
        {
            name = "",
            width = 16,
            align = "CENTER",
            index = "deleteTexture",
            format = "icon",
            texture = true,
            events = {
                OnClick = function(rowFrame, cellFrame, data, cols, row, realRow, column, table, button, ...)
                    -- Use the stored PlayerName key to delete the data
                    local nameKey = data.name; 
                    self.GlobalSettings.BalanceList[nameKey] = nil
                    BalanceList:RefreshData()
                end,
            },
        },

    }

    BalanceFrame.SearchResults = StdUi:ScrollTable(BalanceFrame, cols, 18, 29)
    BalanceFrame.SearchResults:SetDisplayRows(math.floor(BalanceFrame.SearchResults:GetWidth() / BalanceFrame.SearchResults:GetHeight()), BalanceFrame.SearchResults.rowHeight)
    BalanceFrame.SearchResults:EnableSelection(true)

    BalanceFrame.SearchResults:SetScript("OnSizeChanged", function(self)
        local tableWidth = self:GetWidth();
        local tableHeight = self:GetHeight();

        local total = 0;
        for i = 1, #self.columns do
            total = total + self.columns[i].width;
        end

        for i = 1, #self.columns do
            self.columns[i]:SetWidth((self.columns[i].width / total) * (tableWidth - 30));
        end

        self:SetDisplayRows(math.floor(tableHeight / self.rowHeight), self.rowHeight);
    end)

    StdUi:GlueAcross(BalanceFrame.SearchResults, BalanceFrame, 10, -110, -10, 50)
    BalanceFrame.stateLabel = StdUi:Label(BalanceFrame.SearchResults, L["BalanceList_NoResults"])
    StdUi:GlueTop(BalanceFrame.stateLabel, BalanceFrame.SearchResults, 0, -40, "CENTER")
end

function BalanceList:ApplyDefaultSort(tableToSort)
    -- Apply our default sort settings
    SalesTools:Debug("BalanceList:ApplyDefaultSort")

    if (self.BalanceFrame.SearchResults.head.columns) then
        local isSorted = false

        for k, v in pairs(self.BalanceFrame.SearchResults.head.columns) do
            if (v.arrow:IsVisible()) then
                isSorted = true
            end
        end

        if (not isSorted) then
            -- Default sort changed to LastUpdated, descending (newest at top)
            -- FIX: Safely compare, defaulting missing "lastupdated" to 0.
            return table.sort(tableToSort, function(a, b)
                local a_time = a["lastupdated"] or 0
                local b_time = b["lastupdated"] or 0
                return a_time > b_time
            end)
        end
    end

    return tableToSort
end

function BalanceList:UpdateStateText()
    -- Show a warning if no results were found
    SalesTools:Debug("BalanceList:UpdateStateText")

    if (#self.CurrentView > 0) then
        self.BalanceFrame.stateLabel:Hide()
    else
        self.BalanceFrame.stateLabel:SetText(L["BalanceList_NoResults"])
    end
end

function BalanceList:UpdateResultsText()
    -- Show the number of results in the current query
    SalesTools:Debug("BalanceList:UpdateResultsText")

    if (#self.CurrentView > 0) then
        self.BalanceFrame.ResultsLabel:SetText(string.format(L["BalanceList_CurrentResults"], tostring(#self.CurrentView)))
        self.BalanceFrame.ResultsLabel:Show()
    else
        self.BalanceFrame.ResultsLabel:Hide()
    end
end

function BalanceList:RefreshData()
    -- Refresh the results of the current query
    SalesTools:Debug("BalanceList:RefreshData")

    if (self.BalanceFrame ~= nil) then
        BalanceList:SearchEntries(self.BalanceFrame.SearchBox:GetText())
        local AccountTotalBalance = 0
        local WarbandBalance = BalanceList:GetWarbandMoney()
        
        for _, CharBalanceInfo in pairs(self.GlobalSettings.BalanceList) do
            AccountTotalBalance = AccountTotalBalance + CharBalanceInfo["Personal"]
        end
        
        local formattedTotalCombined
        local formattedWarbandBalance

        local TotalBalanceCombined = AccountTotalBalance
        
        -- Check if WarbandBalance is a number (meaning access was granted/available)
        if type(WarbandBalance) == 'number' then
            -- Calculate Total Account Balance (Character Sum + Warband)
            TotalBalanceCombined = AccountTotalBalance + WarbandBalance
            
            -- Format the balances
            formattedWarbandBalance = BalanceList:MoneyFormat(WarbandBalance)
            
            -- Format the combined balance
            formattedTotalCombined = BalanceList:MoneyFormat(TotalBalanceCombined)

            combinedText = string.format(
                ACCOUNT_BALANCE_STRING_FORMAT .. string.char(10) .. WARBAND_BALANCE_STRING,
                formattedTotalCombined,
                formattedWarbandBalance
            )
        else
            -- WarbandBalance is "No Access" (string), do not add it to total
            
            -- Format the character sum balance
            formattedTotalCombined = BalanceList:MoneyFormat(AccountTotalBalance)
            
            -- Display No Access for Warband
            combinedText = string.format(
                ACCOUNT_BALANCE_STRING_FORMAT .. string.char(10) .. WARBAND_BALANCE_STRING,
                formattedTotalCombined,
                NO_ACCESS_TEXT
            )
        end

        -- Update the label
        self.BalanceFrame.GoldLabel:SetText(combinedText)
    end
end

function BalanceList:GetWarbandMoney()
    -- New function to get Warband Bank gold
    SalesTools:Debug("BalanceList:GetWarbandMoney")
    if C_Bank and Enum and Enum.BankType and Enum.BankType.Account then
        -- C_Bank.FetchDepositedMoney returns the amount in copper or nil if access is denied/unavailable.
        local money = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
        if money ~= nil then
            return money
        else
            return NO_ACCESS_TEXT -- Return a non-number indicator for no access
        end
    end
    return NO_ACCESS_TEXT -- Default to No Access if API C_Bank is unavailable
end

function BalanceList:UpdateWarbandGold(event, ...)
    -- Handler for ACCOUNT_MONEY events
    SalesTools:Debug("BalanceList:UpdateWarbandGold")
    self:RefreshData()
end

function BalanceList:UpdateGold(event, ...)
    -- Handler for PLAYER_MONEY, GUILD_ROSTER_UPDATE, etc. events
    SalesTools:Debug("BalanceList:UpdateGold")

-- Store Warband Gold separately (it's account-wide, not character-specific)
    local wgold_val = BalanceList:GetWarbandMoney()
    self.GlobalSettings.WarbandGold = wgold_val -- Stores the number or the NO_ACCESS_TEXT

    if (UnitFullName("player") ~= nil) then
        local faction, _ = UnitFactionGroup("player")
        local player = SalesTools:GetPlayerFullName()
        local pgold = GetMoney()
        local realm = GetRealmName()
        
        -- FIX: Fetch existing data to prevent temporary overwriting of guild name/gold
        local existingData = self.GlobalSettings.BalanceList[player] or {}
        local ggold = existingData["Guild"] or 0
        local gname_internal = existingData["GuildName"] or "No Guild"
        
        -- Remove brackets for internal processing (since stored name might contain them)
        gname_internal = gname_internal:gsub('<', ''):gsub('>', '')
        
        local currentGuildName, _, _, _, _, _, _, _, _, IsGuildLoaded = GetGuildInfo("player")
        
        -- CHECK MEMBERSHIP & UPDATE
        if (IsInGuild()) then
            -- We are in a guild. If GetGuildInfo provides a valid name, update it.
            if currentGuildName and currentGuildName ~= "" then
                gname_internal = currentGuildName
                
                -- CHECK FUNDS: Only try to get funds if permission is granted (officer/leader)
                if (C_GuildInfo.IsGuildOfficer() or IsGuildLeader()) then
                    if LGBC:GetGuildFunds() ~= nil then
                        ggold = LGBC:GetGuildFunds()
                    end
                end
            end
            -- If currentGuildName is nil/empty (due to delayed loading), we keep the gname_internal
            -- initialized from existingData, preventing the overwrite to "No Guild".
        else
            -- If not in a guild, explicitly reset
            gname_internal = "No Guild"
            ggold = 0
        end
        
        -- Store guild name wrapped in <>, similar to how "No Guild" was previously formatted
        local gname_stored
        if gname_internal ~= "No Guild" then
            gname_stored = "<" .. gname_internal .. ">"
        else
            gname_stored = "<No Guild>"
        end


        self.GlobalSettings.BalanceList[player] = {
            ["Personal"] = pgold,
            ["Faction"] = faction,
            ["Guild"] = ggold,
            ["GuildName"] = gname_stored, -- Use the bracketed name for storage
            ["Realm"] = realm:gsub(' ',''),
            ["LastUpdated"] = time(), -- ADD CURRENT TIMESTAMP
            ["PlayerName"] = player, -- Store the full name for easy lookup
        }

        BalanceList:RefreshData()

    end

end

function BalanceList:MoneyFormat(money, excludeCopper)
    -- Format gold nicely with colours and commas
    SalesTools:Debug("BalanceList:MoneyFormat")
    
    if type(money) ~= 'number' then
        return money;
    end

    money = tonumber(money);
    local goldColor = '|cfffff209';
    local silverColor = '|cff7b7b7a';
    local copperColor = '|cffac7248';

    -- FIX: Calculate rawGold directly for accurate comma separation
    local rawGold = floor(money / 10000);  -- 10000 is COPPER_PER_GOLD
    local silver = floor((money - (rawGold * 10000)) / 100); -- 100 is COPPER_PER_SILVER
    local copper = floor(money % 100); -- 100 is COPPER_PER_SILVER

    local output = '';

    if rawGold > 0 then
        -- FIX: Use rawGold (the whole number of gold) for comma formatting
        output = format('%s%s%s ', goldColor, SalesTools:CommaValue(rawGold), '|rg');
    end

    if rawGold > 0 or silver > 0 then
        output = format('%s%s%02i%s ', output, silverColor, silver, '|rs');
    end

    if not excludeCopper then
        output = format('%s%s%02i%s ', output, copperColor, copper, '|rc');
    end

    return output:trim();
end