	
local g_SelectFacestyle_YuanbaoPay=1
local g_SelectFacestyle_Frame_UnifiedPosition;
local g_clientNpcId = -1
local g_ExteriorType = 3 --脸型
local g_MaxBarNum = 0
local g_BarList = {}
local g_CurSelExteriorID = 0		--当前选择的外观ID，从1开始
local g_CurSelExteriorIndex = 0		--当前选择的外观索引，从1开始
local g_menpaiid = -1 --玩家自己的门派id
local OriginalCharFaceId = 0
local g_DataListCount = 0

local SelectFacestyle_CameraHeight = 1		--摄影机高度
local SelectFacestyle_CameraDistance = 2	--摄影机距离
local SelectFacestyle_CameraPitch = 3		--摄影机角度
local g_SelectFacestyle_CameraLevel = 0
local g_SelectFacestyle_CameraPosition =
{
	[0] = {fHeight = 1.09, fDistance = 1.30, },
	[1] = {fHeight = 0.90, fDistance = 2.30, },
	[2] = {fHeight = 0.63, fDistance = 3.30, }, 
}

local g_SelectFacestyle_SpecialPitch = 0.1

local g_SelectHairstyle_SpecialCamera =
{
	[0] = {fHeight = 1.63, fDistance = 1.3, fPitch = 0.13, fXOffset = 0,},
	[1] = {fHeight = 1.8, fDistance = 1.4, fPitch = 0.15, fXOffset = 0},

}

local g_SelectFacestyle_HeadCameraPosition = {Save = 0, fHeight = 1.09, fDistance = 1.30, fPitch = 0.13, fBigDistance = 1.90}
--==================================
-- SelectFacestyle_PreLoad
--==================================
function SelectFacestyle_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);	
	this:RegisterEvent("SEX_CHANGED",false);	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("REFRESH_FACESTYLE",false);		--刷新的这块需要改
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);	
end

--==================================
-- SelectFacestyle_OnLoad
--==================================
function SelectFacestyle_OnLoad()
	g_SelectFacestyle_Frame_UnifiedPosition=SelectFacestyle_Frame:GetProperty("UnifiedPosition");
	g_CurSelExteriorID = 0
	g_CurSelExteriorIndex = 0
end

function SelectFacestyle_Frame_On_ResetPos()
	SelectFacestyle_Frame:SetProperty("UnifiedPosition", g_SelectFacestyle_Frame_UnifiedPosition);
