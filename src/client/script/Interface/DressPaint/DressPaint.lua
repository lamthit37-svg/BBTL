local MAX_OBJ_DISTANCE = 3.0
local DRESS_POS = -1
local g_NeedMoney = 50000
local g_ObjCared = -1
local g_DressPaint_Frame_UnifiedPosition;
local g_DressPaint_TipsTwice = 0
local g_dressNum 					= 9;
local DressVisualID 			=	{};
local DressNames 					= {};
local DressRate 					= {};
local g_ZiDongState 			= 0			--判断是不是自动染色  默认关闭   0 表示关闭  1 表示开启  作用 1判断取消背包操作  2当服务器返回时 根据这个标示判断是自动染色返回还是染色返回
local g_ZiDongTimerState 	= 0			--自动染色状态  0 关闭  1 开启 2 暂停
local g_RecvGRespState 		= 0			--是否收到服务器染色返回  0.3秒间隔发送一次 但是只有返回后 才继续发   0 表示关闭  1 表示开启  这个要在收到服务器返回后 先判断是否稀有后再置成收到状态 
local g_Zidong_ClickTime 	= 300; 	--300毫秒 模拟点击染色按钮
local g_Rare_Time 				= 1000; --1000毫秒 当rou到稀有颜色  关闭自动timer 开启等待timer
local g_Rare_Count        = 3;
local g_IsFirstAuto				= 1;		--是否是auto第一次请求
local HongYaoShi_POS			= -1;
local g_IsXiYouStop				= 0;
g_DressPaint_TipsBind = 0
local g_DressPaint_YuanbaoPay = 1

-- 隐藏元宝购买按钮
local g_DressPaint_SpecialId = {
[10126879] = 1,
[10126887] = 1,
}

local g_FeiyuDressYRID = {
10126162,--	新锦衣卫嫣然
10126163,--	新锦衣卫红翡
10126164,--	新锦衣卫青蓝
}
--PreLoad
function DressPaint_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_DRESS_PAINT")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("PROGRESSBAR_SHOW")
	this:RegisterEvent("CLOSE_DRESS_PAINT")
	this:RegisterEvent("OPEN_STALL_SALE");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--fjs
	this:RegisterEvent("OPEN_DRESS_PAINT_FITTING"); --打开试衣间
	this:RegisterEvent("SEX_CHANGED");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("OPEN_EQUIP");
	this:RegisterEvent("YIGUI_OPEN")
	this:RegisterEvent("OPEN_DRESS_PAINT")
	this:RegisterEvent("FASHION_DEPOT_OP", false);				-- 华裳阁
end

--OnLoad
function DressPaint_OnLoad() 
	g_DressPaint_Frame_UnifiedPosition=DressPaint_Frame:GetProperty("UnifiedPosition");
end

