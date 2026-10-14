local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_Index;
local g_bFrom = 0
local   g_DescriptionOuter= {
						[1] = "庭院桌",
						[2] = "庭院凳",
						[3] = "喷泉",
						[4] = "影壁",
						[5] = "风灯",
						[6] = "鼎",
						[7] = "奇石",
						[8] = "树木",
						[9] = "植栽",
						[10] = "玩物",
						[11] = "栏杆",				
						[12] = "花草",		
						[13] = "奇珍",								
																}
local  g_DescriptionInner= {
						[1] = "床帐",
						[2] = "居室桌",
						[3] = "条案",
						[4] = "茶几",
						[5] = "椅",
						[6] = "居室凳",
						[7] = "柜架",
						[8] = "屏风",
						[9] = "灯烛",
						[10] = "装饰",
						[11] = "隔断",
						[12] = "地毯",
						[13] = "瑰宝",			
																	
																}
function BieYeFurnitureShow_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("SCENE_TRANSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("BIEYE_OPEN_FURNITURE_BANK")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("SHOWFURNITURE")

	--仓库刷新
	this:RegisterEvent("SHOWFURNITUREUPDATE")
	this:RegisterEvent("CLOSE_BIEYEFURNITURE_SHOW")
	this:RegisterEvent("SHOWFURNITURE_INBANK")
end

function BieYeFurnitureShow_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BieYeFurnitureShow_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BieYeFurnitureShow_Frame:GetProperty("UnifiedYPosition");
	g_Index = 0
end



function BieYeFurnitureShow_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BieYeFurnitureShow_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BieYeFurnitureShow_ResetPos()
	elseif( event == "SCENE_TRANSED" ) then
		BieYeFurnitureShow_Close()
	elseif( event == "CLOSE_BIEYEFURNITURE_SHOW" ) then
		BieYeFurnitureShow_Close()		
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then
		local nType = Get_XParam_INT(0)
		
		if nType == 30 then --打开界面
			BieYeFurnitureShow_Close()
		end
		this:Hide()
	elseif(event == "BIEYE_OPEN_FURNITURE_BANK") then
			BieYeFurnitureShow_Close()
	elseif( event == "SHOWFURNITURE" ) then

		g_Index = tonumber(arg0)


		g_bFrom = tonumber(arg1)
		if(IsWindowShow("BieYeFurnitureTransfer")) then
			CloseWindow("BieYeFurnitureTransfer",true)
		end
		BieYeFurnitureShow_Show()
		BieYeFurnitureShow_FakeObject:SetFakeObject("");
		BieYeFurniture:SetFurnitureModel(g_Index)
		BieYeFurnitureShow_FakeObject:SetFakeObject("BieYeFurniture");

		local bInner = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,3)
		local nComfort = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,6)
		--local strDescType = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,1)
		local strName = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,2)
		local nQuality = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,7)
		local nCount = BieYeFurniture:GetFurCntInCangku(g_Index)
		local nCountLimit = BieYeFurniture:GetBieYeFurnitureLimitByBieYeLevel()
		local strCount = ScriptGlobal_Format("#{BYFUR_160531_87}", nCount,nCountLimit)
		local strDescType  = ""
		
		local isJiaoHu = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,9)
		if isJiaoHu == -1 then
			BieYeFurnitureShow_Jiaohu_Text:Hide()
		else
			BieYeFurnitureShow_Jiaohu_Text:Show()
		end

		if g_bFrom == 0 then
			BieYeFurnitureShow_OK:SetProperty("Visible", "True");
		else
			BieYeFurnitureShow_OK:SetProperty("Visible", "False");		
		end

		if nCount == 0 then
			BieYeFurnitureShow_OK:Disable()
		else
			BieYeFurnitureShow_OK:Enable()	
		end
		local nPutCount = BieYeUI:GetFurnitureObjNum(g_Index)
		local nPutCountLimit = BieYeFurniture:GetBieYePutFurnitureLimitByBieYeLevel(bInner)
		local strPutCount = ScriptGlobal_Format("#{BYFUR_160531_88}", nPutCount,nPutCountLimit)

		local str =""
		local Mode_text = ""
		if bInner == 1 then
		--居室
			strDescType = "#{BYFUR_160531_292}"
			str = ScriptGlobal_Format("#{BYFUR_160531_95}", nComfort)
			--BieYeFurnitureShow_Mode_Text:SetText("#{BYFUR_160531_211}")
			local BaseType = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,5)
			local strPutCountToolTips = ScriptGlobal_Format("#{BYFUR_160531_213}",g_DescriptionInner[BaseType])	

		else
		--庭院
			strDescType = "#{BYFUR_160531_291}"
		    str = ScriptGlobal_Format("#{BYFUR_160531_84}", nComfort)
			--BieYeFurnitureShow_Mode_Text:SetText("#{BYFUR_160531_203}")	
			local BaseType = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,5)
			local strPutCountToolTips = ScriptGlobal_Format("#{BYFUR_160531_205}", g_DescriptionOuter[BaseType])	

		end
		--local str = "#{BYFUR_160531_84}" .. nComfort
		--BieYeFurnitureShow_Mode_Text:SetText(str)
		BieYeFurnitureShow_DragTitle:SetText("#gFF0FA0"..strName)
		BieYeFurnitureShow_Right_Txet1:SetToolTip("#{BYFUR_160531_264}")
		BieYeFurnitureShow_Right_Txet1:SetText(strDescType)
		if nQuality == 0 then
		--普通
			BieYeFurnitureShow_Right_Txet2:SetText("#{BYFUR_160531_85}")
		else
		--稀有
			BieYeFurnitureShow_Right_Txet2:SetText("#{BYFUR_160531_86}")
		end
		BieYeFurnitureShow_Right_Txet4:SetToolTip("#{BYFUR_160531_203}")
		BieYeFurnitureShow_Right_Txet2:SetToolTip("#{BYFUR_160531_265}")
		--BieYeFurnitureShow_Right_Txet3:SetText(strCount)
		--BieYeFurnitureShow_Right_Txet4:SetText(strPutCount)
		BieYeFurnitureShow_Right_Txet4:SetText(str)
	elseif( event == "SHOWFURNITURE_INBANK" ) then
		g_Index = tonumber(arg0)

		BieYeFurnitureShow_Show()
		BieYeFurnitureShow_FakeObject:SetFakeObject("");
		BieYeFurniture:SetFurnitureModel(g_Index)
		BieYeFurnitureShow_FakeObject:SetFakeObject("BieYeFurniture");

		local bInner = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,3)
		local nComfort = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,6)
		--local strDescType = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,1)
		local strName = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,2)
		local nQuality = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,7)
		local nCount = BieYeFurniture:GetFurCntInCangku(g_Index)
		local nCountLimit = BieYeFurniture:GetBieYeFurnitureLimitByBieYeLevel()
		local strCount = ScriptGlobal_Format("#{BYFUR_160531_87}", nCount,nCountLimit)
		local strDescType  = ""
		
		local isJiaoHu = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,9)
		if isJiaoHu == -1 then
			BieYeFurnitureShow_Jiaohu_Text:Hide()
		else
			BieYeFurnitureShow_Jiaohu_Text:Show()
		end

		BieYeFurnitureShow_OK:SetProperty("Visible", "False");		


		if nCount == 0 then
			BieYeFurnitureShow_OK:Disable()
		else
			BieYeFurnitureShow_OK:Enable()	
		end
		local nPutCount = BieYeUI:GetFurnitureObjNum(g_Index)
		local nPutCountLimit = BieYeFurniture:GetBieYePutFurnitureLimitByBieYeLevel(bInner)
		local strPutCount = ScriptGlobal_Format("#{BYFUR_160531_88}", nPutCount,nPutCountLimit)

		local str =""
		local Mode_text = ""
		if bInner == 1 then
		--居室
			strDescType = "#{BYFUR_160531_292}"
			str = ScriptGlobal_Format("#{BYFUR_160531_95}", nComfort)
			--BieYeFurnitureShow_Mode_Text:SetText("#{BYFUR_160531_211}")
			local BaseType = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,5)
			local strPutCountToolTips = ScriptGlobal_Format("#{BYFUR_160531_213}",g_DescriptionInner[BaseType])	

		else
		--庭院
			strDescType = "#{BYFUR_160531_291}"
		    str = ScriptGlobal_Format("#{BYFUR_160531_84}", nComfort)
			--BieYeFurnitureShow_Mode_Text:SetText("#{BYFUR_160531_203}")	
			local BaseType = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,5)
			local strPutCountToolTips = ScriptGlobal_Format("#{BYFUR_160531_205}", g_DescriptionOuter[BaseType])	

		end
		--local str = "#{BYFUR_160531_84}" .. nComfort
		--BieYeFurnitureShow_Mode_Text:SetText(str)
		BieYeFurnitureShow_DragTitle:SetText("#gFF0FA0"..strName)
		BieYeFurnitureShow_Right_Txet1:SetToolTip("#{BYFUR_160531_264}")
		BieYeFurnitureShow_Right_Txet1:SetText(strDescType)
		if nQuality == 0 then
		--普通
			BieYeFurnitureShow_Right_Txet2:SetText("#{BYFUR_160531_85}")
		else
		--稀有
			BieYeFurnitureShow_Right_Txet2:SetText("#{BYFUR_160531_86}")
		end
		BieYeFurnitureShow_Right_Txet4:SetToolTip("#{BYFUR_160531_203}")
		BieYeFurnitureShow_Right_Txet2:SetToolTip("#{BYFUR_160531_265}")
		--BieYeFurnitureShow_Right_Txet3:SetText(strCount)
		--BieYeFurnitureShow_Right_Txet4:SetText(strPutCount)
		BieYeFurnitureShow_Right_Txet4:SetText(str)
	elseif( event == "SHOWFURNITUREUPDATE" ) then
		BieYeFurnitureShow_Close()
