--花灯界面
local MAX_OBJ_DISTANCE = 10.0;
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_FlowerLight_MateName = {};
local g_FlowerLight_MemberName = {};
local g_FlowerLight_ConfirmFlag = {};
local g_FlowerLight_ActionButton = {};
local g_FlowerLight_Mark = {};
local g_FlowerLight_MateNum = {};
local g_FlowerLight_CharIndex = 0;
local g_FlowerLight_DengLevel = 0;
local g_FlowerLight_DengStage = 0;
local objCared = -1;
local g_NpcObjId = -1;
local isRecallHide = -1;

 local g_FlowerLight_Item = { 
	[1] = {id=48151, cnt=1, msg="#{HDRZ_180322_04}", tips1="#{HDRZ_180322_161}", tips2="#{HDRZ_180322_162}"},
	[2] = {id=48152, cnt=2, msg="#{HDRZ_180322_03}", tips1="#{HDRZ_180322_163}", tips2="#{HDRZ_180322_164}"},
	[3] = {id=48153, cnt=3, msg="#{HDRZ_180322_02}", tips1="#{HDRZ_180322_165}", tips2="#{HDRZ_180322_166}"},
	[4] = {id=48154, cnt=4, msg="#{HDRZ_180322_01}", tips1="#{HDRZ_180322_167}", tips2="#{HDRZ_180322_168}"}
}
local g_FlowerLight_DengYouId = 38002202 --万家灯火id

function FlowerLight_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function FlowerLight_OnEvent(event)
	if event == "UI_COMMAND"  and tonumber(arg0) == 89272301 then
        if ( Get_XParam_INT_Count() < 2 ) or ( Get_XParam_STR_Count() < 3) then
			return
		end
        
        objCared = -1;
		g_NpcObjId = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(g_NpcObjId);

		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end

		FlowerLight_BeginCareObject(objCared)
        
        g_FlowerLight_CharIndex = tonumber(Get_XParam_INT(1))
        g_FlowerLight_DengLevel = tonumber(Get_XParam_INT(2))
		g_FlowerLight_DengStage = tonumber(Get_XParam_INT(3))
        g_FlowerLight_MemberName[1] = Get_XParam_STR(0)
        g_FlowerLight_MemberName[2] = Get_XParam_STR(1)
        g_FlowerLight_MemberName[3] = Get_XParam_STR(2)
        
        g_FlowerLight_ConfirmFlag[1] = 0
        g_FlowerLight_ConfirmFlag[2] = 0
        g_FlowerLight_ConfirmFlag[3] = 0

		FlowerLight_OnShown()
	elseif( event == "UI_COMMAND"  and tonumber(arg0) == 89272302 and this:IsVisible() )then
        if ( Get_XParam_INT_Count() < 1 ) then
			return
		end
        local charIndex = tonumber(Get_XParam_INT(0))
        g_FlowerLight_ConfirmFlag[charIndex+1] = 1
		FlowerLight_OnShown()
 	elseif( event == "UI_COMMAND"  and tonumber(arg0) == 89272303 and this:IsVisible() )then
        if ( Get_XParam_INT_Count() < 1 ) then
			return
		end
		local isShow = tonumber(Get_XParam_INT(0))
		if isShow == 1 then
			FlowerLight_Recall_Hiden()  --强制关闭
			return
		end
        g_FlowerLight_ConfirmFlag[1] = 0
        g_FlowerLight_ConfirmFlag[2] = 0
        g_FlowerLight_ConfirmFlag[3] = 0
		FlowerLight_OnShown()
   	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			FlowerLight_OnHiden()
		end
	elseif( event == "ADJEST_UI_POS" ) then
		FlowerLight_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		FlowerLight_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function FlowerLight_OnLoad()
  
    g_FlowerLight_MateName[1] = FlowerLight_MateName1;
    g_FlowerLight_MateName[2] = FlowerLight_MateName2;
    g_FlowerLight_MateName[3] = FlowerLight_MateName3;
    
    g_FlowerLight_Mark[1] = FlowerLight_Mark1;
    g_FlowerLight_Mark[2] = FlowerLight_Mark2;
    g_FlowerLight_Mark[3] = FlowerLight_Mark3;
    
	g_FlowerLight_ActionButton[1] = FlowerLight_MateIcon1;
	g_FlowerLight_ActionButton[2] = FlowerLight_MateIcon2;
	g_FlowerLight_ActionButton[3] = FlowerLight_MateIcon3;

	g_FlowerLight_MateNum[1] = FlowerLight_MateNum1;
	g_FlowerLight_MateNum[2] = FlowerLight_MateNum2;
	g_FlowerLight_MateNum[3] = FlowerLight_MateNum3;
		
	g_Frame_UnifiedXPosition	= FlowerLight_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= FlowerLight_Frame:GetProperty("UnifiedYPosition");
		