end
--==================================
-- SelectFacestyle_OnEvent
--==================================
function SelectFacestyle_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		if ( tonumber(arg0) == 928 ) then
			local npcObjId = Get_XParam_INT(0)
			g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
			if g_clientNpcId == -1 then
				PushDebugMessage("未发现 NPC")
				SelectFacestyle_Close()
				return
			end
		
			this:CareObject( g_clientNpcId, 1, "SelectFacestyle" )

			if(IsWindowShow("Shop_Dresser")) then
				CloseWindow("Shop_Dresser", true);
			end

			if(IsWindowShow("SelectHairstyle")) then
				CloseWindow("SelectHairstyle", true);
			end

			if(IsWindowShow("SelectHairColor")) then
				CloseWindow("SelectHairColor", true);
			end
			
			PushEvent( "CLOSE_DRESSPREVIEW") 				
			PushEvent( "CLOSE_GEMEFFECTPREVIEW")
			SelectFacestyle_OnShown()
			this:Show();
		elseif ( tonumber(arg0) == 20141215 ) then
			-- 更新和解锁合并成一个消息返回
			OriginalCharFaceId = DataPool : Get_MyFaceStyle()
			local charFaceId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid = Exterior:LuaFnGetExteriorFaceStyleInfo(g_CurSelExteriorID)
			PushDebugMessage(ScriptGlobal_Format("#{GXHDZ_141121_19}",StyleName))
		end
	elseif event == "SEX_CHANGED" and  this:IsVisible() then
			SelectFacestyle_Model : Hide();
			SelectFacestyle_Model : Show();
			SelectFacestyle_Model : SetFakeObject("Player_Head");
	elseif (event == "ADJEST_UI_POS" ) then
		SelectFacestyle_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SelectFacestyle_Frame_On_ResetPos()
	elseif (event == "REFRESH_FACESTYLE") then
		SelectFacestyle_Update()
	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
		Exterior:LuaFnInitExteriorList(g_ExteriorType)
		g_MaxBarNum = Exterior:LuaFnGetExteriorMaxCount(g_ExteriorType)
		for i = 1, g_MaxBarNum do
			SelectFacestyle_SetItem(i)
		end
	end
	
	-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	   ( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			SelectFacestyle_Close()
			return
		end
	end	

end


function SelectFacestyle_OnShown()
	g_Distance = 1
	if g_SelectFacestyle_YuanbaoPay == 1 or g_SelectFacestyle_YuanbaoPay == 0 then
		SelectFacestyle_Blank_Queren:SetCheck(g_SelectFacestyle_YuanbaoPay)
	end
	OriginalCharFaceId = DataPool : Get_MyFaceStyle();
	
	
	local mySex = GetMySelfRaceId()
	if mySex > 1 or mySex < 0 then 
		mySex = 0
	end

	SelectFacestyle_Model : SetFakeObject( "" )
	SelectFacestyle_Model : SetFakeObject( "Player_Head" )
	FakeObj_RestoreCamera( "Player_Head" )
	
	FakeObj_SetCamera( "Player_Head", SelectFacestyle_CameraPitch, g_SelectFacestyle_SpecialPitch )

	if g_SelectFacestyle_HeadCameraPosition ~= nil and g_SelectFacestyle_HeadCameraPosition.Save < 1 then
		local fHeight, fDistance, fPitch = FakeObj_GetCamera("Player_Head")
		g_SelectFacestyle_HeadCameraPosition.fHeight = fHeight
		g_SelectFacestyle_HeadCameraPosition.fDistance = fDistance
		g_SelectFacestyle_HeadCameraPosition.fPitch = fPitch
		g_SelectFacestyle_HeadCameraPosition.Save = 1
	end

	-- 获取头饰ID
	local ornamentsHeadID = OrnamentsScript:GetOrnamentsUseID(1)
	if ornamentsHeadID > 0 and OrnamentsScript:IsBigOrnamentsHead(ornamentsHeadID) > 0 then
		-- 如果是大头ID，设置专门的摄像机位置
		FakeObj_SetCamera( "Player_Head", SelectFacestyle_CameraDistance, g_SelectFacestyle_HeadCameraPosition.fBigDistance )
	else
		FakeObj_SetCamera( "Player_Head", SelectFacestyle_CameraDistance, g_SelectFacestyle_HeadCameraPosition.fDistance )
	end
	
	local isIVMode = LuaFnGetCurModelState()
	if isIVMode == 1 then
		--local  fHeight, fDistance, fPitch = FakeObj_GetCamera( "Player_Head" )
		--PushDebugMessage("fHeight = "..fHeight.." fDistance = "..fDistance.." fPitch = "..fPitch)
		NewFakeObj_SetCamera_WithXOffset( "Player_Head", g_SelectHairstyle_SpecialCamera[mySex].fHeight, 
														g_SelectHairstyle_SpecialCamera[mySex].fDistance,
														g_SelectHairstyle_SpecialCamera[mySex].fPitch,
														g_SelectHairstyle_SpecialCamera[mySex].fXOffset )
	end	
	
	g_menpaiid = Player : GetData("MEMPAI")
	--默认选中当前装饰的外观id
	local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
	-- PushDebugMessage("cacheExteriorID:"..tostring(cacheExteriorID))
	if cacheExteriorID > 0 then
		g_CurSelExteriorID = cacheExteriorID
	end
	SelectFacestyle_Update()
	SelectFacestyle_Model : SetFakeObject( "Player_Head" )
end

function SelectFacestyle_Update()
	Exterior:LuaFnInitExteriorList(g_ExteriorType)
	g_MaxBarNum = Exterior:LuaFnGetExteriorMaxCount(g_ExteriorType)
	g_DataListCount = Exterior:LuaFnGetExteriorListCount(g_ExteriorType, 0)
	-- PushDebugMessage("g_MaxBarNum:"..tostring(g_MaxBarNum))
	SelectFacestyle_StyleList:Clear()
	for i = 1, g_MaxBarNum do
		local bar = SelectFacestyle_StyleList:AddChild("SelectFacestyle_SuperListItem")
		bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
		g_BarList[i] = bar	
		bar:GetSubItem("SelectFacestyle_Skill1_BKG"):SetEvent("MouseLButtonDown", string.format("SelectFacestyle_ItemClicked(%d)", i))
		bar:GetSubItem("SelectFacestyle_Skill1_BKG"):SetEvent("MouseMove", string.format("SelectFacestyle_ItemMouseMove(%d)", i))
		SelectFacestyle_SetItem(i)
	end
	SelectFacestyle_ShowDetail()
end

--初始化每个图鉴item
function SelectFacestyle_SetItem(index)
	if g_BarList[index] == nil then
		return
	end
	if index > g_DataListCount then
		g_BarList[index]:Hide()
		return
	end
	local bar = g_BarList[index]
	bar:Show()
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, index - 1)
	local charFaceId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid = Exterior:LuaFnGetExteriorFaceStyleInfo(nExteriorID)
	if charFaceId>0 then
		local ctrlAction = bar:GetSubItem("SelectFacestyle_Skill1_BKG")
		if ctrlAction ~= nil then
			-- PushDebugMessage("IconFile:"..tostring(IconFile))
			IconFile = GetIconFullName(IconFile)
			ctrlAction:SetProperty("NormalImage", IconFile)
			ctrlAction:SetProperty("HoverImage", IconFile)
			ctrlAction:SetToolTip(StyleName)
			
			if g_CurSelExteriorID == nExteriorID then
				ctrlAction:SetPushed(1)
			else
				ctrlAction:SetPushed(0)
			end
		end
		bar:GetSubItem("SelectFacestyle_SuperListItemActionTry1"):Hide()
		bar:GetSubItem("SelectFacestyle_SuperListItemActionDef1"):Hide()
		local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		if nExteriorID == cacheExteriorID then
			--当前正在装备的
			bar:GetSubItem("SelectFacestyle_SuperListItemActionDef1"):Show()
			-- bar:GetSubItem("SelectFacestyle_SuperListItemActionTry1"):Hide()
		-- else
		-- 	bar:GetSubItem("SelectFacestyle_SuperListItemActionDef1"):Hide()
		-- 	bar:GetSubItem("SelectFacestyle_SuperListItemActionTry1"):Show()
		end
		bar:GetSubItem("SelectFacestyle_SuperListItemActionAct1"):Hide()
		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then		
			-- PushDebugMessage("nExteriorID:"..tostring(nExteriorID))	
			bar:GetSubItem("SelectFacestyle_Skill1_BKG_Mask"):Hide()
			bar:GetSubItem("SelectFacestyle_SuperListItemActionLock1"):Hide()
		else
			-- 可激活标识
			local have_count = PlayerPackage:Lua_GetUnLockItemCount(ItemID)
			if ItemID ~= 30008020 and have_count >= ItemCount then 
				bar:GetSubItem("SelectFacestyle_SuperListItemActionAct1"):Show()
			end
			--没有的还要区分一下 是不是可以获得的 有门派限制的获得不了  获得不了 需要显示mask
			if menpaiid ~= -1 and g_menpaiid ~= menpaiid then
				bar:GetSubItem("SelectFacestyle_Skill1_BKG_Mask"):Show()
			else 
				bar:GetSubItem("SelectFacestyle_Skill1_BKG_Mask"):Hide()
			end
			bar:GetSubItem("SelectFacestyle_SuperListItemActionLock1"):Show()
		end	
	end