--OnEvent
function DressPaint_OnEvent(event) 

	-- 读进度条中，不能进行染色
	if ( event == "PROGRESSBAR_SHOW" ) then
		if (this:IsVisible()) then
			DressPaint_OnHiden();
		end
	end

	-- 某些功能互斥，需要关闭该界面
	if ( event == "CLOSE_DRESS_PAINT" ) then
		if (this:IsVisible()) then
			DressPaint_OnHiden();
		end
	end

	-- 开始摆摊，不能进行染色
	if ( event == "OPEN_STALL_SALE" ) then
		if (this:IsVisible()) then
			DressPaint_OnHiden();
		end
	end

	if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 0910281 then
		if this:IsVisible() then 
			DressPaint_OnHiden();
		end
		
		PushEvent( "CLOSE_DRESSPREVIEW") 
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")
		local state = DressReplaceColor : ConditionCheck()
		if state == 0 then
			return
		end
		DressPaint_OK:Disable()										-- 禁用“确定”按钮
		DressPaint_Zidong:SetText("#{YJRS_140613_04}") 
		DressPaint_Zidong:Disable()
		DressPaint_Zidong_Animate:Play(false)
		DressPaint_Fitting_FakeObject : Hide() 
		DressPaint_Text : SetText("") 
		DressPaint_Protect : SetText("") 
		DressPaint_Zidong_ALLChoice:Disable()
		DressPaint_Protect:Hide()
		this:Show()
		Dress_Jian : Hide()
		
		DressPaint_Blank:Show()		
		DressPaint_Info:SetText("#{YJRS_140613_01}")
		
		local xx = Get_XParam_INT(0);
		local objCared = DataPool:GetNPCIDByServerID(xx);
		if objCared == -1 then
			return;
		end
		BeginCareObject_DressPaint(objCared)

		DressPaint_DemandMoney:SetProperty("MoneyNumber", g_NeedMoney)
		local playerMoney = Player:GetData("MONEY")
		DressPaint_SelfMoney:SetProperty("MoneyNumber", playerMoney)
		local playerJZ = Player:GetData("MONEY_JZ")
		DressPaint_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
		
		g_DressPaint_TipsTwice = 0
		g_DressPaint_TipsBind = 0
		
		--yuanbaoPay
		if g_DressPaint_YuanbaoPay == 1 or g_DressPaint_YuanbaoPay == 0 then
			DressPaint_Blank_Queren:SetCheck(g_DressPaint_YuanbaoPay)
		end
		DressPaint_FenYe1:SetProperty("Selected", "True")
		DressPaint_FenYe2:SetProperty("Selected", "False")

	elseif event ==	"OPEN_DRESS_PAINT" then
	
		if(IsWindowShow("DressPreview")) then
			CloseWindow("DressPreview", true);
		end	
		local objCared = tonumber(arg0);
		if this:IsVisible() then 
			DressPaint_OnHiden();
		end
		
		g_DressPaint_Frame_UnifiedPosition = Variable:GetVariable("DressClothPos")
		DressPaint_Frame:SetProperty("UnifiedPosition", g_DressPaint_Frame_UnifiedPosition);
		
		local state = DressReplaceColor : ConditionCheck()
		if state == 0 then
			return
		end
		DressPaint_OK:Disable()										-- 禁用“确定”按钮
		DressPaint_Zidong:SetText("#{YJRS_140613_04}") 
		DressPaint_Zidong:Disable()
		DressPaint_Zidong_Animate:Play(false)
		DressPaint_Fitting_FakeObject : Hide() 
		DressPaint_Text : SetText("") 
		DressPaint_Protect : SetText("") 
		DressPaint_Zidong_ALLChoice:Disable()
		DressPaint_Protect:Hide()
		this:Show()
		Dress_Jian : Hide()
		
		DressPaint_Blank:Show()
		DressPaint_Info:SetText("#{YJRS_140613_01}")
		
		--local objCared = DataPool:GetNPCIDByServerID(_objCared);
		if objCared == -1 then
			return;
		end
		BeginCareObject_DressPaint(objCared)

		DressPaint_DemandMoney:SetProperty("MoneyNumber", g_NeedMoney)
		local playerMoney = Player:GetData("MONEY")
		DressPaint_SelfMoney:SetProperty("MoneyNumber", playerMoney)
		local playerJZ = Player:GetData("MONEY_JZ")
		DressPaint_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
		
		g_DressPaint_TipsTwice = 0
		g_DressPaint_TipsBind = 0
		
		--yuanbaoPay
		if g_DressPaint_YuanbaoPay == 1 or g_DressPaint_YuanbaoPay == 0 then
			DressPaint_Blank_Queren:SetCheck(g_DressPaint_YuanbaoPay)
		end
		DressPaint_FenYe1:SetProperty("Selected", "True")
		DressPaint_FenYe2:SetProperty("Selected", "False")
	-- 染色成功，显示预览效果
	elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 091109 then
		if this:IsVisible() then
			DressPaint_Show()
			g_DressPaint_TipsTwice = 0
			g_DressPaint_TipsBind = 0
		end
  elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 091113 then 
		 DressPaint_ResetZiDongState()
	elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 091114 then 
		 DressPaint_Zidong:SetText("#{YJRS_140613_05}")  
	elseif event ==	"UPDATE_DRESS_PAINT" then
		if arg0 ~= nil and arg1 ~= nil then
			DressPaint_Update(tonumber(arg0), tonumber(arg1))
		end

	elseif event == "OBJECT_CARED_EVENT" then
		if(arg0 ~= nil and tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			DressPaint_OnHiden();
		end

	elseif event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() then
		if(arg0~=nil and tonumber(arg0) == 96) then
			DressPaint_Resume_Equip()
		end

	elseif event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() then
		if( arg0~= nil and -1 == tonumber(arg0)) then
			return
		end

		if (DRESS_POS == tonumber(arg0)) then
			DressPaint_Update(tonumber(arg0), 1)
		end

	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		DressPaint_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		DressPaint_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

	elseif (event == "ADJEST_UI_POS" ) then
		DressPaint_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DressPaint_Frame_On_ResetPos()

	elseif(event == "OPEN_DRESS_PAINT_FITTING") then
		if arg0 == nil then
			return ;
		end

		-- 试衣
		DRESS_POS = tonumber(arg0)
		if DRESS_POS == -1 then
			return ;
		end
		DressReplaceColor : FittingOnDress(DRESS_POS)
		local n_szDressDesc, nRate,MaterBind = DressReplaceColor : GetDressVisualInfo(DRESS_POS)
		if n_szDressDesc == "" or nRate == 0 then
			return
		end

		-- 设置使用哪个模型
		DressPaint_Fitting_FakeObject : SetFakeObject("");
		DressPaint_Fitting_FakeObject : SetFakeObject("DressPaint_Player"); 
		local strdic;
		if nRate == 23000 then
			strdic = ScriptGlobal_Format("#{SZRSYH_120912_10}", n_szDressDesc)
		elseif nRate == 14000 then
			strdic = ScriptGlobal_Format("#{SZRSYH_120912_11}", n_szDressDesc)
		elseif nRate == 1000 then
			strdic = ScriptGlobal_Format("#{SZRSYH_120912_12}", n_szDressDesc)
		elseif nRate == -1 then
			strdic = "#G"..n_szDressDesc
		end
		DressPaint_Text:SetText(strdic)
		
		--dujm
		if g_ZiDongState == 1 then  
			local n_visualID = DressReplaceColor : GetDressVisualID(DRESS_POS)
			if n_visualID == 0 then
				return
			end 
			local _name,ComIdx = DressPaint_Zidong_ALLChoice:GetCurrentSelect()  
			if DressVisualID[ComIdx] == n_visualID then
					DressPaint_SuccDestMode(strdic) 
			elseif  nRate == 1000 and g_IsXiYouStop == 1 then  
					g_IsXiYouStop = 0 
					DressPaint_SuccDestMode(strdic)  
			end   
			g_RecvGRespState = 1 
		end 
		 
	-- 变性
	elseif event == "SEX_CHANGED" and  this:IsVisible() then
		DressPaint_Fitting_FakeObject : Hide();
		DressPaint_Text : Hide()
		Dress_Jian : Hide()
		DressPaint_Fitting_FakeObject : Show();
		DressPaint_Text : Show()
		Dress_Jian : Show()
		DressPaint_Fitting_FakeObject : SetFakeObject("DressPaint_Player");
		
	-- 离开游戏世界
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		DressPaint_OnHiden();
		return
		
	-- 不能和变性同时存在
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20120406) then
		if (this:IsVisible()) then 
			DressPaint_OnHiden();
		end
		
		-- 试衣的时候不能打开角色资料窗口
	elseif ( event == "OPEN_EQUIP" ) then
		if (this:IsVisible()) then 
			DressPaint_OnHiden();
		end
		
	-- 试衣的时候不能打开衣柜
	elseif ( event == "YIGUI_OPEN" ) then
		if (this:IsVisible()) then 
			DressPaint_OnHiden();
		end
	elseif (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1) then --华裳阁
		if (this:IsVisible()) then 
			DressPaint_OnHiden();
		end
	end
	
	-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) then   --时装预览
		if (this:IsVisible()) then
			DressPaint_OnHiden();
			return
		end
	end