--[[	PushDebugMessage("test")
		local nType,nLevel = BieYeUI:GetFurnitureTypeByItemID(g_Index)
		if nType < 0 then
			return
		end

		local nContainerIndex = BieYeFurniture:GetContainerIndexByItemTableIndex(g_Index)
		if nContainerIndex < 0 then
			BieYeFurnitureShow_Close()
			return 
		end
		
	
		BieYeFurnitureShow_FakeObject:SetFakeObject("");
		BieYeFurnitureShow_FakeObject:SetFakeObject("BieYeFurniture");
		BieYeFurnitureShow_ConditionsCheck()
		this:Show()		
		
		local bInner = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,3)
		local nComfort = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,6)
		local strDescType = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,1)
		local strName = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,2)
		local nQuality = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,7)
		local nCount = BieYeFurniture:GetFurCntInCangku(g_Index)
		local nCountLimit = BieYeFurniture:GetBieYeFurnitureLimitByBieYeLevel()
		local strCount = ScriptGlobal_Format("#{BYFUR_160531_87}", nCount,nCountLimit)
		
		if g_bFrom == 0 then
			BieYeFurnitureShow_OK:SetProperty("Visible", "True");
		else
			BieYeFurnitureShow_OK:SetProperty("Visible", "False");		
		end
		
		if nCount == 0 then
			BieYeFurnitureShow_OK:Disable()
		else
			BieYeFurnitureShow_OK:Enable()	
		end

		local nPutCount = BieYeUI:GetFurnitureObjNum(g_Index)
		local nPutCountLimit = BieYeFurniture:GetBieYePutFurnitureLimitByBieYeLevel(bInner)
		local strPutCount = ScriptGlobal_Format("#{BYFUR_160531_88}", nPutCount,nPutCountLimit)
		local str
		
		if bInner == 1 then
		--居室
			str = ScriptGlobal_Format("#{BYFUR_160531_95}", nComfort)
			--BieYeFurnitureShow_Mode_Text:SetText("")	
		else
		--庭院
		    str = ScriptGlobal_Format("#{BYFUR_160531_84}", nComfort)
			--BieYeFurnitureShow_Mode_Text:SetText("#{BYFUR_160531_203}")	
		end
		--local str = "#{BYFUR_160531_84}" .. nComfort
		--BieYeFurnitureShow_Mode_Text:SetText(str)
		BieYeFurnitureShow_DragTitle:SetText(strName)
		BieYeFurnitureShow_Right_Txet1:SetText(strDescType)
		if nQuality == 0 then
		--普通
			BieYeFurnitureShow_Right_Txet2:SetText("#{BYFUR_160531_85}")
		elseif nQuality == 1 then
		--稀有
			BieYeFurnitureShow_Right_Txet2:SetText("#{BYFUR_160531_86}")
		end
		--BieYeFurnitureShow_Right_Txet3:SetText(strCount)
		--BieYeFurnitureShow_Right_Txet4:SetText(strPutCount)
		BieYeFurnitureShow_Right_Txet4:SetText(str)
		--]]
	end
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeFurnitureShow_ResetPos()
	BieYeFurnitureShow_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BieYeFurnitureShow_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BieYeFurnitureShow_OpenFame()
	--打开大的UI