end

--只是点击action时切换
function SelectFacestyle_ItemClicked(nIndex)

	local oldbar = g_BarList[g_CurSelExteriorIndex]
	if oldbar~=nil then
		oldbar:GetSubItem("SelectFacestyle_SuperListItemActionTry1"):Hide()
	end
	g_CurSelExteriorIndex = nIndex
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, nIndex - 1)
	
	local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
	if nExteriorID ~= cacheExteriorID then
		--当前不是正在装备的
		local newbar = g_BarList[g_CurSelExteriorIndex]
		newbar:GetSubItem("SelectFacestyle_SuperListItemActionTry1"):Show()
	end
	g_CurSelExteriorID = nExteriorID
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("SelectFacestyle_Skill1_BKG")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
	SelectFacestyle_ShowDetail()
end

--显示下方label信息
function SelectFacestyle_ShowDetail()
	local charFaceId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid = Exterior:LuaFnGetExteriorFaceStyleInfo(g_CurSelExteriorID)
	if charFaceId <= 0 then
		return
	end
	local name,icon = LifeAbility : GetPrescr_Material(ItemID);	
	if Exterior:LuaFnIsHaveExterior(g_ExteriorType, g_CurSelExteriorID) == 1 then	
		if menpaiid == -1 then
			SelectFacestyle_WarningText : SetText("#{GXHDZ_141121_03}")
			SelectFacestyle_Accept:SetText("#{GXHDZ_141121_04}")	
		elseif  g_menpaiid ==  menpaiid then
			local menpainame = SelectFacestyle_GetMenpaiString(menpaiid)
			local scriptglobal = ScriptGlobal_Format("#{HWMP_200619_06}",menpainame)
			SelectFacestyle_WarningText : SetText(scriptglobal.."#r".."#{GXHDZ_141121_03}")
		else 
			local menpainame = SelectFacestyle_GetMenpaiString(menpaiid)
			local scriptglobal = ScriptGlobal_Format("#{HWMP_200619_05}",menpainame)
			SelectFacestyle_WarningText : SetText(scriptglobal.."#r".."#{GXHDZ_141121_03}")
		end
		local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		if g_CurSelExteriorID == cacheExteriorID then
			--当前正在装备的
			SelectFacestyle_WarningText : SetText("#r".."#{WGTJ_210112_12}")
		end
	else
		SelectFacestyle_Accept:SetText("#{GXHDZ_141121_10}")
		if menpaiid == -1 then
			SelectFacestyle_WarningText : SetText("需要道具：#G"..name.."#r#W需要金钱：#Y#{_EXCHG"..CostMoney.."}#r".."#{GXHDZ_141121_05}");		
		elseif  g_menpaiid ==  menpaiid then
			local menpainame = SelectFacestyle_GetMenpaiString(menpaiid)
			local scriptglobal = ScriptGlobal_Format("#{HWMP_200619_04}",menpainame)
			SelectFacestyle_WarningText : SetText("需要道具：#G"..name.."#r#W需要金钱：#Y#{_EXCHG"..CostMoney.."}".."#r"..scriptglobal.."#r".."#{GXHDZ_141121_05}");		
		else 
			local menpainame = SelectFacestyle_GetMenpaiString(menpaiid)
			local scriptglobal = ScriptGlobal_Format("#{HWMP_200619_03}",menpainame)
			SelectFacestyle_WarningText : SetText("需要道具：#G"..name.."#r#W需要金钱：#Y#{_EXCHG"..CostMoney.."}".."#r"..scriptglobal.."#r".."#{GXHDZ_141121_05}");		
		end
	end
	--切换mesh
	DataPool : Change_MyFaceStyle(charFaceId)
