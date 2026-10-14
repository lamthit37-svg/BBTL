-- 九星神器升星设计-魂玉合成

local g_UnifiedPosition = nil
local g_nObjCaredID = -1
local ObjCaredID = -1
local g_nIndex = 0
local g_MaxNum = 0
local g_CurNum = 0
local MAX_OBJ_DISTANCE = 3.0

--=========================================================
--PreLoad()
--=========================================================
function ShenqiSX_HY_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "OBJECT_CARED_EVENT" )
	this : RegisterEvent( "ADJEST_UI_POS" )
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" )
end

--=========================================================
--OnLoad()
--=========================================================
function ShenqiSX_HY_OnLoad()
	g_UnifiedPosition = ShenqiSX_HY_Frame:GetProperty("UnifiedPosition")
	ShenqiSX_HY_Reset()
end

--=========================================================
--事件响应
--=========================================================
function ShenqiSX_HY_OnEvent( event )

	if event == "UI_COMMAND" and tonumber(arg0) == 89247202 then
		local targetId = Get_XParam_INT(0)
		ObjCaredID = DataPool : GetNPCIDByServerID( targetId )
		if ObjCaredID == -1 then
			--PushDebugMessage("server传过来的数据有问题。")
			return
		end
		local nIndex = Get_XParam_INT(1)
		if nIndex == nil or nIndex < 1 or nIndex > 2 then
			return
		end
		BeginCareObject_ShenqiSX_HY()
		g_nObjCaredID = targetId		
		g_nIndex = nIndex
		g_MaxNum = Get_XParam_INT(2)
		local strMsg = Get_XParam_STR(0)
		ShenqiSX_HY_Info:SetText(strMsg)
		ShenqiSX_HY_InputValue:SetText(g_MaxNum)
		ShenqiSX_HY_InputValue:SetProperty("DefaultEditBox", "True")
		ShenqiSX_HY_InputValue:SetSelected(0, -1)
		this : Show()
			
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89247203 then
		-- 关闭界面
		ShenqiSX_HY_Close()

	elseif event == "OBJECT_CARED_EVENT" then
		if( tonumber(arg0) ~= ObjCaredID ) then
			return
		end
		if( arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1=="destroy" ) then
			ShenqiSX_HY_Close()
		end
	
	elseif (event == "ADJEST_UI_POS" ) then
		ShenqiSX_HY_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ShenqiSX_HY_Frame_On_ResetPos()
		
	end

end

--=========================================================
--重置界面
--=========================================================
function ShenqiSX_HY_Reset()
	g_nObjCaredID = -1
	g_nIndex = 0
	g_MaxNum = 0
	g_CurNum = 0
end

--=========================================================
--关闭
--=========================================================
function ShenqiSX_HY_Close()
	this : Hide()
	StopCareObject_ShenqiSX_HY()
	ShenqiSX_HY_Reset()
end

--=========================================================
--界面隐藏
--=========================================================
function ShenqiSX_HY_OnHiden()
	StopCareObject_ShenqiSX_HY()
	ShenqiSX_HY_Reset()
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_ShenqiSX_HY()
	this : CareObject( ObjCaredID, 1, "ShenqiSX_HY" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_ShenqiSX_HY()
	this : CareObject( ObjCaredID, 0, "ShenqiSX_HY" )
end

--=========================================================
--ResetPos()
--=========================================================
function ShenqiSX_HY_Frame_On_ResetPos()
  ShenqiSX_HY_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
end

--=========================================================
-- 数量改变
--=========================================================
function ShenqiSX_HY_NumChange()
	local nString = ShenqiSX_HY_InputValue:GetText()
	
	--默认为MAX
  if nString == nil or nString == "" then
		g_CurNum = 0
		return
	end

	local nBuysNum = tonumber(nString)
  if nBuysNum == nil then
		g_CurNum = 0
		return
	end

	--小于0时
	if nBuysNum <= 0 then
		g_CurNum = 1
		ShenqiSX_HY_InputValue:SetText(g_CurNum)
		return
	end
	
	--大于最大使用数量
  if nBuysNum > g_MaxNum then
    g_CurNum = g_MaxNum
    ShenqiSX_HY_InputValue:SetText(g_CurNum)
    return
  end

	g_CurNum = nBuysNum
end

--=========================================================
--确认
--=========================================================
function ShenqiSX_HY_OK_Clicked()
	if g_CurNum <= 0 then
		PushDebugMessage("#{JXSQ_210819_06}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_ExchConfirm" )
		Set_XSCRIPT_ScriptID( 892472 )
		Set_XSCRIPT_Parameter( 0, g_nObjCaredID )
		Set_XSCRIPT_Parameter( 1, g_nIndex )
		Set_XSCRIPT_Parameter( 2, tonumber(g_CurNum) )
		Set_XSCRIPT_ParamCount( 3 )
	Send_XSCRIPT()	
end

--=========================================================
--取消
--=========================================================
function ShenqiSX_HY_Cancel_Clicked()
	ShenqiSX_HY_Close()
end