end

function DressPaint_OpenDressWash_Clicked() 
	-- 打开时装还原界面
	--PushDebugMessage("OPEN_DRESS_WASH"..g_ObjCared)
	Variable:SetVariable("DressClothPos", DressPaint_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("OPEN_DRESS_WASH", g_ObjCared);
	
end

function DressPaint_Update(Pos, isEquip)
	--PushDebugMessage("PosvPos" ,tostring(Pos))
	--DressPaint_Clear()
	if isEquip == 1 then
		local theAction = EnumAction(Pos, "packageitem")
		if theAction:GetID() ~= 0 then

			--if PlayerPackage:IsLock(Pos) == 1 then   --tt60972 策划改设计，加锁时装也能染色
				--PushDebugMessage("#{SZPR_091023_16}")
				--DressPaint_Clear()
				--return
			--end

			local EquipPoint = LifeAbility:Get_Equip_Point(Pos)
			if EquipPoint ~= 16 then
				PushDebugMessage("#{SZPR_091023_17}")
				--DressPaint_Clear()
				return
			end
			local tableIndex = PlayerPackage : GetItemTableIndex( Pos )
			if tableIndex==g_FeiyuDressYRID[1] or tableIndex==g_FeiyuDressYRID[2] or tableIndex==g_FeiyuDressYRID[3] then
				PushDebugMessage("#{FYYR_200610_32}")
				--DressPaint_Clear()
				return
			end
			--判断是不是可染色时装
			local canPaint = DressReplaceColor:DressCanPaint(Pos)
			if canPaint ~= 1 then
				PushDebugMessage("#{SZPR_091023_18}")
				--DressPaint_Clear()
				return
			end
			if( g_ZiDongState == 0 ) then  
				DressPaint_Clear()
				DRESS_POS = Pos;
--				DressPaint_Zidong:Enable();
				DressPaint_Zidong_ALLChoice_Init()
			end 
			LifeAbility:Lock_Packet_Item(DRESS_POS, 1)
			DressPaint_Object:SetActionItem(theAction:GetID())

			--启用确定按钮
			DressPaint_OK:Enable(); 
			DressPaint_Show();
			Dress_Jian : Show();
			DressPaint_Zidong_ALLChoice:Enable(); 
			
			if g_DressPaint_SpecialId[tableIndex] ~= nil then
				DressPaint_Blank:Hide()
			end
				
			local n_szDressDesc, nRate, MaterBind = DressReplaceColor : GetDressVisualInfo(DRESS_POS)
			local itemname = DataPool:Lua_GetItemNameByIndex(MaterBind)
			local infostr = ScriptGlobal_Format("#{XRSDJ220715_01}", itemname)
			DressPaint_Info:SetText(infostr)
			
			if(IsWindowShow("DressJian") == true) then
				Dress_Jian_Clicked();
			end
			g_DressPaint_TipsTwice = 0
			g_DressPaint_TipsBind = 0
			return

		else
			--DressPaint_Clear()
			PushDebugMessage("#{SZPR_091023_17}")
			return
		end
	else
		PushDebugMessage("#{SZPR_091023_17}")
		--DressPaint_Clear()
		return
	end

end

function DressPaint_Resume_Equip() 
	if g_ZiDongState == 1 then
		PushDebugMessage("#{YJRS_140613_07}") 
		return 
	end 
	DressPaint_Clear()
	if(IsWindowShow("DressJian") == true) then
		PushEvent( "CLOSE_DRESSJIAN_DLG")		
	end
end

function DressPaint_Clear()
	if(DRESS_POS ~= -1) then
		DressPaint_OK:Disable()										-- 禁用“确定”按钮
		DressPaint_Zidong:SetText("#{YJRS_140613_04}") 
		DressPaint_Zidong:Disable(); 
		DressPaint_Zidong_Animate:Play(false)
		DressPaint_Zidong_ALLChoice:Disable()
		DressPaint_Object:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(DRESS_POS, 0)
		DRESS_POS = -1
		-- 清下试衣间数据
		DressReplaceColor:RestoreDressPaintFitting()
		DressPaint_Fitting_FakeObject : Hide();
		DressPaint_Text : SetText("");
		Dress_Jian : Hide() 
		DressPaint_Zidong_ALLChoice_Init() 
		DressVisualID ={};
		DressNames = {};
		DressRate = {}; 
		
		DressPaint_Blank:Show()
		DressPaint_Info:SetText("#{YJRS_140613_01}")
		
		if g_ZiDongState == 1  then  				--- count timer  kill  没写呢 
  		KillTimer("DressPaint_countEvent()") 
  		PushDebugMessage("#{YJRS_140613_17}")
  	end   	
  	if g_ZiDongTimerState == 2  and g_Rare_Count < 3 then  				--- count timer  kill  没写呢 
  		KillTimer("DressRare_TimerEvent()") 
  	end   	
		DressPaint_ResetZiDongState()
	end
end

function DressPaint_OnHiden() 
	SetDefaultMouse();
	StopCareObject_DressPaint(objCared)
	DressPaint_Clear()  
	DressPaint_Fitting_FakeObject : SetFakeObject("");
	DressPaint_Text : SetText("");
	Dress_Jian : Hide() 
	this:Hide() 
	if(IsWindowShow("DressJian") == true) then
		PushEvent( "CLOSE_DRESSJIAN_DLG")		
	end
	return
end

-- 
function DressPaint_Blank_Queren_Clicked() 
	g_DressPaint_YuanbaoPay = DressPaint_Blank_Queren:GetCheck();
	-- PushDebugMessage("DressPaint_Blank_Queren_Clicked"..g_DressPaint_YuanbaoPay) 
end

------------------------------------------------------
--
--	确定
--
function DressPaint_OK_Clicked() 
	if g_ZiDongState == 1 then
		PushDebugMessage("#{YJRS_140613_07}") 
		return 
	end 

	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < g_NeedMoney then
		PushDebugMessage("#{RXZS_090804_11}")
		return
	end
	
	local isDressBind = GetItemBindStatus(DRESS_POS)
	
	local n_szDressDesc, nRate,MaterBind = DressReplaceColor : GetDressVisualInfo(DRESS_POS)
	if g_DressPaint_TipsBind == 0 and isDressBind == 0 and PlayerPackage:CountAvailableItemByIDTable(MaterBind) > 0 then
		PushEvent( "DRESSPAINT_BINDDRESS", MaterBind)
		return
	end
	if nRate == 1000 and g_DressPaint_TipsTwice == 0 then 
		PushEvent( "DRESSPAINT_SELECTSERVER", n_szDressDesc )
		g_DressPaint_TipsTwice = 1
	else
		
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnDressPaint")
		Set_XSCRIPT_ScriptID(830001)
		Set_XSCRIPT_Parameter(0, DRESS_POS)
		Set_XSCRIPT_Parameter(1, g_DressPaint_YuanbaoPay)
		Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end

end

--点击自动染色事件
function DressPaint_Zidong_Clicked()			--自动开启  开启timer事件
	  
	 if g_ZiDongState == 0 then 
		if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
			PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
			return
		end 
		--判断电话密保和二级密码保护2012.6.12-LIUBO
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then
			return
		end
	
		local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
		if selfMoney < g_NeedMoney then
			PushDebugMessage("#{YJRS_140613_11}")
			return
		end 
		local isDressBind = GetItemBindStatus(DRESS_POS)
		local n_szDressDesc, nRate, MaterBind = DressReplaceColor : GetDressVisualInfo(DRESS_POS)
		if g_DressPaint_TipsBind == 0 and isDressBind == 0 and PlayerPackage:CountAvailableItemByIDTable(MaterBind) > 0 then
			PushEvent( "DRESSPAINT_BINDDRESS", MaterBind)
			return
		end
		if nRate == 1000 and g_DressPaint_TipsTwice == 0 then 
			PushEvent( "DRESSPAINT_SELECTSERVER", n_szDressDesc )
			g_DressPaint_TipsTwice = 1
			return
		end
		g_IsFirstAuto       = 1
		  
		g_ZiDongState 			= 1			
    g_ZiDongTimerState	= 1
    g_RecvGRespState    = 1 	
    SetTimer("DressPaint","DressPaint_ZiDong_TimerEvent()", 300)
    DressPaint_Zidong_ALLChoice:Disable() 
  else 
  	PushDebugMessage("#{YJRS_140613_17}")
  	DressPaint_ResetZiDongState()
	end
	
end
 
function DressPaint_ZiDong_TimerEvent()	--模拟点击染色按钮  0.3秒一次  
	if g_ZiDongTimerState == 1  and g_RecvGRespState == 1 then 
 	   -- 判断是否为安全时间2012.6.12-LIUBO
		if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
			PushDebugMessage("#{ZYXT_120528_16}")
			DressPaint_ResetZiDongState()
			return
		end  
		--判断电话密保和二级密码保护2012.6.12-LIUBO
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then
			DressPaint_ResetZiDongState()
			return
		end 
		local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
		if selfMoney < g_NeedMoney then
			PushDebugMessage("#{YJRS_140613_14}")
			DressPaint_ResetZiDongState()
			return
		end  

		local destVisualID = -1
		local _name,ComIdx = DressPaint_Zidong_ALLChoice:GetCurrentSelect()
		if ComIdx ~= nil and ComIdx > 0 and DressVisualID[ComIdx] ~= nil then
			destVisualID = DressVisualID[ComIdx]
		end

		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAutoDressPaint")
		Set_XSCRIPT_ScriptID(830001)
		Set_XSCRIPT_Parameter(0, DRESS_POS)
		Set_XSCRIPT_Parameter(1, g_IsFirstAuto)			--是否是第一次自动染色  为了区别显示不同内容  1 代表第一次 0不是
		Set_XSCRIPT_Parameter(2, destVisualID)
		Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT() 
		g_RecvGRespState    = 0 
		g_IsFirstAuto       = 0
 	end 
end


--rou出稀有时装 启动Timer
function DressPaint_GetRareDress() 
	g_ZiDongTimerState = 2  
	g_Rare_Count = 3	
	SetTimer("DressPaint","DressRare_TimerEvent()", g_Rare_Time)
	
end
--rou出稀有时装Timer回调函数
function DressRare_TimerEvent() 
	local tmpStr = ScriptGlobal_Format("#{YJRS_140613_06}" ,g_Rare_Count)  
	DressPaint_Protect:SetText(tmpStr);
	g_Rare_Count = g_Rare_Count - 1 
	if g_Rare_Count == -1 then 
		KillTimer("DressRare_TimerEvent()")
		g_Rare_Count = 3
		g_ZiDongTimerState = 1   
		DressPaint_Protect:SetText("");
	end
end 
--事件函数
------------------------------------------------------
--
--	打开试衣间
--
function DressPaint_Show()
		-- 先清空当前试衣间的数据
	DressReplaceColor:RestoreDressPaintFitting();

	-- 打开
	DressReplaceColor:OpenDressPaintFitting( DRESS_POS )

	DressPaint_Fitting_FakeObject : Show();
	DressPaint_Text : Show();
end

------------------------------------------------------
--
--	关心NPC
--
function BeginCareObject_DressPaint(objCaredId)
	g_ObjCared = objCaredId
	this:CareObject(g_ObjCared, 1, "DressPaint")
end


function StopCareObject_DressPaint(objCaredId)
	this:CareObject(g_ObjCared, 0, "DressPaint")
	g_ObjCared = -1
end

function DressPaint_Frame_On_ResetPos()
  DressPaint_Frame:SetProperty("UnifiedPosition", g_DressPaint_Frame_UnifiedPosition);
end

----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左)
--
function DressPaint_Fitting_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			DressPaint_Fitting_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			DressPaint_Fitting_FakeObject:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右)
--
function DressPaint_Fitting_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			DressPaint_Fitting_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			DressPaint_Fitting_FakeObject:RotateEnd();
		end
	end
