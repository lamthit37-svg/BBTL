--活动时装预览间 界面
--!!!reloadscript =DressPreview
local g_DressPreview_Frame_UnifiedPosition = ""

local g_Distance = 1
local g_Distance_Ori = 2
local g_Distance_Max = 4

local g_dressColorMax = 9

--暂时只有一个动作按钮
local g_ActionNumMax = 3

local g_previewDressDesc = {}
local g_previewDressVisualID = {}
local g_previewDressRate = {}

local g_ActionButtonList = {}
local g_ActionButtonImgList = {}
local g_DressNameText = ""
local g_DressButton = ""
local g_HairButton = ""
local g_FaceButton = ""

local g_CameraPosition =
{
	--女性相关位置
	[0] = {{fHeight = 0.85, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
	       {fHeight = 1.55, fDistance = 2.5, fPitch=0.20, fXOffset= 0 }, {fHeight = 1.55, fDistance = 1.7, fPitch=0.20, fXOffset= 0 }},
	--男性相关位置
	[1] = {{fHeight = 0.85, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
	       {fHeight = 1.65, fDistance = 2.7, fPitch=0.28, fXOffset= 0 }, {fHeight = 1.70, fDistance = 1.9, fPitch=0.28, fXOffset= 0 }},
}

local g_CameraPosition_IV =
{
	--女性相关位置
	[0] = {{fHeight = 0.85, fDistance = 12, fPitch=0.2, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.2, fPitch=0.2, fXOffset= 0 },
	       {fHeight = 1.55, fDistance = 2.5, fPitch=0.10, fXOffset= 0 }, {fHeight = 1.62, fDistance = 1.8, fPitch=0.10, fXOffset= 0 }},
	--男性相关位置
	[1] = {{fHeight = 0.85, fDistance = 12, fPitch=0.28, fXOffset= 0 }, {fHeight = 0.85, fDistance = 7.5, fPitch=0.28, fXOffset= 0 }, 
	       {fHeight = 1.70, fDistance = 2.7, fPitch=0.05, fXOffset= 0 }, {fHeight = 1.78, fDistance = 1.9, fPitch=0.05, fXOffset= 0 }},
}


local g_SpecialFashionCamera = {
-- 桃花醉
[1] = {startid = 10126405, endid = 10126420, fHeight = 1.9, fDistance = 20, fPitch = -1, timecount = 21000},
-- 千里江山
[2] = {startid = 10126295, endid = 10126310, fHeight = -1, fDistance = -1, fPitch = -1, timecount = 42000},
}

local g_NumberingFashionCamera = { fHeight = 1.9, fDistance = 20, timecount1 = 9000, timecount2 = 10000 }

local g_sexButton = ""
local g_sexButtonInfo = {
	[0] = { imgH = "set:DressPreview01 image:DressPreview_Male_Hover", imgN = "set:DressPreview01 image:DressPreview_Male_Normal", imgP = "set:DressPreview01 image:DressPreview_Male_Pushed"  },
	[1] = { imgH = "set:DressPreview01 image:DressPreview_Female_Hover", imgN = "set:DressPreview01 image:DressPreview_Female_Normal", imgP = "set:DressPreview01 image:DressPreview_Female_Pushed"  },
}

local g_previewParam = 1
local g_previewDress = 10126180
local g_previewDressViusal = 0
local g_previewFace = 3
local g_previewHair = 3
local g_curSex = 0
local g_curDressColorType = 0   ---时装类型 0默认 1可染色
local g_curDressActionType = 0   ---时装类型 0无动作 1有动作

local g_selectColorIdx = g_dressColorMax


--PreLoad
function DressPreview_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_DRESSPREVIEW")
	this:RegisterEvent("CLOSE_DRESSPREVIEW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	---this:RegisterEvent("SEX_CHANGED");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	this:RegisterEvent("FASHION_DEPOT_OP", false);				-- 华裳阁
	this:RegisterEvent("OPEN_STALL_SALE", false);
	this:RegisterEvent("MODELID_CHANGE", false);
	this:RegisterEvent("OPEN_EQUIP", false);
	this:RegisterEvent("YIGUI_OPEN", false);
	
end

--OnLoad
function DressPreview_OnLoad() 
	g_DressPreview_Frame_UnifiedPosition = DressPreview_Frame:GetProperty("UnifiedPosition");
	
	g_ActionButtonList = {
		DressPreview_DressAction_Btn,
		DressPreview_DressAction_Btn2,
		DressPreview_DressAction_Btn3,
	}	
	
	g_ActionButtonImgList = {
		DressPreview_DressAction_1,
		DressPreview_DressAction_2,
		DressPreview_DressAction_3,
	}		
	
	g_sexButton = DressPreview_GenderChange_Btn
	g_DressNameText	= DressPreview_DressName
	g_DressButton = DressPreview_DressBtn
	g_HairButton = DressPreview_HairBtn
	g_FaceButton = DressPreview_FaceBtn
	
end

--OnEvent
function DressPreview_OnEvent(event) 

	if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 120203161 then
		if this:IsVisible() then 
			DressPreview_OnHiden();
		end
		
		if( tonumber( IsInStall() ) == 1 ) then
			PushDebugMessage("#{ETQWF_131106_4}")			--摆摊状态无法进行这种操作。
			return
		end		
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")
		
		local dress = Get_XParam_INT(0)
		local hair = Get_XParam_INT(1)
		local face = Get_XParam_INT(2)
		if dress ~= -1 or hair ~= -1 or face~= -1 then
			g_previewDress = dress
			g_previewHair = hair
			g_previewFace = face
			local isOK = DressPreview_Show()
			if isOK > 0 then
				this:Show()
			else
				this:Hide()
			end
		end

	elseif event ==	"OPEN_DRESSPREVIEW" then
		if this:IsVisible() then
			return
		end
		
		if tonumber(IsInStall()) == 1 then
			PushDebugMessage("#{ETQWF_131106_4}")			--摆摊状态无法进行这种操作。
			return
		end
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")
		local dress = tonumber(arg0)
		local hair = tonumber(arg1)
		local face = tonumber(arg2)
		if dress ~= -1 or hair ~= -1 or face ~= -1 then
			g_previewDress = dress
			g_previewHair = hair
			g_previewFace = face
			local isOK = DressPreview_Show()
			if isOK > 0 then
				this:Show()
			else
				this:Hide()
			end			
			DressPreview_Frame:SetForce()
		end
		
	elseif (event == "OPEN_STALL_SALE" ) or ( event == "MODELID_CHANGE" ) then
		if (this:IsVisible()) then 
			DressPreview_OnHiden();
		end
	
	elseif (event == "ADJEST_UI_POS" ) then
		DressPreview_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DressPreview_Frame_On_ResetPos()

		
	-- 离开游戏世界
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		DressPreview_OnHiden();
		return
		
	-- 不能和变性同时存在
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20120406) then
		if (this:IsVisible()) then 
			DressPreview_OnHiden();
		end
	
		-- 试衣的时候不能打开角色资料窗口
	elseif ( event == "OPEN_EQUIP" ) then
		if (this:IsVisible()) then 
			DressPreview_OnHiden();
		end
		
	-- 试衣的时候不能打开衣柜
	elseif ( event == "YIGUI_OPEN" ) then
		if (this:IsVisible()) then 
			DressPreview_OnHiden();
		end
	elseif (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1) then --华裳阁
		if (this:IsVisible()) then 
			DressPreview_OnHiden();
		end
	end
	
	if (event == "CLOSE_DRESSPREVIEW") then --华裳阁
		if (this:IsVisible()) then 
			DressPreview_OnHiden();
		end
	end
end



function DressPreview_Clear()

	local isUpdateOK = DressPreview_UpdateObj(0)
	SetDefaultMouse()
	DressPreview_FakeObject:DetachWindowEx()
	g_previewFace = -1
	g_previewHair = -1
	g_previewDress = -1

end

function DressPreview_OnHiden() 

	DressPreview_Clear()  
	this:Hide() 

end

function DressPreview_Frame_On_ResetPos()
  DressPreview_Frame:SetProperty("UnifiedPosition", g_DressPreview_Frame_UnifiedPosition);
end


function DressPreview_Show()
	
	DressPreview_Init()
	
	DressPreview_UpdateCurVisualID()

	local isUpdateOK = DressPreview_UpdateObj(1)
	if isUpdateOK > 0 then
		DressPreview_UpdateCamera()
		return 1
	end

	return -1
end

function DressPreview_UpdateCurVisualID()
	if g_curDressColorType == 1 then
		g_previewDressViusal = g_previewDressVisualID[g_selectColorIdx]
	end
end

function DressPreview_Init()
	
	g_curSex = Player:GetMySex()
	DressPreview_ResetCamera()
	g_DressButton:Hide()
	g_FaceButton:Hide()
	g_HairButton:Hide()
	g_DressNameText:Hide()
	g_DressNameText:SetText( "" )
	--PushDebugMessage("g_previewFace = "..g_previewFace.."   g_previewHair ="..g_previewHair.."  g_previewDress ="..g_previewDress)

	local theActionButton_Dress = DataPool:CreateActionItemForShow(g_previewDress, 1)
	if theActionButton_Dress:GetID() ~= 0 then
		g_DressButton:Enable()
		g_DressButton:SetActionItem(theActionButton_Dress:GetID());
		g_DressButton:Show();
		
		local dressName = DataPool:Lua_GetItemNameByIndex(g_previewDress)
		if dressName ~= nil then
			local str = ScriptGlobal_Format("#{HDSZYL_210325_04}",dressName)
			g_DressNameText:SetText( str )
			g_DressNameText:Show()
		end
		
	end	
	
	local nExteriorFaceID = g_previewFace
	local charFaceId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid,afterchangesex = Exterior:LuaFnGetFaceStylePreviewInfo(nExteriorFaceID,g_curSex)
	if charFaceId >= 0 then
		g_FaceButton:Enable()
		g_FaceButton:SetProperty("Empty", "FALSE")
		g_FaceButton:SetProperty("UseDefaultTooltip", "True")
		IconFile = GetIconFullName(IconFile)
		g_FaceButton:SetProperty("NormalImage", IconFile)
		g_FaceButton:SetProperty("HoverImage", IconFile)
		g_FaceButton:SetToolTip(StyleName)
		g_FaceButton:Show()
	end

	local nExteriorHairID = g_previewHair
	local charHairId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid,afterchangesex = Exterior:LuaFnGetHairStylePreviewInfo(nExteriorHairID,g_curSex)
	if charHairId >= 0 then
		g_HairButton:Enable()
		g_HairButton:SetProperty("Empty", "FALSE")
		g_HairButton:SetProperty("UseDefaultTooltip", "True")
		IconFile = GetIconFullName(IconFile)
		g_HairButton:SetProperty("NormalImage", IconFile)
		g_HairButton:SetProperty("HoverImage", IconFile)
		g_HairButton:SetToolTip(StyleName)
		g_HairButton:Show()
	end
	DressPreview_ColorList:Show()
	DressPreview_ColorList_Text:Show()
	DressPreview_ColorList:ResetList()
	g_previewDressViusal = Exterior:LuaFnGetPreviewDressStdVisualID(g_previewDress)
	
	g_curDressColorType = 0
	local isDressCanPaint = Exterior:LuaFnDressCanPaint(g_previewDress)
	if isDressCanPaint > 0 then
		g_curDressColorType = 1
		Exterior:LuaFnInitPreviewDressData(g_previewDress)
		
		DressPreview_ColorList:Enable()
		
		
		local visualID0,desc0,rate0 = Exterior:LuaFnGetPreviewDressDesc(g_dressColorMax - 1)
		g_previewDressVisualID[1] = visualID0;
		g_previewDressDesc[1] = desc0
		g_previewDressRate[1] = -1;		
		
		for i=1 ,g_dressColorMax - 1 do
			local visualID,desc,rate = Exterior:LuaFnGetPreviewDressDesc(i-1)
			
			g_previewDressVisualID[i+1] = visualID;
			if rate == 23000 then
				g_previewDressDesc[i+1] = ScriptGlobal_Format("#{SZRSYH_120912_07}", desc);
			elseif rate == 14000 then
				g_previewDressDesc[i+1] = ScriptGlobal_Format("#{SZRSYH_120912_08}", desc)
			elseif rate == 1000 then
				g_previewDressDesc[i+1] = ScriptGlobal_Format("#{SZRSYH_120912_09}", desc)
			elseif rate == -1 then
				g_previewDressDesc[i+1] = desc
			end
			g_previewDressRate[i+1] = rate;
		end
		
		--DressPreview_ColorList:AddTextItem(g_previewDressDesc[g_dressColorMax], 1)
		for i = 1, g_dressColorMax do
			DressPreview_ColorList:AddTextItem(g_previewDressDesc[i], i)
		end
		DressPreview_ColorList:SetCurrentSelect(0)
		g_selectColorIdx = 1
		
	else
		local str = "#{HDSZYL_210325_03}"
		DressPreview_ColorList:Disable()
		DressPreview_ColorList:SetText(str)
		----DressPreview_ColorList:AddTextItem(str, 1)
		----DressPreview_ColorList:SetCurrentSelect(0)
		
	end
	
	if g_previewDress == -1 then 
		DressPreview_ColorList:Hide()
		DressPreview_ColorList_Text:Hide()
		g_DressNameText:Hide()
	end
	
	DressPreview_ButtonEnable()
	
	DressPreview_UpdateActionButton()
	
	g_sexButton:SetProperty("HoverImage", g_sexButtonInfo[g_curSex].imgH)
	g_sexButton:SetProperty("NormalImage", g_sexButtonInfo[g_curSex].imgN)
	g_sexButton:SetProperty("PushedImage", g_sexButtonInfo[g_curSex].imgP)
	

		
end

function DressPreview_UpdateActionButton()
	
	
	for i = 1, table.getn(g_ActionButtonList) do
		g_ActionButtonList[i]:Hide()
	end
	
	for i = 1, table.getn(g_ActionButtonImgList) do
		g_ActionButtonImgList[i]:Hide()
	end
		
	local ActionNum = FashionActionUI:GetFashionActionActionNum(g_previewDress, g_previewDressViusal)

	if ActionNum > g_ActionNumMax then
		ActionNum = g_ActionNumMax
	end
	
	if ActionNum >=1 then
		for i = 1, ActionNum do
			g_ActionButtonList[i]:Show()
			g_ActionButtonImgList[i]:Show()
		end
		g_curDressActionType = 1
	else
		--g_ActionButtonList[1]:Show()
		--g_ActionButtonImgList[1]:Show()
	end
	
	if ActionNum == 1 then
		g_ActionButtonImgList[1]:Hide()
	end	
	
end


function DressPreview_ChangeSex()
	if g_curSex == 0 or g_curSex == 1 then
		g_curSex = 1 - g_curSex
	else 
		g_curSex = Player:GetMySex()
	end
	g_sexButton:SetProperty("HoverImage", g_sexButtonInfo[g_curSex].imgH)
	g_sexButton:SetProperty("NormalImage", g_sexButtonInfo[g_curSex].imgN)
	g_sexButton:SetProperty("PushedImage", g_sexButtonInfo[g_curSex].imgP)
	
	local nExteriorFaceID = g_previewFace
	local charFaceId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid,afterchangesex = Exterior:LuaFnGetFaceStylePreviewInfo(nExteriorFaceID,g_curSex)

		if charFaceId >= 0 then 			
			g_FaceButton:Enable()
			g_FaceButton:SetProperty("Empty", "FALSE")
			g_FaceButton:SetProperty("UseDefaultTooltip", "True")
			IconFile = GetIconFullName(IconFile)
			g_FaceButton:SetProperty("NormalImage", IconFile)
			g_FaceButton:SetProperty("HoverImage", IconFile)
			g_FaceButton:SetToolTip(StyleName)
			g_FaceButton:Show()
		else
			g_FaceButton:Hide()
		end


	local nExteriorHairID = g_previewHair
	local charHairId,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,menpaiid,afterchangesex = Exterior:LuaFnGetHairStylePreviewInfo(nExteriorHairID,g_curSex)

		if charHairId >= 0 then 	
			g_HairButton:Enable()
			g_HairButton:SetProperty("Empty", "FALSE")
			g_HairButton:SetProperty("UseDefaultTooltip", "True")
			IconFile = GetIconFullName(IconFile)
			g_HairButton:SetProperty("NormalImage", IconFile)
			g_HairButton:SetProperty("HoverImage", IconFile)
			g_HairButton:SetToolTip(StyleName)
			g_HairButton:Show()
		else
			g_HairButton:Hide()
		end

	

	DressPreview_ButtonEnable()
	DressPreview_UpdateActionButton()
	local isUpdateOK = DressPreview_UpdateObj(1)
	if isUpdateOK > 0 then
		DressPreview_UpdateCamera()
	end
end


--时装动作
function DressPreview_OnAction(nIndex) 
	if not nIndex then 
		return
	end
	
	if g_curDressActionType ~= 1 then
		PushDebugMessage("#{HDSZYL_210325_01}")  --该时装没有配套时装动作。
		for i = 1, table.getn(g_ActionButtonList) do
			g_ActionButtonList[i]:Hide()
		end
		for i = 1, table.getn(g_ActionButtonImgList) do
			g_ActionButtonImgList[i]:Hide()
		end
	end
	
	local nHaveReSet = 0
	for i = 1, table.getn(g_SpecialFashionCamera) do
		if g_previewDress >= g_SpecialFashionCamera[i].startid and g_previewDress <= g_SpecialFashionCamera[i].endid then
			local fHeight, fDistance, fPitch = DressPreview_FakeObject:GetCameraEx()
			if g_SpecialFashionCamera[i].fDistance ~= -1 then
				fDistance = g_SpecialFashionCamera[i].fDistance
			end
			if g_SpecialFashionCamera[i].fHeight ~= -1 then
				fHeight = g_SpecialFashionCamera[i].fHeight
			end
			if g_SpecialFashionCamera[i].fPitch ~= -1 then
				fPitch = g_SpecialFashionCamera[i].fPitch
			end
			DressPreview_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
			DressPreview_ButtonDisable()		
			SetTimer("DressPreview","DressPreview_ActionEnd()", g_SpecialFashionCamera[i].timecount)
			
			nHaveReSet = 1
		end		
	end
				
	if nHaveReSet == 0 then
		local nFashionNumber = Exterior:LuaFnGetNumberingFashionInfo(g_previewDress, "Number")
		if nFashionNumber ~= nil and nFashionNumber > 0 then
			local fHeight, fDistance, fPitch = DressPreview_FakeObject:GetCameraEx()
			
			fHeight = g_NumberingFashionCamera.fHeight
			fDistance = g_NumberingFashionCamera.fDistance
			
			DressPreview_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)	
			DressPreview_ButtonDisable()	
			
			local timecount = g_NumberingFashionCamera.timecount1
			if nIndex == 2 then
				timecount = g_NumberingFashionCamera.timecount2
			end
			
			SetTimer("DressPreview","DressPreview_ActionEnd()", timecount)
		end
	end
	
	Exterior:LuaFnDressPreviewPlayAction(g_previewDress, g_previewDressViusal, nIndex - 1)
end

function DressPreview_ButtonEnable()
	DressPreview_Model_Plus:Enable()
	DressPreview_Model_Subtract:Enable()
	DressPreview_Model_TurnLeft:Enable()
	DressPreview_Model_TurnRight:Enable()
end

function DressPreview_ButtonDisable()
	DressPreview_Model_Plus:Disable()
	DressPreview_Model_Subtract:Disable()
	DressPreview_Model_TurnLeft:Disable()
	DressPreview_Model_TurnRight:Disable()
end

function DressPreview_ActionEnd()
	KillTimer("DressPreview_ActionEnd()");
	DressPreview_ButtonEnable()	
	DressPreview_UpdateCamera()
end

function DressPreview_ColorChanged()

	local szName, curSelectIdx = DressPreview_ColorList:GetCurrentSelect()
	g_selectColorIdx = curSelectIdx
	DressPreview_UpdateCurVisualID()
	DressPreview_UpdateActionButton()
	local isUpdateOK = DressPreview_UpdateObj(1)
	if isUpdateOK > 0 then
		DressPreview_UpdateCamera()
	end

end
--模型
function DressPreview_UpdateObj(param)   --1预览 0取消
	
	---PushDebugMessage("DressPreview_UpdateObj")
	---PushDebugMessage("param = "..param.."   visualID ="..g_previewDressViusal.."  face ="..g_previewFace.."  hair ="..g_previewHair.." sex = "..g_curSex)
		
	DressPreview_FakeObject:DetachWindowEx()
	DressPreview_FakeObject:AttachWindowEx("DressPreview_Player")
	local isCanPreview = Exterior:LuaFnUpdateDressPreviewPlayerData(g_previewDress, g_previewDressViusal, g_previewFace, g_previewHair, g_curSex, param)
	
	DressPreview_ActionEnd()		
	
	if isCanPreview >0 then
		return 1
	end

	return -1
	
end


--左转
function DressPreview_FakeObject_TurnLeft(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		DressPreview_FakeObject:RotateBeginEx("DressPreview_Player", -0.3)
	else
		DressPreview_FakeObject:RotateEndEx()
	end
	
end

--右转
function DressPreview_FakeObject_TurnRight(idx)
	
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		DressPreview_FakeObject:RotateBeginEx("DressPreview_Player", 0.3)
	else
		DressPreview_FakeObject:RotateEndEx()
	end
	
end



--缩小
function DressPreview_FakeObject_ZoomOut()

	if g_Distance == 1 then
		return
	end	
	g_Distance = g_Distance - 1	
	DressPreview_UpdateCamera()
	
end

--放大
function DressPreview_FakeObject_ZoomIn()

	if g_Distance == g_Distance_Max then
		return
	end
	g_Distance = g_Distance + 1	
	DressPreview_UpdateCamera()
	
end

function DressPreview_UpdateCamera()

	if g_curSex ~= 0 and g_curSex ~= 1 then 
		g_curSex = GetMySelfRaceId()
	end
		
	if g_Distance < 1 or g_Distance > g_Distance_Max then
		g_Distance = 2
	end
	
	local isIVMode = LuaFnGetCurModelState()
	local cameraInfo = g_CameraPosition
	if isIVMode == 1 then
		cameraInfo = g_CameraPosition_IV
	end
	
	local fHeight, fDistance, fPitch = DressPreview_FakeObject:GetCameraEx()
	local fXOffset = 0	
	
	fHeight = cameraInfo[g_curSex][g_Distance].fHeight
	fDistance = cameraInfo[g_curSex][g_Distance].fDistance
	fPitch = cameraInfo[g_curSex][g_Distance].fPitch
	fXOffset = cameraInfo[g_curSex][g_Distance].fXOffset
	DressPreview_FakeObject:SetCameraEx(fHeight, fDistance, fPitch, fXOffset)	
	
end

function DressPreview_ResetCamera()

	local sex = GetMySelfRaceId()
	if sex ~= 0 and sex ~= 1 then 
		return
	end
		
	g_Distance = 2
	
	local fHeight, fDistance, fPitch = DressPreview_FakeObject:GetCameraEx()
	fHeight = g_CameraPosition[sex][g_Distance].fHeight
	fDistance = g_CameraPosition[sex][g_Distance].fDistance
	fPitch = g_CameraPosition[sex][g_Distance].fPitch
	DressPreview_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
	
end
