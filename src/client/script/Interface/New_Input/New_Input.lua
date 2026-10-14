-- 默认选择方式
local g_SelectType = -1

-- 盘出方式
local SALETYPE_MONEY = 0
local SALETYPE_YUANBAO = 1

-- 界面的默认相对位置
local g_New_Input_Frame_UnifiedXPosition
local g_New_Input_Frame_UnifiedYPosition

-- npc关注
local objCared = -1
local MAX_OBJ_DISTANCE = 3.0

--===============================================
-- PreLoad()
--===============================================
function New_Input_PreLoad()
	this:RegisterEvent("OPEN_NEW_INPUT")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("CLOSE_NEW_INPUT")
	this:RegisterEvent("PS_CLOSE_SHOP_MAG")
end

--===============================================
-- OnLoad()
--===============================================
function New_Input_OnLoad()
	-- 保存界面的默认相对位置
	g_New_Input_Frame_UnifiedXPosition	= New_InputFrame : GetProperty("UnifiedXPosition")
	g_New_Input_Frame_UnifiedYPosition	= New_InputFrame : GetProperty("UnifiedYPosition")
end

--===============================================
-- OnEvent
--===============================================
function New_Input_OnEvent(event)
	-- 打开界面
	if(event == "OPEN_NEW_INPUT") then
		this:Show()			
		-- npc关注
		objCared = PlayerShop:GetNpcId()
		this:CareObject(objCared, 1, "New_Input")
		-- 设置界面
		New_Input_ChangeMode(SALETYPE_MONEY)--默认金币盘出方式
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		New_Input_ResetPos()
	end
	
	-- 游戏分辨率发生了变化
	if (event == "VIEW_RESOLUTION_CHANGED") then
		New_Input_ResetPos()
	end
	
	-- 离开npc关闭界面
	if ( event == "OBJECT_CARED_EVENT" )   then
		if(tonumber(arg0) ~= objCared) then
			return
		end		
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			New_Input_Clicked_Cancel()
		end	
	end
	
	-- 关闭界面
	if( event == "CLOSE_NEW_INPUT")	 then
		New_Input_Clicked_Cancel()
	end
	
	-- 关闭界面
	if( event == "PS_CLOSE_SHOP_MAG")	 then
		New_Input_Clicked_Cancel()
	end

end

--===============================================
-- 隐藏
--===============================================
function New_Input_OnHiden()
	--变量重置
	g_SelectType = -1
	--控件清空
	New_Input_Clear()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function New_Input_ResetPos()
	New_InputFrame : SetProperty("UnifiedXPosition", g_New_Input_Frame_UnifiedXPosition)
	New_InputFrame : SetProperty("UnifiedYPosition", g_New_Input_Frame_UnifiedYPosition)
end

--===============================================
-- 清空
--===============================================
function New_Input_Clear()
	--文字内容清空
	New_InputGold:SetText("")
	New_InputSilver:SetText("")
	New_InputCopperCoin:SetText("")
	New_InputText3:SetText("")
	--光标默认位置
	New_InputGold:SetProperty("DefaultEditBox", "False")
	New_InputSilver:SetProperty("DefaultEditBox", "False")	
	New_InputCopperCoin:SetProperty("DefaultEditBox", "False")
	New_InputText3:SetProperty("DefaultEditBox", "False")	
	--确认按钮默认禁用
	New_InputAccept:Disable()	
end

--===============================================
-- 确定
--===============================================
function New_Input_Clicked_Accept()
	--参数检测
	if g_SelectType ~= SALETYPE_MONEY and g_SelectType ~= SALETYPE_YUANBAO then
		return
	end

	--金币盘出
	if g_SelectType == SALETYPE_MONEY then
		local szGold = New_InputGold:GetText()
		local szSilver = New_InputSilver:GetText()
		local szCopperCoin = New_InputCopperCoin:GetText()
		--在程序里头再检测输入字符的有效性和数值
		local bAvailability,nMoney = Bank:GetInputMoney(szGold,szSilver,szCopperCoin)		
		--???什么情况下失败需要再定
		if(bAvailability == true) then
			--输入不合法
			if (tonumber(nMoney) < 1) then
				New_InputGold:SetText("")
				New_InputSilver:SetText("")
				New_InputCopperCoin:SetText("")
				New_InputGold:SetProperty("DefaultEditBox", "True")
				PushDebugMessage("盘出商店价格不能小于1铜，请重新输入")
				return
			elseif (tonumber(nMoney) > 100000000) then
				New_InputGold:SetText("")
				New_InputSilver:SetText("")
				New_InputCopperCoin:SetText("")
				New_InputGold:SetProperty("DefaultEditBox", "True")
				PushDebugMessage("盘出商店价格不能超过10000金，请重新输入")
				return
			end
			--确认盘出
			PlayerShop:Transfer("info", "sale", nMoney, g_SelectType)
			--关闭界面
			New_Input_Clicked_Cancel()
		end
	elseif g_SelectType == SALETYPE_YUANBAO then
		local szYuanbao = New_InputText3:GetText()
		--输入不合法
		if (tonumber(szYuanbao) < 1) then
			New_InputText3:SetText("")
			New_InputText3:SetProperty("DefaultEditBox", "True")		
			PushDebugMessage("盘出商店价格不能小于1元宝，请重新输入")
			return
		elseif (tonumber(szYuanbao) > 100000) then
			New_InputText3:SetText("")
			New_InputText3:SetProperty("DefaultEditBox", "True")		
			PushDebugMessage("盘出商店价格不能超过100000元宝，请重新输入")
			return
		end
		--确认盘出
		PlayerShop:Transfer("info", "sale", tonumber(szYuanbao), g_SelectType)
		--关闭界面
		New_Input_Clicked_Cancel()		
	end
end

--===============================================
-- 取消
--===============================================
function New_Input_Clicked_Cancel()
	--界面隐藏
	this:Hide()
	--取消关心
	this:CareObject(objCared, 0, "New_Input")
end

--===============================================
-- 输入改变
--===============================================
function New_Input_ChangeMoney()	
	--金币盘出
	if g_SelectType == SALETYPE_MONEY then
		local szGold = New_InputGold:GetText()
		local szSilver = New_InputSilver:GetText()
		local szCopperCoin = New_InputCopperCoin:GetText()		
		if szGold == "" and szSilver == "" and szCopperCoin == "" then
			New_InputAccept:Disable()
		else
			New_InputAccept:Enable()
		end
	--元宝盘出
	elseif g_SelectType == SALETYPE_YUANBAO then
		local szYuanbao = New_InputText3:GetText()	
		if szYuanbao == "" then
			New_InputAccept:Disable()
		else
			New_InputAccept:Enable()
		end
	end
end

--===============================================
-- 选项改变
--===============================================
function New_Input_ChangeMode(type)
	--参数检测
	if type ~= SALETYPE_MONEY and type ~= SALETYPE_YUANBAO then
		return
	end
	
	--模式设置
	if g_SelectType == type then
		return
	end
	g_SelectType = type
	
	--控件清空
	New_Input_Clear()
		
	--状态修改
	if g_SelectType == SALETYPE_MONEY then
		--单选按钮
		New_Input_Bind2:SetCheck(0)
		New_Input_Bind1:SetCheck(1)
		--光标默认位置
		New_InputGold:SetProperty("DefaultEditBox", "True")		
	elseif g_SelectType == SALETYPE_YUANBAO then
		--单选按钮
		New_Input_Bind1:SetCheck(0)
		New_Input_Bind2:SetCheck(1)
		--光标默认位置
		New_InputText3:SetProperty("DefaultEditBox", "True")
	end
end