end

function Dress_Jian_Clicked()
	DressReplaceColor :DressOpenDressJian(DRESS_POS);
end
--重置自动状态 1.点击停止 关闭窗口时
function DressPaint_ResetZiDongState() 	
		local _name,ComIdx = DressPaint_Zidong_ALLChoice:GetCurrentSelect()
		if ComIdx > 0 then 
			DressPaint_Zidong:SetText("#{YJRS_140613_04}") 
			DressPaint_Zidong:Disable()
			DressPaint_Zidong_Animate:Play(false)
			DressPaint_Zidong_ALLChoice:Enable() 
			DressPaint_Zidong_ALLChoice:SetText("#{YJRS_140613_03}")--选择目标染色风格  
			--DressPaint_Zidong_ALLChoice:SetCurrentSelect(-1)
		end 
	  --DressPaint_Zidong:Enable();
	  DressPaint_Zidong:SetText("#{YJRS_140613_04}") 
	  if g_ZiDongTimerState == 2  and g_Rare_Count < 3 then  				--- count timer  kill  没写呢 
  		KillTimer("DressRare_TimerEvent()") 
  	end
  	DressPaint_Protect:SetText(""); 
  	if g_ZiDongState == 1  then 
  		KillTimer("DressPaint_ZiDong_TimerEvent()") 
  	end  

  	g_ZiDongState 			= 0			
    g_ZiDongTimerState	= 0
    g_RecvGRespState    = 0 