end

function SelectFacestyle_OK_Clicked()

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("UnlockAndChangeExteriorFaceId");
		Set_XSCRIPT_ScriptID(805029);
		Set_XSCRIPT_Parameter(0,g_CurSelExteriorID);
		Set_XSCRIPT_Parameter(1,g_SelectFacestyle_YuanbaoPay);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
	

end

function SelectFacestyle_ItemMouseMove(nIndex)

end

function SelectFacestyle_Blank_Queren_Clicked() 
	g_SelectFacestyle_YuanbaoPay = SelectFacestyle_Blank_Queren:GetCheck();
end

--hidden事件触发
function SelectFacestyle_Cancel_Clicked()
	SelectFacestyle_Model : SetFakeObject( "" );
	g_CurSelExteriorID = 0
	g_CurSelExteriorIndex = 0
	this:CareObject( g_clientNpcId, 0, "SelectFacestyle" )
	g_clientNpcId = -1
	--关闭二次确认界面
	PushEvent("CONVENIENT_BUY_CONFIRM_CLOSE")
	DataPool : Change_MyFaceStyle(OriginalCharFaceId)
end

--关闭
function SelectFacestyle_Close()
	this:Hide()
end

--==================================
--左转
--==================================
function SelectFacestyle_Modle_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		if(start == 1) then
			SelectFacestyle_Model:RotateBegin(-0.3);
		else
			SelectFacestyle_Model:RotateEnd();
		end
	end