end
function BieYeFurnitureShow_TurnRight(nLeft)
	--打开大的UI
		--打开大的UI
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(nLeft == 1) then
			BieYeFurnitureShow_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			BieYeFurnitureShow_FakeObject:RotateEnd();
		end
	end

end
function BieYeFurnitureShow_TurnLeft(nRight)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(nRight == 1) then
			BieYeFurnitureShow_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			BieYeFurnitureShow_FakeObject:RotateEnd();
		end
	end
end


function BieYeFurnitureShow_Put()
	--打开大的UI
	local nCount = BieYeFurniture:GetFurCntInCangku(g_Index)
	if nCount > 0 then 
		BieYeUI:MoveFurnitureForItemId(g_Index)
		BieYeFurnitureShow_Close()
	end
end
function BieYeFurnitureShow_Log()
	--打开大的UI
	PushEvent("BIEYEFURNITUREBANK_LOG")
end


function BieYeFurnitureShow_Show()

	if(IsWindowShow("BieYeFurnitureCreate")) then
	  CloseWindow("BieYeFurnitureCreate", true);
	end

	local bConditons = BieYeFurnitureShow_ConditionsCheck()
	if bConditons == 1 then 
		this:Show()		
	end

end
function BieYeFurnitureShow_Close()
	--打开大的UI
	BieYeFurnitureShow_FakeObject:SetFakeObject("");	
	this:Hide()
end
function BieYeFurnitureShow_ConditionsCheck()
	--打开大的UI


	if Player:GetLevel() < 50 then
		PushDebugMessage("#{BYFUR_160531_83}");
		return 0
	end
	BieYeFurnitureShow_Close()	
	this:Hide()
	return 1
end

