local g_SelectHairstyle_Frame_UnifiedPosition;
local g_SelectHairstyle_YuanbaoPay=1
local g_clientNpcId = -1
local g_ExteriorType = 4 --发型
local g_MaxBarNum = 0
local g_BarList = {}
local g_CurSelExteriorID = 0		--当前选择的外观ID，从1开始
local g_CurSelExteriorIndex = 0		--当前选择的外观索引，从1开始
local g_menpaiid = -1 --玩家自己的门派id

local OriginalCharHairId = 0
local g_DataListCount = 0

local SelectHairstyle_CameraHeight = 1		--摄影机高度
local SelectHairstyle_CameraDistance = 2	--摄影机距离
local SelectHairstyle_CameraPitch = 3		--摄影机角度
local g_SelectHairstyle_CameraLevel = 0
local g_SelectHairstyle_CameraPosition =
{
	[0] = {fHeight = 1.09, fDistance = 1.30, },
	[1] = {fHeight = 0.90, fDistance = 2.30, },
	[2] = {fHeight = 0.63, fDistance = 3.30, }, 
}

local g_SelectHairstyle_SpecialPitch = 0.1

local g_SelectHairstyle_SpecialCamera =
{
	[0] = {fHeight = 1.63, fDistance = 1.3, fPitch = 0.13, fXOffset = 0,},
	[1] = {fHeight = 1.8, fDistance = 1.4, fPitch = 0.15, fXOffset = 0},

}

local g_SelectHairstyle_HeadCameraPosition = {Save = 0, fHeight = 1.09, fDistance = 1.30, fPitch = 0.13, fBigDistance = 1.90}

function SelectHairstyle_PreLoad()
	this:RegisterEvent("UI_COMMAND", true);	
	this:RegisterEvent("SEX_CHANGED", false);	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("REFRESH_HAIRSTYLE", false);	
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);	
end

function SelectHairstyle_OnLoad()
	
	g_SelectHairstyle_Frame_UnifiedPosition=SelectHairstyle_Frame:GetProperty("UnifiedPosition");

end

function SelectHairstyle_Frame_On_ResetPos()
	SelectHairstyle_Frame:SetProperty("UnifiedPosition", g_SelectHairstyle_Frame_UnifiedPosition);
end

function SelectHairstyle_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		if ( tonumber(arg0) == 21 ) then
			local npcObjId = Get_XParam_INT(0)
			g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
			if g_clientNpcId == -1 then
				PushDebugMessage("未发现 NPC")
				SelectHairstyle_Close()
				return
			end
			this:CareObject( g_clientNpcId, 1, "SelectHairstyle" )

			if(IsWindowShow("Shop_Dresser")) then
				CloseWindow("Shop_Dresser", true);
			end
			if(IsWindowShow("SelectHairColor")) then
				CloseWindow("SelectHairColor", true);
			end
			
			if(IsWindowShow("SelectFacestyle")) then
				CloseWindow("SelectFacestyle", true);
			end
			
			PushEvent( "CLOSE_DRESSPREVIEW") 	
			PushEvent( "CLOSE_GEMEFFECTPREVIEW")
			SelectHairstyle_OnShown()
			this:Show()
		elseif ( tonumber(arg0) == 20141224 ) then
			-- 更新和解锁合并成一个消息返回
			OriginalCharHairId = DataPool : Get_MyHairStyle()
			local charHairId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid = Exterior:LuaFnGetExteriorHairStyleInfo(g_CurSelExteriorID)
			if StyleName ~= nil then
				PushDebugMessage(ScriptGlobal_Format("#{GXHDZ_141121_30}",StyleName))
			end
		end
	elseif event == "SEX_CHANGED" and  this:IsVisible() then
		SelectHairstyle_Model : Hide();
		SelectHairstyle_Model : Show();
		SelectHairstyle_Model:SetFakeObject("Player_Head");
	elseif (event == "ADJEST_UI_POS" ) then
		SelectHairstyle_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SelectHairstyle_Frame_On_ResetPos()
	elseif (event == "REFRESH_HAIRSTYLE") then
		SelectHairstyle_Update()
	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
		Exterior:LuaFnInitExteriorList(g_ExteriorType)
		g_MaxBarNum = Exterior:LuaFnGetExteriorMaxCount(g_ExteriorType)
		for i = 1, g_MaxBarNum do
			SelectHairstyle_SetItem(i)
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