end

--==================================
--右转
--==================================
function SelectFacestyle_Modle_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		if(start == 1) then
			SelectFacestyle_Model:RotateBegin(0.3);
		else
			SelectFacestyle_Model:RotateEnd();
		end
	end
end


--放大
function SelectFacestyle_ZoomIn()
	if g_SelectFacestyle_CameraLevel < 1  or g_SelectFacestyle_CameraLevel > 2 then
		return
	end
	
	g_SelectFacestyle_CameraLevel = g_SelectFacestyle_CameraLevel - 1
	SelectFacestyle_SetCameraPosition()

end

--缩小
function SelectFacestyle_ZoomOut()

	if g_SelectFacestyle_CameraLevel < 0  or g_SelectFacestyle_CameraLevel > 1 then
		return
	end
	
	g_SelectFacestyle_CameraLevel = g_SelectFacestyle_CameraLevel + 1
	SelectFacestyle_SetCameraPosition()
end



function SelectFacestyle_SetCameraPosition()
	if g_SelectFacestyle_CameraLevel > -1 and g_SelectFacestyle_CameraLevel < 3 then
		FakeObj_SetCamera( "Player_Head", SelectFacestyle_CameraHeight, g_SelectFacestyle_CameraPosition[g_SelectFacestyle_CameraLevel].fHeight )
		FakeObj_SetCamera( "Player_Head", SelectFacestyle_CameraDistance, g_SelectFacestyle_CameraPosition[g_SelectFacestyle_CameraLevel].fDistance )
		FakeObj_RestoreCamera( "Player_Head" )
	end
end

function SelectFacestyle_GetMenpaiString( menpai )
	local strName = "";

	-- 得到门派名称.
	if(0 == menpai) then
		strName = "#{GMItem_4}";

	elseif(1 == menpai) then
		strName = "#{GMItem_5}";

	elseif(2 == menpai) then
		strName = "#{GMItem_6}";

	elseif(3 == menpai) then
		strName = "#{GMItem_7}";

	elseif(4 == menpai) then
		strName = "#{GMItem_8}";

	elseif(5 == menpai) then
		strName = "#{GMItem_9}";

	elseif(6 == menpai) then
		strName = "#{GMItem_10}";

	elseif(7 == menpai) then
		strName = "#{GMItem_11}";

	elseif(8 == menpai) then
		strName = "#{GMItem_12}";

	elseif(9 == menpai) then
		strName = "无门派";

	elseif(10== menpai) then
		strName = "#{GMItem_17}";

	elseif(11== menpai) then
		strName = "#{XMPTM_130123_01}";
		
	elseif(12== menpai) then
		strName = "#{XMPGG_160524_02}";
	elseif(13== menpai) then
		strName = "#{THDXG_190705_04}"; --桃花岛
		
	elseif(14== menpai) then
		strName = "#{XMPHM_210604_01}";
	elseif(15== menpai) then--menpa15 mptodo
		strName = "#{GMGameInterface_Script_DataPool_Info_ERenGu}";
	end

	return strName;
end