end	

--初始化自动状态 并构造数据
function DressPaint_Zidong_ALLChoice_Init() 
	DressPaint_Zidong_ALLChoice:ResetList()  	
	DressPaint_Zidong_ALLChoice:SetText("#{YJRS_140613_03}")--选择目标染色风格  
	--DressPaint_Zidong_ALLChoice:SetCurrentSelect(0); 
  if ( DRESS_POS == -1 ) then  
  	DressVisualID 	= {};
		DressNames 			= {};
		DressRate 			= {};  
		DressPaint_Zidong_ALLChoice:Disable();
		return
	end

	DressReplaceColor :StoreDressType(DRESS_POS); 
	for i=1 ,g_dressNum-1 do
		local nVisual,ndesc,nRate = DressReplaceColor:GetDressDesc(i-1) 
		DressVisualID[i] = nVisual; 
		if nRate == 23000 then
			DressNames[i] = ScriptGlobal_Format("#{SZRSYH_120912_07}", ndesc);
		elseif nRate == 14000 then
			DressNames[i] = ScriptGlobal_Format("#{SZRSYH_120912_08}", ndesc)
		elseif nRate == 1000 then
			DressNames[i] = ScriptGlobal_Format("#{SZRSYH_120912_09}", ndesc)
		elseif nRate == -1 then
			DressNames[i] = ndesc
		end
		DressRate[i]=nRate 
	end  
	for i = 1 , g_dressNum-1 do 
		DressPaint_Zidong_ALLChoice:AddTextItem(DressNames[i] ,i) 
	end  
 	DressPaint_Zidong_ALLChoice:AddTextItem("#{YJRS_140613_23}" ,g_dressNum) 	 	 
	DressPaint_Zidong_ALLChoice:Enable() 
	
