local g_targetId = -1
local g_params = {-1,-1,-1}

local g_BangHuiShudi2_Frame_UnifiedXPosition = 0
local g_BangHuiShudi2_Frame_UnifiedYPosition = 0

local g_isTimer = {0,0,0}
local g_isOn = 0

local g_isAskTimer = 0

local g_time = {0,0,0}

local g_MonsterInfo = {"#{BHSD_150205_150}","#{BHSD_150205_151}","#{BHSD_150205_152}"}

local g_btntexts = {
	[1] = {text1 = "",
		   text2 = "",
	},
	[2] = {text1 = "",
		   text2 = "",
	},
	[3] = {text1 = "",
		   text2 = "",
	},
}

function BangHuiShudi2_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("ADJEST_UI_POS",false)

	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		
	this:RegisterEvent("UI_COMMAND")

end

function BangHuiShudi2_OnLoad()
	g_btntexts[1].text1 = BangHuiShudi2_ContentFrame1_Info1_text
	g_btntexts[1].text2 = BangHuiShudi2_ContentFrame2_Info1_text
	g_btntexts[2].text1 = BangHuiShudi2_ContentFrame1_Info2_text
	g_btntexts[2].text2 = BangHuiShudi2_ContentFrame2_Info2_text
	g_btntexts[3].text1 = BangHuiShudi2_ContentFrame1_Info3_text
	g_btntexts[3].text2 = BangHuiShudi2_ContentFrame2_Info3_text

	g_BangHuiShudi2_Frame_UnifiedXPosition = BangHuiShudi2_Frame:GetProperty("UnifiedXPosition")
	g_BangHuiShudi2_Frame_UnifiedYPosition = BangHuiShudi2_Frame:GetProperty("UnifiedYPosition")
end

function BangHuiShudi2_ResetPos()
	BangHuiShudi2_Frame : SetProperty("UnifiedXPosition", g_BangHuiShudi2_Frame_UnifiedXPosition);
	BangHuiShudi2_Frame : SetProperty("UnifiedYPosition", g_BangHuiShudi2_Frame_UnifiedYPosition);
end

function BangHuiShudi2_OnEvent(event)
	if( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif( event == "ADJEST_UI_POS" ) then
		BangHuiShudi2_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BangHuiShudi2_ResetPos()
	elseif(event == "UI_COMMAND" ) then
		if arg0 == "20150319" then
			g_targetId = Get_XParam_INT(0)
			ObjCaredID = DataPool : GetNPCIDByServerID(g_targetId);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "BangHuiShudi2");
			end
						
			local guildnames={"","",""}
			for i=1,3 do
				guildnames[i] = Get_XParam_STR(i-1)
				if guildnames[i] == "" then
					guildnames[i] = " "
				end
			end
						
			--BangHuiShudi2_Detailtips_text:SetText(ScriptGlobal_Format("#{BHSD_150205_20}",guildnames[1],guildnames[2],guildnames[3]))
			
			for i=1,3 do
				if Get_XParam_INT(i) ~= -1 then
					g_btntexts[i].text1:SetText(ScriptGlobal_Format("#{BHSD_150205_21}",guildnames[Get_XParam_INT(i)]))
					g_btntexts[i].text2:SetText(g_MonsterInfo[Get_XParam_INT(i)])
				else
					g_btntexts[i].text1:SetText("#{BHSD_150205_105}")
					g_btntexts[i].text2:SetText("#{BHSD_150205_156}")
				end
				
			end
			this:Show()
		end
	end
end
