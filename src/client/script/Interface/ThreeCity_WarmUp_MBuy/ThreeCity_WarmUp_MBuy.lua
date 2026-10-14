--2022Q3新天外预热活动-ypl

local g_ThreeCity_WarmUp_MBuy_UnifiedPosition

local g_ThreeCity_WarmUp_MBuy_SinglePrice = 0--50 --单价：每个炎黄信物需要的元宝数（此数，服务器下发吧，省的两边都写了）
local g_ThreeCity_WarmUp_MBuy_LimitNum = 0 --9999 --上限：每个玩家，不论有多少元宝，最多可以购买的数量（此数，服务器下发吧，省的两边都写了）
local g_ThreeCity_WarmUp_MBuy_ReduceNum = 0 --购买数量：默认是0，可输入购买数量
local g_ThreeCity_WarmUp_MBuy_MaxYuanBao = 0 --拥有元宝
local g_ThreeCity_WarmUp_MBuy_HaveNum = 0 --已拥有炎黄信物的数量(服务器下发过来的)

--local g_objCared = -1

function ThreeCity_WarmUp_MBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_YUANBAO");
end

function ThreeCity_WarmUp_MBuy_OnLoad()	
	g_ThreeCity_WarmUp_MBuy_UnifiedPosition = ThreeCity_WarmUp_MBuy_Frame:GetProperty("UnifiedPosition")

	g_ThreeCity_WarmUp_MBuy_SinglePrice = 0
	g_ThreeCity_WarmUp_MBuy_LimitNum = 0
	g_ThreeCity_WarmUp_MBuy_ReduceNum = 0
	g_ThreeCity_WarmUp_MBuy_MaxYuanBao = 0
	g_ThreeCity_WarmUp_MBuy_HaveNum = 0
end

function ThreeCity_WarmUp_MBuy_OnEvent(event)
	local nSpecKaJi89 = Player:GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 or nSpecKaJi89 == 1 then
		this:Hide()	
		return
	end
	
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99819702 ) then
		--拥有的元宝
		g_ThreeCity_WarmUp_MBuy_MaxYuanBao = Get_XParam_INT(0)
		--已拥有炎黄信物的数量
		g_ThreeCity_WarmUp_MBuy_HaveNum = Get_XParam_INT(1)
		--上限：每个玩家，不论有多少元宝，最多可以购买的数量（此数，服务器下发吧，省的两边都写了）
		g_ThreeCity_WarmUp_MBuy_LimitNum = Get_XParam_INT(2)
		--单价：每个炎黄信物需要的元宝数（此数，服务器下发吧，省的两边都写了）
		g_ThreeCity_WarmUp_MBuy_SinglePrice = Get_XParam_INT(3) 	
		--默认界面：购买数量为0
		ThreeCity_WarmUp_MBuy_Update( 0 )
		--输入框调整
		ThreeCity_WarmUp_MBuy_InputNum:SetProperty("DefaultEditBox", "True");
		ThreeCity_WarmUp_MBuy_InputNum:SetProperty("MaxTextLength", "4")
		ThreeCity_WarmUp_MBuy_InputNum:SetText(tostring(0));
		ThreeCity_WarmUp_MBuy_InputNum:SetSelected( 0, -1 );	
		--npc关心事件
        -- g_objCared = DataPool:GetNPCIDByServerID(Get_XParam_INT(4))
		-- this:CareObject(g_objCared, 1, "ThreeCity_WarmUp_MBuy");		
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99819703 ) then
		ThreeCity_WarmUp_MBuy_OnHidden()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateMyUI" )
			Set_XSCRIPT_ScriptID(998197)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif (event == "ADJEST_UI_POS" ) then
		ThreeCity_WarmUp_MBuy_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ThreeCity_WarmUp_MBuy_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ThreeCity_WarmUp_MBuy_OnHidden()
    elseif ( event == "OBJECT_CARED_EVENT" and this:IsVisible() ) then
		-- if(tonumber(arg0) ~= g_objCared) then
			-- return
		-- end
		-- -- 如果和NPC的距离大于一定距离或者被删除，自动关闭
        -- if(arg1 == "distance" and tonumber(arg2)>3 or arg1=="destroy") then
            -- ThreeCity_WarmUp_MBuy_OnHidden()
        -- end
		-- --取消关心
		-- this:CareObject(g_objCared, 0, "ThreeCity_WarmUp_MBuy");
	elseif( event == "UPDATE_YUANBAO" and this:IsVisible() ) then
		local num = tonumber(ThreeCity_WarmUp_MBuy_InputNum:GetText());
		g_ThreeCity_WarmUp_MBuy_MaxYuanBao = Player:GetData("YUANBAO");
		ThreeCity_WarmUp_MBuy_Update(  num  )
	end
	
end

function ThreeCity_WarmUp_MBuy_On_ResetPos()
	ThreeCity_WarmUp_MBuy_Frame:SetProperty("UnifiedPosition", g_ThreeCity_WarmUp_MBuy_UnifiedPosition);
end

