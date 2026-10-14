local g_targetId = -1
local g_params = {-1,-1,-1}

local g_BangHuiShudi_Frame_UnifiedXPosition = 0
local g_BangHuiShudi_Frame_UnifiedYPosition = 0

local g_isTimer = {0,0,0}
local g_isOn = 0

local g_isAskTimer = 0

local g_time = {0,0,0}

local g_btntexts = {
	[1] = {text = "",
		   btn = "",
	},
	[2] = {text = "",
		   btn = "",
	},
	[3] = {text = "",
		   btn = "",
	},
}

function BangHuiShudi_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("ADJEST_UI_POS",false)

	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		
	this:RegisterEvent("UI_COMMAND")

end

function BangHuiShudi_OnLoad()
	g_btntexts[1].text = BangHuiShudi_ContentFrame1_Info1_text
	g_btntexts[1].btn = BangHuiShudi_ContentFrame1_Info1_button
	g_btntexts[2].text = BangHuiShudi_ContentFrame1_Info2_text
	g_btntexts[2].btn = BangHuiShudi_ContentFrame1_Info2_button
	g_btntexts[3].text = BangHuiShudi_ContentFrame1_Info3_text
	g_btntexts[3].btn = BangHuiShudi_ContentFrame1_Info3_button

	g_BangHuiShudi_Frame_UnifiedXPosition = BangHuiShudi_Frame:GetProperty("UnifiedXPosition")
	g_BangHuiShudi_Frame_UnifiedYPosition = BangHuiShudi_Frame:GetProperty("UnifiedYPosition")
end

function BangHuiShudi_ResetPos()
	BangHuiShudi_Frame : SetProperty("UnifiedXPosition", g_BangHuiShudi_Frame_UnifiedXPosition);
	BangHuiShudi_Frame : SetProperty("UnifiedYPosition", g_BangHuiShudi_Frame_UnifiedYPosition);
end