end
--染出目标颜色
function DressPaint_SuccDestMode(strDressDesc)
	local Msg = ScriptGlobal_Format("#{YJRS_140613_15}", strDressDesc) 
	PushDebugMessage(Msg)
	DressPaint_ResetZiDongState()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnSuccDressPaint")
	Set_XSCRIPT_ScriptID(830001) 
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()  
end
--目标ComList选择事件
function DressPaint_DestMode_Changed() 
	if g_ZiDongState == 1 then
		PushDebugMessage("#{YJRS_140613_07}") 
		return
	end 
	local _name,ComIdx = DressPaint_Zidong_ALLChoice:GetCurrentSelect()
	if ComIdx == g_dressNum then
		 g_IsXiYouStop = 1
	else
		 g_IsXiYouStop = 0
	end 
	
	if ComIdx > 0 then 
		DressPaint_Zidong:SetText("#G#{YJRS_140613_04}") 
		DressPaint_Zidong:Enable()
		DressPaint_Zidong_Animate:Play(true)
	else
		DressPaint_Zidong:SetText("#{YJRS_140613_04}") 
		DressPaint_Zidong:Disable() 
		DressPaint_Zidong_Animate:Play(false)
	end 
	local n_visualID = DressReplaceColor : GetDressVisualID(DRESS_POS) 
	if n_visualID == 0 then
		DressPaint_Zidong:SetText("#{YJRS_140613_04}") 
		DressPaint_Zidong:Disable()
		DressPaint_Zidong_Animate:Play(false)
		return  
	end
	
	local _name,ComIdx = DressPaint_Zidong_ALLChoice:GetCurrentSelect()
 
	if DressVisualID[ComIdx] == n_visualID then 
			DressPaint_Zidong:SetText("#{YJRS_140613_04}") 
			DressPaint_Zidong:Disable()
			DressPaint_Zidong_Animate:Play(false)
			PushDebugMessage("#{YJRS_140613_24}") 
	end  
	local n_szDressDesc, nRate, MaterBind = DressReplaceColor : GetDressVisualInfo(DRESS_POS) 
	if nRate == 1000 and ComIdx == g_dressNum then 
			DressPaint_Zidong:SetText("#{YJRS_140613_04}") 
			DressPaint_Zidong:Disable()
			DressPaint_Zidong_Animate:Play(false)
			PushDebugMessage("#{YJRS_140613_24}") 
	end  
end