function SelectHairstyle_OnShown()
	--yuanbaoPay
	if g_SelectHairstyle_YuanbaoPay == 1 or g_SelectHairstyle_YuanbaoPay == 0 then
		SelectHairstyle_Blank_Queren:SetCheck(g_SelectHairstyle_YuanbaoPay)
	end
	OriginalCharHairId = DataPool : Get_MyHairStyle()

	local mySex = GetMySelfRaceId()
	if mySex > 1 or mySex < 0 then 
		mySex = 0
	end

	SelectHairstyle_Model : SetFakeObject( "" )
	SelectHairstyle_Model : SetFakeObject( "Player_Head" )
	FakeObj_RestoreCamera( "Player_Head" )
	
	FakeObj_SetCamera( "Player_Head", SelectHairstyle_CameraPitch, g_SelectHairstyle_SpecialPitch )

	if g_SelectHairstyle_HeadCameraPosition ~= nil and g_SelectHairstyle_HeadCameraPosition.Save < 1 then
		local fHeight, fDistance, fPitch = FakeObj_GetCamera("Player_Head")
		g_SelectHairstyle_HeadCameraPosition.fHeight = fHeight
		g_SelectHairstyle_HeadCameraPosition.fDistance = fDistance
		g_SelectHairstyle_HeadCameraPosition.fPitch = fPitch
		g_SelectHairstyle_HeadCameraPosition.Save = 1
	end

	-- 获取头饰ID
	local ornamentsHeadID = OrnamentsScript:GetOrnamentsUseID(1)
	if ornamentsHeadID > 0 and OrnamentsScript:IsBigOrnamentsHead(ornamentsHeadID) > 0 then
		-- 如果是大头ID，设置专门的摄像机位置
		FakeObj_SetCamera( "Player_Head", SelectHairstyle_CameraDistance, g_SelectHairstyle_HeadCameraPosition.fBigDistance )
	else
		FakeObj_SetCamera( "Player_Head", SelectHairstyle_CameraDistance, g_SelectHairstyle_HeadCameraPosition.fDistance )
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
	local cacheExteriorHairID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
	if cacheExteriorHairID > 0 then
		g_CurSelExteriorID = cacheExteriorHairID
	end
	SelectHairstyle_Update();

end

function SelectHairstyle_Update()
	Exterior:LuaFnInitExteriorList(g_ExteriorType)
	g_MaxBarNum = Exterior:LuaFnGetExteriorMaxCount(g_ExteriorType)
	g_DataListCount = Exterior:LuaFnGetExteriorListCount(g_ExteriorType, 0)
	-- PushDebugMessage("g_menpaiid:"..tostring(g_menpaiid))
	SelectHairstyle_StyleList:Clear()
	for i = 1, g_MaxBarNum do
		local bar = SelectHairstyle_StyleList:AddChild("SelectHairstyle_SuperListItem")
		g_BarList[i] = bar	
		bar:GetSubItem("SelectHairstyle_Skill1_BKG"):SetEvent("MouseLButtonDown", string.format("SelectHairstyle_ItemClicked(%d)", i))
		bar:GetSubItem("SelectHairstyle_Skill1_BKG"):SetEvent("MouseMove", string.format("SelectHairstyle_ItemMouseMove(%d)", i))
		SelectHairstyle_SetItem(i)
	end
	SelectHairstyle_ShowDetail()
end