function BangHuiShudi_OnEvent(event)
	if( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif( event == "ADJEST_UI_POS" ) then
		BangHuiShudi_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BangHuiShudi_ResetPos()
	elseif(event == "UI_COMMAND" ) then
		if arg0 == "20150204" then
				
			g_targetId = Get_XParam_INT(0)
			ObjCaredID = DataPool : GetNPCIDByServerID(g_targetId);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "BangHuiShudi");
			end
						
			local guildnames={"","",""}
			for i=1,3 do
				guildnames[i] = Get_XParam_STR(i-1)
				if guildnames[i] == "" then
					guildnames[i] = "#{MDJH_130507_92}"
				end
			end
			
						
			
			local isSelected = {0,0,0}
			
			for i=1,3 do
				g_btntexts[i].btn:Show()
				g_params[i] = Get_XParam_INT(i)
				if g_params[i] == -10 then
					g_btntexts[i].text:SetText("#{BHSD_150205_24}")
					g_btntexts[i].btn:Disable()
					g_isTimer[i] = 0
				elseif g_params[i] < 0 then
					g_btntexts[i].text:SetText(ScriptGlobal_Format("#{BHSD_150205_21}",guildnames[0-g_params[i]]))
					g_btntexts[i].btn:Disable()
					g_isTimer[i] = 0
					isSelected[0-g_params[i]] = 1
				elseif g_params[i] > 300 then
					g_btntexts[i].text:SetText(ScriptGlobal_Format("#{BHSD_150205_23}",g_params[i]-300))
					g_btntexts[i].btn:Disable()
					g_isTimer[i] = 0
				else
					g_btntexts[i].text:SetText(ScriptGlobal_Format("#{BHSD_150205_22}",g_params[i]))					
					g_btntexts[i].btn:Enable()
					g_time[i] = g_params[i]
					if g_isTimer[i] == 0 then						
						g_isTimer[i] = 1
					end
					if g_isOn == 0 then
						SetTimer("BangHuiShudi","BangHuiShudi_OnTimerEvent()", 1000)
						g_isOn = 1
					end
				end
			end
			
			for i=1,3 do
				if isSelected[i] == 0 and guildnames[i] ~= "#{MDJH_130507_92}" then
					guildnames[i] = guildnames[i].."#{BHSD_150205_148}"
				end
			end
			BangHuiShudi_Detailtips_text:SetText(ScriptGlobal_Format("#{BHSD_150205_20}",guildnames[1],guildnames[2],guildnames[3]))
			
			if g_isAskTimer == 0 then
				SetTimer("BangHuiShudi","BangHuiShudi_OnAskTimer()", 1000)
				g_isAskTimer = 1
			end
			
			this:Show()
		elseif arg0 == "20150324" then
			if not this:IsVisible() then
				return
			end
				
			g_targetId = Get_XParam_INT(0)
			ObjCaredID = DataPool : GetNPCIDByServerID(g_targetId);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "BangHuiShudi");
			end
						
			local guildnames={"","",""}
			for i=1,3 do
				guildnames[i] = Get_XParam_STR(i-1)
				if guildnames[i] == "" then
					guildnames[i] = "#{MDJH_130507_92}"
				end
			end			
			
			local isSelected = {0,0,0}
			
			for i=1,3 do
				g_btntexts[i].btn:Show()
				g_params[i] = Get_XParam_INT(i)
				if g_params[i] == -10 then
					g_btntexts[i].text:SetText("#{BHSD_150205_24}")
					g_btntexts[i].btn:Disable()
					g_isTimer[i] = 0
				elseif g_params[i] < 0 then
					g_btntexts[i].text:SetText(ScriptGlobal_Format("#{BHSD_150205_21}",guildnames[0-g_params[i]]))
					g_btntexts[i].btn:Disable()
					g_isTimer[i] = 0
					isSelected[0-g_params[i]] = 1
				elseif g_params[i] > 300 then
					g_btntexts[i].text:SetText(ScriptGlobal_Format("#{BHSD_150205_23}",g_params[i]-300))
					g_btntexts[i].btn:Disable()
					g_isTimer[i] = 0
				else
					g_btntexts[i].text:SetText(ScriptGlobal_Format("#{BHSD_150205_22}",g_params[i]))					
					g_btntexts[i].btn:Enable()
					g_time[i] = g_params[i]
					if g_isTimer[i] == 0 then						
						g_isTimer[i] = 1
					end
					if g_isOn == 0 then
						SetTimer("BangHuiShudi","BangHuiShudi_OnTimerEvent()", 1000)
						g_isOn = 1
					end
				end
			end
			
			for i=1,3 do
				if isSelected[i] == 0 and guildnames[i] ~= "#{MDJH_130507_92}" then
					guildnames[i] = guildnames[i].."#{BHSD_150205_148}"
				end
			end
			BangHuiShudi_Detailtips_text:SetText(ScriptGlobal_Format("#{BHSD_150205_20}",guildnames[1],guildnames[2],guildnames[3]))
			
		end
	end
end

function BangHuiShudi_OnClose()
	this:Hide()
	if g_isAskTimer == 1 then
		KillTimer("BangHuiShudi_OnAskTimer()")
		g_isAskTimer = 0
	end
end

function BangHuiShudi_OnTimerEvent()
	local count = 0
	for i=1,3 do
		if g_isTimer[i] == 0 then
			count = count + 1
		end
	end
	if count == 3 then
		KillTimer("BangHuiShudi_OnTimerEvent()")
		g_isOn = 0
		return
	end
	
	
	for i=1,3 do
		if g_isTimer[i] == 1 and g_time[i] > 0 then
			g_time[i] = g_time[i] - 1
			g_btntexts[i].text:SetText(ScriptGlobal_Format("#{BHSD_150205_22}",g_time[i]))			
		elseif g_isTimer[i] == 1 and g_time[i] == 0 then
			g_btntexts[i].text:SetText("#{BHSD_150205_24}")
			g_btntexts[i].btn:Disable()
			g_isTimer[i] = 0
		end
	end
	
end

function BangHuiShudi_OnAskTimer()
	if not this:IsVisible() then
		KillTimer("BangHuiShudi_OnAskTimer()")
		g_isAskTimer = 0
	end
	if g_targetId == -1 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAskManorInfo")
		Set_XSCRIPT_ScriptID(891063) 
		Set_XSCRIPT_Parameter(0,g_targetId);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function BangHuiShudi_OnClick(ClickId)
	if g_targetId == -1 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnSelect")
		Set_XSCRIPT_ScriptID(891063) 
		Set_XSCRIPT_Parameter(0,g_targetId);
		Set_XSCRIPT_Parameter(1,ClickId);
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
