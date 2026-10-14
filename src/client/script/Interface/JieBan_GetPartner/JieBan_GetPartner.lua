-- 寻找结伴


local g_JieBan_GetPartner_Frame_UnifiedPosition
local JieBan_GetPartner_Name = {};
local JieBan_GetPartner_FaceImage = {};
local JieBan_GetPartner_CheckButton = {};
local JieBan_GetPartner_ChatButton = {};
local JieBan_GetPartner_manclient = {};
local  JieBan_GetPartner_Vip = {}
local isJiebanHuiliu = 0;

local g_VIP_Image = {	--VIP图标
	[0] = "set:CommonFrame19 image:VIPLevel_0",
	[1] = "set:CommonFrame19 image:VIPLevel_1",
	[2] = "set:CommonFrame19 image:VIPLevel_2",
	[3] = "set:CommonFrame19 image:VIPLevel_3",
	[4] = "set:CommonFrame19 image:VIPLevel_4",
	[5] = "set:CommonFrame19 image:VIPLevel_5",
	[6] = "set:CommonFrame19 image:VIPLevel_6",
	[7] = "set:CommonFrame19 image:VIPLevel_7",
	[8] = "set:CommonFrame19 image:VIPLevel_8",
	[9] = "set:CommonFrame19 image:VIPLevel_9",
}


function JieBan_GetPartner_PreLoad()
    this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("JIEBANPARTNER_UPDATE");
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function JieBan_GetPartner_OnLoad()
	JieBan_GetPartner_Name[1] = JieBan_GetPartner_Man1Name
	JieBan_GetPartner_Name[2] = JieBan_GetPartner_Man2Name
	JieBan_GetPartner_Name[3] = JieBan_GetPartner_Man3Name
	
	JieBan_GetPartner_FaceImage[1] = JieBan_GetPartner_Man1Head
	JieBan_GetPartner_FaceImage[2] = JieBan_GetPartner_Man2Head
	JieBan_GetPartner_FaceImage[3] = JieBan_GetPartner_Man3Head
	
	JieBan_GetPartner_CheckButton[1] = JieBan_GetPartner_Man1CheckBtn
	JieBan_GetPartner_CheckButton[2] = JieBan_GetPartner_Man2CheckBtn
	JieBan_GetPartner_CheckButton[3] = JieBan_GetPartner_Man3CheckBtn
	
	JieBan_GetPartner_ChatButton[1] = JieBan_GetPartner_Man1ChatBtn
	JieBan_GetPartner_ChatButton[2] = JieBan_GetPartner_Man2ChatBtn
	JieBan_GetPartner_ChatButton[3] = JieBan_GetPartner_Man3ChatBtn
	
	JieBan_GetPartner_manclient[1] = JieBan_GetPartner_Man1Client;
	JieBan_GetPartner_manclient[2] = JieBan_GetPartner_Man2Client;
	JieBan_GetPartner_manclient[3] = JieBan_GetPartner_Man3Client;
	
	JieBan_GetPartner_Vip[1] = JieBan_GetPartner_Man1Name_VIP
	JieBan_GetPartner_Vip[2] = JieBan_GetPartner_Man2Name_VIP
	JieBan_GetPartner_Vip[3] = JieBan_GetPartner_Man3Name_VIP
	
    g_JieBan_GetPartner_Frame_UnifiedPosition = JieBan_GetPartner_Frame:GetProperty("UnifiedPosition")

end

function JieBan_GetPartner_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		JieBan_GetPartner_OnClosed()

	elseif (event == "ADJEST_UI_POS" ) then
		JieBan_GetPartner_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JieBan_GetPartner_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319506 and this:IsVisible()) then
		JieBan_GetPartner_OnClosed()
	elseif (event == "JIEBANPARTNER_UPDATE" ) then
		JieBan_GetPartner_Update()
	end
end

function JieBan_GetPartner_Init()
	
end

function JieBan_GetPartner_Update()
	isJiebanHuiliu = DataPool:Lua_GetJiebanHuiliuFlag()
	if isJiebanHuiliu == 1 then
		JieBan_GetPartner_Description_Text:SetText("#{JBHL_190803_77}")
	else
		JieBan_GetPartner_Description_Text:SetText("#{JBHL_190803_217}")
	end
	
	local num = 0
	for i = 0, 2 do
		local name = DataPool:Lua_GetJiebanPartner(i, "Name")
		if name ~= nil and name ~= "" then
			JieBan_GetPartner_manclient[num+1]:Show()
			JieBan_GetPartner_Name[num+1]:SetText("#M"..name)
			local image = DataPool:Lua_GetJiebanPartner(i, "Portrait")
			JieBan_GetPartner_FaceImage[num+1]:SetProperty("Image", image);
			local viplevel = DataPool:Lua_GetJiebanPartner(i, "VipLevel")
			if viplevel >= 0 and viplevel <= 9 then
				JieBan_GetPartner_Vip[num+1]:SetProperty("Image", g_VIP_Image[viplevel]);
			end
			num = num + 1
		end
	end
	if num < 3 then
		for j = num, 2 do
			JieBan_GetPartner_manclient[j+1]:Hide()
		end
	end
	
	if num == 0 then
		JieBan_GetPartner_Text:SetText("#{JBHL_190803_221}")
	else
		JieBan_GetPartner_Text:SetText("")
	end
	PushDebugMessage("#{JBHL_190803_214}")
	JieBan_GetPartner_GoBtn:Hide()
	this:Show()
end

--查看
function JieBan_GetPartner_Check_Click(index)
	local name = DataPool:Lua_GetJiebanPartner(index-1, "Name")
	local zoneworldid = DataPool:GetSelfZoneWorldID()
	if name ~= nil and name ~= "" then
		if( Friend:IsPlayerIsFriend( name, -1 ) == 1 ) then
			DataPool:ShowFriendInfo( name, -1 );
		else
			DataPool:ShowChatInfoByZWId( name, zoneworldid )
		end
	end
end

--设为私聊
function JieBan_GetPartner_Chat_Click(index)
	local name = DataPool:Lua_GetJiebanPartner(index-1, "Name")
	local zoneworldid =  DataPool:GetSelfZoneWorldID()
	if name ~= nil and name ~= "" then
		Talk:ContexMenuTalk( name, zoneworldid )
	end
end

--刷新
function JieBan_GetPartner_Refresh_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FindJiebanPartner" )
		Set_XSCRIPT_ScriptID( 893195 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--前往
function JieBan_GetPartner_Go_Click()
	AutoRunToTargetEx(175,143,2)
	SetAutoRunTargetNPCName("孙八爷")
end

function JieBan_GetPartner_OnClosed()
	this:Hide()
end

function JieBan_GetPartner_On_ResetPos()
    JieBan_GetPartner_Frame:SetProperty("UnifiedPosition", g_JieBan_GetPartner_Frame_UnifiedPosition)
end

function JieBan_GetPartner_Help_Clicked()
	PushEvent("CCSHOP_HELP", 105)
end