function SelectHairstyle_SetItem(index)
	if g_BarList[index] == nil then
		return
	end
	if index > g_DataListCount then
		g_BarList[index]:Hide()
		return
	end
	local bar = g_BarList[index]
	bar:Show()
	-- PushDebugMessage("index:"..tostring(index))
	local nExteriorID = Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, index - 1)

	local charHairId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid = Exterior:LuaFnGetExteriorHairStyleInfo(nExteriorID)
	-- if charHairId<=0 then
	-- 	PushDebugMessage("charHairId:"..tostring(charHairId))
	-- 	PushDebugMessage("menpaiid:"..tostring(menpaiid))
	-- 	PushDebugMessage("nExteriorID:"..tostring(nExteriorID))
	-- 	PushDebugMessage("index:"..tostring(index))
	-- end
	if charHairId>=0 then
		local ctrlAction = bar:GetSubItem("SelectHairstyle_Skill1_BKG")
		if ctrlAction ~= nil then
			IconFile = GetIconFullName(IconFile)
			-- PushDebugMessage("IconFile:"..tostring(IconFile))
			ctrlAction:SetProperty("NormalImage", IconFile)
			ctrlAction:SetProperty("HoverImage", IconFile)
			ctrlAction:SetToolTip(StyleName)
			
			if g_CurSelExteriorID == nExteriorID then
				ctrlAction:SetPushed(1)
			else
				ctrlAction:SetPushed(0)
			end
		end
		bar:GetSubItem("SelectHairstyle_SuperListItemActionTry1"):Hide()
		bar:GetSubItem("SelectHairstyle_SuperListItemActionDef1"):Hide()
		local cacheExteriorHairID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		if nExteriorID == cacheExteriorHairID then
			--当前正在装备的
			bar:GetSubItem("SelectHairstyle_SuperListItemActionDef1"):Show()
		-- 	bar:GetSubItem("SelectHairstyle_SuperListItemActionTry1"):Hide()
		-- else
		-- 	bar:GetSubItem("SelectHairstyle_SuperListItemActionDef1"):Hide()
		-- 	bar:GetSubItem("SelectHairstyle_SuperListItemActionTry1"):Show()
		end

		bar:GetSubItem("SelectHairstyle_SuperListItemActionAct1"):Hide()
		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then		
			-- PushDebugMessage("nExteriorID:"..tostring(nExteriorID))	
			bar:GetSubItem("SelectHairstyle_Skill1_BKG_Mask"):Hide()
			bar:GetSubItem("SelectHairstyle_SuperListItemActionLock1"):Hide()
		else
			-- 可激活标识
			local have_count = PlayerPackage:Lua_GetUnLockItemCount(ItemID)
			if have_count >= ItemCount then 
				bar:GetSubItem("SelectHairstyle_SuperListItemActionAct1"):Show()
			end
			-- PushDebugMessage("IconFile:"..tostring(IconFile))
			--没有的还要区分一下 是不是可以获得的 有门派限制的获得不了  获得不了 需要显示mask
			if menpaiid ~= -1 and g_menpaiid ~= menpaiid then
				bar:GetSubItem("SelectHairstyle_Skill1_BKG_Mask"):Show()
			else 
				bar:GetSubItem("SelectHairstyle_Skill1_BKG_Mask"):Hide()
			end
			bar:GetSubItem("SelectHairstyle_SuperListItemActionLock1"):Show()
		end	
	end

end

function SelectHairstyle_ItemClicked(nIndex)
	local oldbar = g_BarList[g_CurSelExteriorIndex]
	if oldbar~=nil then
		oldbar:GetSubItem("SelectHairstyle_SuperListItemActionTry1"):Hide()
	end
	g_CurSelExteriorIndex = nIndex
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, nIndex - 1)
	g_CurSelExteriorID = nExteriorID

	local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
	if nExteriorID ~= cacheExteriorID then
		--当前不是正在装备的
		local newbar = g_BarList[g_CurSelExteriorIndex]
		newbar:GetSubItem("SelectHairstyle_SuperListItemActionTry1"):Show()
	end

	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("SelectHairstyle_Skill1_BKG")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
	SelectHairstyle_ShowDetail()
end

