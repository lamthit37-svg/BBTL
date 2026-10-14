--许愿界面
local MAX_OBJ_DISTANCE = 3.0;
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_AnniversaryWish_Index = 0;
local objCared = -1;
local g_NpcObjId = -1;

local g_AnniversaryWish_Item = {}
local g_AnniversaryWish_Mark = {}
local g_AnniversaryWish_Reward = {}

local g_AnniversaryWish_DRZ_REWARD = 2021

local g_AnniversaryWish_WishName = {
	"#{HDRZ_180322_196}", "#{HDRZ_180322_194}","#{HDRZ_180322_197}","#{HDRZ_180322_195}"
}
function AnniversaryWish_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OPEN_ZHOUNIANYUAN_WISH",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function AnniversaryWish_OnEvent(event)
	if event == "UI_COMMAND"  and tonumber(arg0) == 89272601 then
        if ( Get_XParam_INT_Count() < 1 ) then
			return
		end
        
		local isShow = Get_XParam_INT(0);
		if isShow == 1 then
        	--objCared = -1;
			--g_NpcObjId = Get_XParam_INT(0);
			--objCared = DataPool : GetNPCIDByServerID(g_NpcObjId);

			--if objCared == -1 then
			--	PushDebugMessage("异常数据，请稍后再试！")
			--	return
			--end

			--AnniversaryWish_BeginCareObject(objCared)
			AnniversaryWish_OnShown()
		else
		 	AnniversaryWish_OnHiden()
		end
	elseif  event == "OPEN_ZHOUNIANYUAN_WISH" then
		AnniversaryWish_OnShown()
   	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			AnniversaryWish_OnHiden()
		end
	elseif( event == "ADJEST_UI_POS" ) then
		AnniversaryWish_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		AnniversaryWish_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function AnniversaryWish_OnLoad()   
	g_AnniversaryWish_Mark[1] = AnniversaryWish_Reward1_Mark
	g_AnniversaryWish_Mark[2] = AnniversaryWish_Reward2_Mark
	g_AnniversaryWish_Mark[3] = AnniversaryWish_Reward3_Mark
	g_AnniversaryWish_Mark[4] = AnniversaryWish_Reward4_Mark
	
	g_AnniversaryWish_Reward[1] = AnniversaryWish_Reward1
	g_AnniversaryWish_Reward[2] = AnniversaryWish_Reward2
	g_AnniversaryWish_Reward[3] = AnniversaryWish_Reward3
	g_AnniversaryWish_Reward[4] = AnniversaryWish_Reward4
	
	g_Frame_UnifiedXPosition	= AnniversaryWish_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= AnniversaryWish_Frame:GetProperty("UnifiedYPosition");
		
end

function AnniversaryWish_OnShown()
	for i = 1, 4 do
		g_AnniversaryWish_Mark[i]:Hide()
		g_AnniversaryWish_Reward[i]:Enable()
	end
	AnniversaryWish_Button:Enable()
	--AnniversaryWish_Button:SetText("#{HDRZ_180322_203}")
	AnniversaryWish_Explain_Text:SetText("#{HDRZ_180322_108}")
	
  	local nMD_DRZ_REWARD = DataPool:GetPlayerMission_DataRound(g_AnniversaryWish_DRZ_REWARD)
	local temp = math.pow(10, 5)
	local ItemIndex = math.mod(math.floor(nMD_DRZ_REWARD/temp), 10)
	if ItemIndex >= 1 and ItemIndex <= 4 then
		g_AnniversaryWish_Mark[ItemIndex]:Show()
		AnniversaryWish_Button:Disable()
		--AnniversaryWish_Button:SetText("#{HDRZ_180322_219}")
		local itemname = g_AnniversaryWish_WishName[ItemIndex]
		local str = ScriptGlobal_Format("#{HDRZ_180322_207}", itemname)
		AnniversaryWish_Explain_Text:SetText(str)
		
		for i = 1, 4 do
			g_AnniversaryWish_Reward[i]:Disable()
		end
	end	
	
	this:Show();
end
--=========================================================
--选择
--=========================================================
function AnniversaryWish_Reward_Clicked(index)
    g_AnniversaryWish_Index = index
	--for i = 1, 4 do
	--	if index == i then
	--		g_AnniversaryWish_Reward[index]:SetCheck(1)
	--	else
	--		g_AnniversaryWish_Reward[index]:SetCheck(0)
	--	end
	--end
end

--=========================================================
--确认
--=========================================================
function AnniversaryWish_Button_Clicked()
		--if g_AnniversaryWish_Index == 0 then
		--	PushDebugMessage("#{HDRZ_180322_216}")
		--	return
		--end
		
        Clear_XSCRIPT()
		    Set_XSCRIPT_Function_Name("EnterForToday")
		    Set_XSCRIPT_ScriptID(892726)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_Parameter(1,1)
		    Set_XSCRIPT_ParamCount(2)
	    Send_XSCRIPT()	
end
--=========================================================
--开始关心NPC
--=========================================================
function AnniversaryWish_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "AnniversaryWish");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "AnniversaryWish")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function AnniversaryWish_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "AnniversaryWish");
		g_Object = -1;
	end
end


function AnniversaryWish_OnHiden()
   -- AnniversaryWish_StopCareObject()
	this:Hide();
end
function AnniversaryWish_ResetPos()
	AnniversaryWish_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	AnniversaryWish_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end