end

function FlowerLight_OnShown()
    FlowerLight_DragTitle:SetText(g_FlowerLight_Item[g_FlowerLight_DengLevel].msg)
    FlowerLight_FlameTip:SetText( ScriptGlobal_Format("#{HDRZ_180322_10}",g_FlowerLight_Item[g_FlowerLight_DengLevel].cnt) )
	
	local GiftItemID = g_FlowerLight_DengYouId
	--灯油
	for i = 1, 3 do
		g_FlowerLight_MateNum[i]:SetText(string.format("%d", g_FlowerLight_Item[g_FlowerLight_DengLevel].cnt))
		--local theAction = DataPool:CreateActionItemForShow(GiftItemID, 1)
		--if theAction:GetID() ~= 0 then
		--	g_FlowerLight_ActionButton[i]:SetActionItem(theAction:GetID());
			--g_FlowerLight_ActionButton[i]:Show();
		--end		
	end
	
	local j = 2
	for i = 1, 3 do
		if g_FlowerLight_CharIndex+1 == i then
			g_FlowerLight_MateName[1]:SetText(g_FlowerLight_MemberName[i])
			if g_FlowerLight_ConfirmFlag[i] == 1 then
				g_FlowerLight_Mark[1]:Show()
				local theAction = DataPool:CreateActionItemForShow(GiftItemID, 1)
				if theAction:GetID() ~= 0 then
					g_FlowerLight_ActionButton[1]:SetActionItem(theAction:GetID());
					g_FlowerLight_ActionButton[1]:Show();
				end
			else
				g_FlowerLight_Mark[1]:Hide()
				--g_FlowerLight_ActionButton[1]:Hide()
			end
		else
			g_FlowerLight_MateName[j]:SetText(g_FlowerLight_MemberName[i])
			if g_FlowerLight_ConfirmFlag[i] == 1 then
				g_FlowerLight_Mark[j]:Show()
				local theAction = DataPool:CreateActionItemForShow(GiftItemID, 1)
				if theAction:GetID() ~= 0 then
					g_FlowerLight_ActionButton[j]:SetActionItem(theAction:GetID());
					g_FlowerLight_ActionButton[j]:Show();
				end
			else
				g_FlowerLight_Mark[j]:Hide()
				--g_FlowerLight_ActionButton[j]:Hide()
			end			
			j = j+1
		end
  
    end
    
    --if g_FlowerLight_CharIndex == 0 then
    --    FlowerLight_Button:SetText("放飞花灯")
    --else
	local index = g_FlowerLight_CharIndex+1
	if g_FlowerLight_ConfirmFlag[index] == 1 then
		FlowerLight_Button:Disable()
	else
		FlowerLight_Button:Enable()
	end
		
		
    FlowerLight_Button:SetText("#{HDRZ_180322_11}")
    --end
	
	local strtmp = ""
	--if g_FlowerLight_DengStage == 1 then
		strtmp = g_FlowerLight_Item[g_FlowerLight_DengLevel].tips1
	--elseif g_FlowerLight_DengStage == 2 then
	--	strtmp = g_FlowerLight_Item[g_FlowerLight_DengLevel].tips2
	--end
	
	FlowerLight_FlameImage:SetToolTip(ScriptGlobal_Format("#{HDRZ_180322_06}",g_FlowerLight_Item[g_FlowerLight_DengLevel].cnt, strtmp) )
    
	this:Show();
end
--=========================================================
--确认
--=========================================================

function FlowerLight_Button_Clicked()
    
		Clear_XSCRIPT()
		    Set_XSCRIPT_Function_Name("OnConfirm")
		    Set_XSCRIPT_ScriptID(892723)
            Set_XSCRIPT_Parameter(0,g_NpcObjId)
		    Set_XSCRIPT_ParamCount(1)
	    Send_XSCRIPT()

       
end

--=========================================================
--开始关心NPC
--=========================================================
function FlowerLight_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "FlowerLight");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "FlowerLight")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function FlowerLight_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "FlowerLight");
		g_Object = -1;
	end
end

function FlowerLight_Recall_Hiden()
	isRecallHide = 1;
	this:Hide(); 
end

function FlowerLight_OnHiden()
    FlowerLight_StopCareObject()
	if isRecallHide ~= 1 then
    	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnHiden")
			Set_XSCRIPT_ScriptID(892723)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
	isRecallHide = -1
	this:Hide();  
end
function FlowerLight_ResetPos()
	FlowerLight_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	FlowerLight_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end