----------------------------------------
--功能：控制3项数字的显示
--1、购买道具数量
--2、需要元宝数
--3、拥有元宝数
--参数：
--1、元宝数量（实际拥有）
--2、购买数量（本次想要购买的数量）
--说明：
--两个参数，是经过修正后的，可直接使用，
--修正逻辑在调用前执行
-----------------------------------------
function ThreeCity_WarmUp_MBuy_Update(  curbuycnt  )

	if(nil == curbuycnt) or(curbuycnt and curbuycnt < 0) then
		curbuycnt = 0
	end
	
	--元宝数量
	local nYuanBao = g_ThreeCity_WarmUp_MBuy_MaxYuanBao
	
	--购买数量
	g_ThreeCity_WarmUp_MBuy_ReduceNum = curbuycnt
	
	--输入框调整
	--ThreeCity_WarmUp_MBuy_InputNum:SetProperty("DefaultEditBox", "True");
	--ThreeCity_WarmUp_MBuy_InputNum:SetText(tostring(g_ThreeCity_WarmUp_MBuy_ReduceNum))

	--需要元宝
	local needYuaBao = g_ThreeCity_WarmUp_MBuy_ReduceNum*g_ThreeCity_WarmUp_MBuy_SinglePrice
	ThreeCity_WarmUp_MBuy_Price_Yuanbao:SetText(ScriptGlobal_Format("#{XTWYR_220729_123}",needYuaBao))
	
	--拥有元宝
	if nYuanBao < needYuaBao then
		ThreeCity_WarmUp_MBuy_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{XTWYR_220729_125}",nYuanBao))
		ThreeCity_WarmUp_MBuy_Buy:Disable()
	else
		ThreeCity_WarmUp_MBuy_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{XTWYR_220729_126}",nYuanBao))
		ThreeCity_WarmUp_MBuy_Buy:Enable()
	end

end

---------------------------------------------------
--功能：通过输入框写入购买数量
--说明：
--写入后，按照实际元宝数以及道具上限，将动态调整
--这个数字为合理数值并将这个合理数值传给
--ThreeCity_WarmUp_MBuy_Update(curbuycnt)
----------------------------------------------------
function ThreeCity_WarmUp_MBuy_TextChanged()

	local num = tonumber(ThreeCity_WarmUp_MBuy_InputNum:GetText())
	
	--不合理的值：按0处理
	if(nil == num or(num and num < 0)) then
		ThreeCity_WarmUp_MBuy_Update(  0  )
		PushDebugMessage("#{XTWYR_220729_132}")
		return
	end
	
	--刷新界面：利用修正后的数据，刷新界面
	ThreeCity_WarmUp_MBuy_Update(  num  )
	
end

---------------------------------------------------
--功能：自动计算并填入，可以购买的最大数量
----------------------------------------------------
function ThreeCity_WarmUp_MBuy_CalMax()
	local num = math.floor(tonumber(g_ThreeCity_WarmUp_MBuy_MaxYuanBao)/tonumber(g_ThreeCity_WarmUp_MBuy_SinglePrice))

	if g_ThreeCity_WarmUp_MBuy_LimitNum ~= 0 then
		if num > (g_ThreeCity_WarmUp_MBuy_LimitNum-g_ThreeCity_WarmUp_MBuy_HaveNum) then
			num = g_ThreeCity_WarmUp_MBuy_LimitNum-g_ThreeCity_WarmUp_MBuy_HaveNum
		end
	end
	
	ThreeCity_WarmUp_MBuy_InputNum:SetText(tostring(num))
	
	--刷新界面：利用修正后的数据，刷新界面
	ThreeCity_WarmUp_MBuy_Update(  num  )
end

---------------------------------------------------
--功能：确认购买
----------------------------------------------------
function ThreeCity_WarmUp_MBuy_OK_Clicked()

	local nSpecKaJi89 = Player:GetData("SPECKAJI89") 
	if KaJi:LuaFnIsKaJiServer() == 1 or nSpecKaJi89 == 1 then
		this:Hide()	
		return
	end
	
	local text = ThreeCity_WarmUp_MBuy_InputNum:GetText()
	local num = 0
	if text == "" then
		num = 0
	else
		num = tonumber(text)
	end	
	if(num == nil or num <= 0) then
		PushDebugMessage("#{XTWYR_220729_132}")
		return
	end	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoExchange" )
		Set_XSCRIPT_ScriptID(998197)
		Set_XSCRIPT_Parameter(0,tonumber(num))
		Set_XSCRIPT_Parameter(1,1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

---------------------------------------------------
--功能：关闭界面、取消购买
----------------------------------------------------
function ThreeCity_WarmUp_MBuy_Close_Clicked()
	ThreeCity_WarmUp_MBuy_OnHidden()
end

---------------------------------------------------
--功能：关闭界面
----------------------------------------------------
function ThreeCity_WarmUp_MBuy_OnHidden()
	--取消关心
	-- this:CareObject(g_objCared, 0, "ThreeCity_WarmUp_MBuy");
	-- g_objCared = -1
	this:Hide()
end

