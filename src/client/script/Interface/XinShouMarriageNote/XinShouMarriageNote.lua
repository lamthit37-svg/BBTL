--------------------------------------------
-- XinShouMarriageNote.lua
-- !!!reloadscript =XinShouMarriageNote
--------------------------------------------

-- 好友界面的默认位置
local g_XinShouMarriageNoteFrame_UnifiedXPosition;
local g_XinShouMarriageNoteFrame_UnifiedYPosition;

local g_XinShouMarriageNote_Type = 0
local g_XinShouMarriageNote_CareObj = -1
local g_XinShouMarriageNote_MaxDistance = 10
local g_XinShouMarriageNote_SendCloseMsg = 0
local g_XinShouMarriageNote_Name = 
{
	[0] = "",
	[1] = "",
}


--===============================================
-- PreLoad()
--===============================================
function XinShouMarriageNote_PreLoad()

	

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

--===============================================
-- OnLoad()
--===============================================
function XinShouMarriageNote_OnLoad()
	
	-- 保存好友界面的默认相对位置
	g_XinShouMarriageNoteFrame_UnifiedXPosition	= XinShouMarriageNote_Frame:GetProperty("UnifiedXPosition");
	g_XinShouMarriageNoteFrame_UnifiedYPosition	= XinShouMarriageNote_Frame:GetProperty("UnifiedYPosition");

end

--===============================================
-- OnEvent()
--===============================================
function XinShouMarriageNote_OnEvent( event )
	-- 打开界面
	if ( event == "UI_COMMAND" and 89275301 == tonumber(arg0) ) then
		local npcid = Get_XParam_INT(0)
		if( npcid ~= -1 ) then
			g_XinShouMarriageNote_CareObj = DataPool:GetNPCIDByServerID(npcid)
		end
		XinShouMarriageNote_ClearData()
		g_XinShouMarriageNote_SendCloseMsg = 0
		g_XinShouMarriageNote_Type = Get_XParam_INT(1)
		XinShouMarriageNote_Update()
		this:Show()
		XinShouMarriageNote_CareObject()
	elseif(event == "UI_COMMAND" and 89275302 == tonumber(arg0)) then --填写名字
		if(not this:IsVisible()) then
			return
		end
		local szName = Get_XParam_STR(0)
		if(g_XinShouMarriageNote_Type == 0) then
			g_XinShouMarriageNote_Name[1] = szName
		else
			g_XinShouMarriageNote_Name[0] = szName
		end
		XinShouMarriageNote_Update()
	elseif(event == "UI_COMMAND" and 89275303 == tonumber(arg0)) then --关闭界面
		if(this:IsVisible()) then
			XinShouMarriageNote_CloseWhithOutMsg()
		end
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		XinShouMarriageNote_CloseWhithOutMsg()
	elseif(event == "OBJECT_CARED_EVENT") then
		if (tonumber(arg0) ~= g_XinShouMarriageNote_CareObj) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > g_XinShouMarriageNote_MaxDistance) or arg1=="destroy") then
			XinShouMarriageNote_Close()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		XinShouMarriageNote_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		XinShouMarriageNote_ResetPos()
	
	end
end


--================================================
-- 隐藏界面
--================================================
function XinShouMarriageNote_Close(nIndex)
	XinShouMarriageNote_StopCareObject()
	if(g_XinShouMarriageNote_SendCloseMsg == 0) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("CloseSoupseUI");
			Set_XSCRIPT_ScriptID(892753);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
	end
	XinShouMarriageNote_ClearData()
	this:Hide();
end

function XinShouMarriageNote_CloseWhithOutMsg()
	XinShouMarriageNote_StopCareObject()
	XinShouMarriageNote_ClearData()
	g_XinShouMarriageNote_SendCloseMsg = 1
	this:Hide();
end

function XinShouMarriageNote_ClearData()
	g_XinShouMarriageNote_Name[0] = ""
	g_XinShouMarriageNote_Name[1] = ""
	g_XinShouMarriageNote_Type = 0
end

--================================================
-- 恢复好友界面的默认相对位置
--================================================
function XinShouMarriageNote_ResetPos()

	XinShouMarriageNote_Frame:SetProperty("UnifiedXPosition", g_XinShouMarriageNoteFrame_UnifiedXPosition);
	XinShouMarriageNote_Frame:SetProperty("UnifiedYPosition", g_XinShouMarriageNoteFrame_UnifiedYPosition);
	
end

function XinShouMarriageNote_Update()
	if(g_XinShouMarriageNote_Name[0] == "") then
		if(g_XinShouMarriageNote_Type == 0) then
			XinShouMarriageNote_Name1:SetText("#{TLXS_180427_172}")
		else
			XinShouMarriageNote_Name1:SetText("#{TLXS_180427_171}")
		end
	else
		XinShouMarriageNote_Name1:SetText(g_XinShouMarriageNote_Name[0])
	end
	if(g_XinShouMarriageNote_Name[1] == "") then
		if(g_XinShouMarriageNote_Type == 1) then
			XinShouMarriageNote_Name2:SetText("#{TLXS_180427_172}")
		else
			XinShouMarriageNote_Name2:SetText("#{TLXS_180427_171}")
		end
	else
		XinShouMarriageNote_Name2:SetText(g_XinShouMarriageNote_Name[1])
	end
end

function XinShouMarriageNote_SingClick()
	if(g_XinShouMarriageNote_Name[g_XinShouMarriageNote_Type] ~= nil) then
		g_XinShouMarriageNote_Name[g_XinShouMarriageNote_Type] = Player:GetName()
		local bCheck1 = 0
		local bCheck2 = 0
		if(g_XinShouMarriageNote_Name[0] ~= nil and g_XinShouMarriageNote_Name[0] ~= "") then
			bCheck1 = 1
		end
		if(g_XinShouMarriageNote_Name[1] ~= nil and g_XinShouMarriageNote_Name[1] ~= "") then
			bCheck2 = 1
		end
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SingName");
			Set_XSCRIPT_ScriptID(892753);
			Set_XSCRIPT_Parameter(0,bCheck1)
			Set_XSCRIPT_Parameter(1,bCheck2)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
		XinShouMarriageNote_Update()
	end
end

function XinShouMarriageNote_CareObject()
	this:CareObject(g_XinShouMarriageNote_CareObj, 1, "XinShouMarriageNote")
	return
end

function XinShouMarriageNote_StopCareObject()
	this:CareObject(g_XinShouMarriageNote_CareObj, 0, "XinShouMarriageNote")
	g_XinShouMarriageNote_CareObj = -1
	return
end