function  SelectHairstyle_ShowDetail()
	local charHairId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid = Exterior:LuaFnGetExteriorHairStyleInfo(g_CurSelExteriorID)
	if charHairId < 0 then
		return
	end
	local name,icon = LifeAbility : GetPrescr_Material(ItemID);
	if Exterior:LuaFnIsHaveExterior(g_ExteriorType, g_CurSelExteriorID) == 1 then	
		-- PushDebugMessage("ItemID:"..tostring(ItemID))	
		if menpaiid == -1 then
			SelectHairstyle_WarningText : SetText("#{GXHDZ_141121_21}")
			SelectHairstyle_Accept:SetText("更换")
		elseif  g_menpaiid ==  menpaiid then
			local menpainame = SelectFacestyle_GetMenpaiString(menpaiid)
			local scriptglobal = ScriptGlobal_Format("#{HWMP_200619_13}",menpainame)
			SelectHairstyle_WarningText : SetText(scriptglobal.."#r".."#{GXHDZ_141121_21}")
		else
			local menpainame = SelectFacestyle_GetMenpaiString(menpaiid)
			local scriptglobal = ScriptGlobal_Format("#{HWMP_200619_12}",menpainame)
			SelectHairstyle_WarningText : SetText(scriptglobal.."#r".."#{GXHDZ_141121_21}")
		end		
		local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		if g_CurSelExteriorID == cacheExteriorID then
			--当前正在装备的
			SelectHairstyle_WarningText : SetText("#r".."#{WGTJ_210112_13}")
		end	
	else
		SelectHairstyle_Accept:SetText("确定")
		if menpaiid == -1 then
			SelectHairstyle_WarningText : SetText("需要"..name.." : "..ItemCount.."#r需要金钱: #{_EXCHG"..CostMoney.."}#r#{GXHDZ_141121_83}");
		elseif  g_menpaiid ==  menpaiid then
			local menpainame = SelectFacestyle_GetMenpaiString(menpaiid)
			local scriptglobal = ScriptGlobal_Format("#{HWMP_200619_11}",menpainame)
			SelectHairstyle_WarningText : SetText("需要"..name.." : "..ItemCount.."#r需要金钱: #{_EXCHG"..CostMoney.."}#r"..scriptglobal.."#r#{GXHDZ_141121_83}");	
			
		else
			local menpainame = SelectFacestyle_GetMenpaiString(menpaiid)
			local scriptglobal = ScriptGlobal_Format("#{HWMP_200619_10}",menpainame)
			SelectHairstyle_WarningText : SetText("需要"..name.." : "..ItemCount.."#r需要金钱: #{_EXCHG"..CostMoney.."}#r"..scriptglobal.."#r#{GXHDZ_141121_83}");		
			
		end		
	end
	--切换mesh
	DataPool:Change_MyHairStyle(charHairId);
end
--==================================
--确认
--==================================
function SelectHairstyle_OK_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("UnlockAndChangeExteriorHairId");
		Set_XSCRIPT_ScriptID(801010);
		Set_XSCRIPT_Parameter(0,g_CurSelExteriorID);
		Set_XSCRIPT_Parameter(1,g_SelectHairstyle_YuanbaoPay);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
	
end

function SelectHairstyle_ItemMouseMove(nIndex)

end

function SelectHairstyle_Blank_Queren_Clicked() 
	g_SelectHairstyle_YuanbaoPay = SelectHairstyle_Blank_Queren:GetCheck();
end

function SelectHairstyle_Cancel_Clicked()
	SelectHairstyle_Model : SetFakeObject( "" );
	this:CareObject( g_clientNpcId, 0, "SelectHairstyle" )
	g_clientNpcId = -1
	g_CurSelExteriorID = 0
	g_CurSelExteriorIndex = 0
	PushEvent("CONVENIENT_BUY_CONFIRM_CLOSE");
	DataPool : Change_MyHairStyle(OriginalCharHairId)
end

--关闭
function SelectHairstyle_Close()
	this:Hide()
end

--放大
function SelectHairstyle_ZoomIn()
	if g_SelectHairstyle_CameraLevel < 1  or g_SelectHairstyle_CameraLevel > 2 then
		return
	end
	
	g_SelectHairstyle_CameraLevel = g_SelectHairstyle_CameraLevel - 1
	SelectHairstyle_SetCameraPosition()
end

--缩小
function SelectHairstyle_ZoomOut()

	if g_SelectHairstyle_CameraLevel < 0  or g_SelectHairstyle_CameraLevel > 1 then
		return
	end
	
	g_SelectHairstyle_CameraLevel = g_SelectHairstyle_CameraLevel + 1
	SelectHairstyle_SetCameraPosition()
end

function SelectHairstyle_SetCameraPosition()
	if g_SelectHairstyle_CameraLevel > -1 and g_SelectHairstyle_CameraLevel < 3 then
		FakeObj_SetCamera( "Player_Head", SelectHairstyle_CameraHeight, g_SelectHairstyle_CameraPosition[g_SelectHairstyle_CameraLevel].fHeight )
		FakeObj_SetCamera( "Player_Head", SelectHairstyle_CameraDistance, g_SelectHairstyle_CameraPosition[g_SelectHairstyle_CameraLevel].fDistance )
		FakeObj_RestoreCamera( "Player_Head" )
	end
end
----------------------------------------------------------------------------------
-- 旋转人物头像模型（向左)
function Player_Head_Modle_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			SelectHairstyle_Model:RotateBegin(-0.3);
		--向左旋转结束
		else
			SelectHairstyle_Model:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--旋转人物头像模型（向右)
function Player_Head_Modle_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			SelectHairstyle_Model:RotateBegin(0.3);
		--向右旋转结束
		else
			SelectHairstyle_Model:RotateEnd();
		end
	end
end





