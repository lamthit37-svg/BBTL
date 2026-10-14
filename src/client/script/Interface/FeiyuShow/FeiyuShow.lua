local MAX_OBJ_DISTANCE = 3.0
local DRESS_POS = -1
local DRESSITEM_POS = -1

local g_FeiyuDressID = 10126161--	新锦衣卫时装

local g_FeiyuItemID = {
38004801,
38004802,
38004803
}
local g_FeiyuNewDressID = {
10126162,--	新锦衣卫嫣然
10126163,--	新锦衣卫红翡
10126164,--	新锦衣卫青蓝
}
local g_FeiyuDressStr = {
"#{FYYR_200610_34}",
"#{FYYR_200610_35}",
"#{FYYR_200610_36}",
}
local g_NeedMoney = 50000
local g_ObjCared = -1
local g_FeiyuShow_Frame_UnifiedPosition;

local FeiyuDressVisualID 	= {};
local FeiyuDressNames 			= {};
local FeiyuDressRate 			= {};
local g_dressNum 					= 9;


--PreLoad
function FeiyuShow_PreLoad()
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_FEIYUDRESS_PAINT",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
--	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)

	this:RegisterEvent("PROGRESSBAR_SHOW")
	this:RegisterEvent("OPEN_STALL_SALE");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("FEIYUDRESS_PAINT_OK",false)
	--fjs
	this:RegisterEvent("OPEN_DRESS_PAINT_FITTING",false); --打开试衣间
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("OPEN_EQUIP",false);
	this:RegisterEvent("YIGUI_OPEN",false)
	this:RegisterEvent("OPEN_DRESS_PAINT",false)
	this:RegisterEvent("FASHION_DEPOT_OP", false);				-- 华裳阁
	this:RegisterEvent("FEIYUSHOW_WINDOW", true)
	this:RegisterEvent("OPEN_SPECIALDRESSPAINT", false)
end

--OnLoad
function FeiyuShow_OnLoad() 
	g_FeiyuShow_Frame_UnifiedPosition=FeiyuShow_Frame:GetProperty("UnifiedPosition");
end

--OnEvent
function FeiyuShow_OnEvent(event)
	-- 读进度条中，不能进行染色
	if ( event == "PROGRESSBAR_SHOW" ) then
		if (this:IsVisible()) then
			FeiyuShow_OnHide();
		end
	end

	-- 开始摆摊，不能进行染色
	if ( event == "OPEN_STALL_SALE" ) then
		if (this:IsVisible()) then
			FeiyuShow_OnHide();
		end
	end

	if event == "FEIYUSHOW_WINDOW" then
		if arg0~=nil and tonumber(arg0)==-1 then
			FeiyuShow_OnHide();
			return
		end
		FeiyuShow_Init()
		local targetId = tonumber(arg0);
		CloseWindow("DressPaint")
--		FeiyuShow_Btn:Disable()										-- 禁用“确定”按钮
--		FeiyuShow_FakeObject : Hide()
		this:Show()

		
		local objCared = DataPool:GetNPCIDByServerID(targetId);
		if objCared == -1 then
			return;
		end
		BeginCareObject_FeiyuShow(objCared)

	elseif event ==	"UPDATE_FEIYUDRESS_PAINT" then
		if arg0 ~= nil and arg1 ~= nil  then
			FeiyuShow_Update(tonumber(arg0), tonumber(arg1))
		end

	elseif event == "OBJECT_CARED_EVENT" then
		if(arg0 ~= nil and tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			FeiyuShow_OnHide();
		end

	elseif event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() then
		if(arg0~=nil and tonumber(arg0) == 105) then
			FeiyuShow_DressClear()
		elseif (arg0~=nil and tonumber(arg0) == 106) then
			FeiyuShow_ItemClear()
		end

--	elseif event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() then
--		if( arg0 == nil or -1 == tonumber(arg0)) then
--			return
--		end
--
--		if (DRESS_POS == tonumber(arg0)) then
--			FeiyuShow_Update(1,tonumber(arg0))
--		elseif (DRESSITEM_POS == tonumber(arg0)) then
--			FeiyuShow_Update(2,tonumber(arg0))
--		end
	elseif event == "FEIYUDRESS_PAINT_OK" then
		FeiyuShow_OKClick(0)
	elseif (event == "ADJEST_UI_POS" ) then
		FeiyuShow_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FeiyuShow_Frame_On_ResetPos()
	
	-- 离开游戏世界
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		FeiyuShow_OnHide();
		return

	-- FakeObject模型界面互斥
	elseif ( event == "OPEN_EQUIP" ) or												-- 角色资料界面
		( event ==	"OPEN_DRESS_PAINT" ) or
		( event == "OPEN_YB_SHOP_FITTING" )or			--元宝商店试衣间
		 ( event == "OPEN_DRESS_PAINT_FITTING" ) or					-- 时装染色试衣间
		 ( event == "OPEN_DRESS_ENCHASE_FITTING" ) or	-- 时装镶嵌试衣间
		 ( event == "YIGUI_OPEN") or			-- 衣柜
		  (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1)  or --华裳阁
		   (event == "OPEN_SPECIALDRESSPAINT" and tonumber(arg0) >= 0) then
		if (this:IsVisible()) then 
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
			this:Hide();
		end
	end

end

function FeiyuShow_Update(Oper, Pos)
	--FeiyuShow_Clear()
	
	if Oper==0 then
		--鼠标右键
		local tableIndex = PlayerPackage : GetItemTableIndex( Pos )
		if tableIndex==g_FeiyuDressID or tableIndex==g_FeiyuNewDressID[1] or tableIndex==g_FeiyuNewDressID[2] or tableIndex==g_FeiyuNewDressID[3] then
			FeiyuShow_PutInDress(Pos)
		elseif tableIndex==g_FeiyuItemID[1] or tableIndex==g_FeiyuItemID[2] or tableIndex==g_FeiyuItemID[3] then
			FeiyuShow_PutInItem(Pos)
		else
			PushDebugMessage("#{FYYR_200610_19}")
		end
	elseif Oper==1 then
		--拖拽
		FeiyuShow_PutInDress(Pos)
	elseif Oper==2 then
		--拖拽
		FeiyuShow_PutInItem(Pos)
	end
end
function FeiyuShow_PutInDress(Pos)
	local theAction = EnumAction(Pos, "packageitem")
	if theAction:GetID() ~= 0 then
--		local EquipPoint = LifeAbility:Get_Equip_Point_NoMsg(Pos)
--		if EquipPoint ~= 16 then
--			PushDebugMessage("#{FYYR_200610_11}")
--			return
--		end
		local tableIndex = PlayerPackage : GetItemTableIndex( Pos )
		if tableIndex==g_FeiyuNewDressID[1] or tableIndex==g_FeiyuNewDressID[2] or tableIndex==g_FeiyuNewDressID[3] then
			PushDebugMessage("#{FYYR_200610_13}")
			return
		end
		if tableIndex~=g_FeiyuDressID then
			PushDebugMessage("#{FYYR_200610_11}")
			return
		end

		if PlayerPackage:IsLock(Pos) == 1 then
			PushDebugMessage("#{FYYR_200610_14}")
			return
		end
--		--判断是不是可染色时装
--		local canPaint = DressReplaceColor:DressCanPaint(Pos)
--		if canPaint ~= 1 then
--			PushDebugMessage("#{SZPR_091023_18}")
--			--FeiyuShow_Clear()
--			return
--		end
		if( DRESS_POS >= 0 ) then  
			FeiyuShow_DressClear()
		end
		DRESS_POS = Pos;
		LifeAbility:Lock_Packet_Item(DRESS_POS, 1)
		FeiyuShow_Text2_But:SetActionItem(theAction:GetID())
		FeiyuShow_Zidong_ALLChoice_Init()
--		--启用确定按钮
--		if DRESSITEM_POS >= 0 then
--			FeiyuShow_Btn:Enable(); 
--		end
		FeiyuShow_Show();
	end
end
function FeiyuShow_PutInItem(Pos)
	local theAction = EnumAction(Pos, "packageitem")
	if theAction:GetID() ~= 0 then

		local tableIndex = PlayerPackage : GetItemTableIndex( Pos )
		if tableIndex~=g_FeiyuItemID[1] and tableIndex~=g_FeiyuItemID[2] and tableIndex~=g_FeiyuItemID[3] then
			PushDebugMessage("#{FYYR_200610_16}")
			return
		end
		if PlayerPackage:IsLock(Pos) == 1 then
			PushDebugMessage("#{FYYR_200610_17}")
			return
		end
--		--判断是不是可染色时装
--		local canPaint = DressReplaceColor:DressCanPaint(Pos)
--		if canPaint ~= 1 then
--			PushDebugMessage("#{SZPR_091023_18}")
--			--FeiyuShow_Clear()
--			return
--		end
		if( DRESSITEM_POS >= 0 ) then  
			FeiyuShow_ItemClear()
		end
		DRESSITEM_POS = Pos;
		LifeAbility:Lock_Packet_Item(DRESSITEM_POS, 1)
		FeiyuShow_Text1_But:SetActionItem(theAction:GetID())
		FeiyuShow_Zidong_ALLChoice_Init()
--		--启用确定按钮
--		if DRESS_POS >= 0 then
--			FeiyuShow_Btn:Enable(); 
--		end
		FeiyuShow_Show()
	end
end

--初始化自动状态 并构造数据
function FeiyuShow_Zidong_ALLChoice_Init()
	FeiyuShow_Zidong_ALLChoice:ResetList()  	
	FeiyuShow_Zidong_ALLChoice:SetText("#{FYYR_200610_37}")--选择目标印染风格
	FeiyuShow_Zidong_ALLChoice:SetCurrentSelect(0); 
  if ( DRESS_POS == -1 or DRESSITEM_POS == -1 ) then  
  	FeiyuDressVisualID 	= {};
		FeiyuDressNames 			= {};
		FeiyuDressRate 			= {};  
		FeiyuShow_Zidong_ALLChoice:Disable();
		return
	end

	DressReplaceColor :StoreDressType(DRESS_POS); --复用
	--特殊印染
	local feiyuIdx = 1
	local tableIndex = PlayerPackage : GetItemTableIndex( DRESSITEM_POS )
	if tableIndex==g_FeiyuItemID[1] then
		FeiyuDressVisualID[feiyuIdx] = -1
		FeiyuDressNames[feiyuIdx]=g_FeiyuDressStr[1]
		FeiyuDressRate[feiyuIdx]=-1
	elseif tableIndex==g_FeiyuItemID[2] then
		FeiyuDressVisualID[feiyuIdx] = -1
		FeiyuDressNames[feiyuIdx]=g_FeiyuDressStr[2]
		FeiyuDressRate[feiyuIdx]=-1
	elseif tableIndex==g_FeiyuItemID[3] then
		FeiyuDressVisualID[feiyuIdx] = -1
		FeiyuDressNames[feiyuIdx]=g_FeiyuDressStr[3]
		FeiyuDressRate[feiyuIdx]=-1
	else
		return
	end
	feiyuIdx = feiyuIdx+1
	local n_visualID = DressReplaceColor : GetDressVisualID(DRESS_POS)
	for i=g_dressNum-1,1,-1 do
		local nVisual,ndesc,nRate = DressReplaceColor:GetDressDesc(i-1)
		if nVisual ~= n_visualID then
			FeiyuDressVisualID[feiyuIdx] = nVisual;
			if nRate == 23000 then
				FeiyuDressNames[feiyuIdx] = ScriptGlobal_Format("#{SZRSYH_120912_07}", ndesc);
			elseif nRate == 14000 then
				FeiyuDressNames[feiyuIdx] = ScriptGlobal_Format("#{SZRSYH_120912_08}", ndesc)
			elseif nRate == 1000 then
				FeiyuDressNames[feiyuIdx] = ScriptGlobal_Format("#{SZRSYH_120912_09}", ndesc)
			elseif nRate == -1 then
				FeiyuDressNames[feiyuIdx] = ndesc
			end
			FeiyuDressRate[feiyuIdx]=nRate
			feiyuIdx = feiyuIdx+1
		end
	end  
	for i = 1, feiyuIdx-1 do
		FeiyuShow_Zidong_ALLChoice:AddTextItem(FeiyuDressNames[i], i)
	end
	FeiyuShow_Zidong_ALLChoice:Enable() 
	
end

function FeiyuShow_DressClear()
	if(DRESS_POS ~= -1) then
--		FeiyuShow_Btn:Disable()										-- 禁用“确定”按钮
		FeiyuShow_Text2_But:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(DRESS_POS, 0)
		DRESS_POS = -1
	end
--	PushDebugMessage("DressReplaceColor:RestoreFeiyuDressPaint()")
	DressReplaceColor:RestoreFeiyuDressPaint()
	FeiyuShow_FakeObject : SetFakeObject("FeiyuDress_Player");
	FeiyuShow_Text3 : SetText("");
	FeiyuShow_Zidong_ALLChoice:ResetList()  	
	FeiyuShow_Zidong_ALLChoice:SetText("#{FYYR_200610_37}")--选择目标印染风格
	FeiyuShow_Zidong_ALLChoice:SetCurrentSelect(0); 
	FeiyuShow_Zidong_ALLChoice:Disable()
end
function FeiyuShow_ItemClear()
	if(DRESSITEM_POS ~= -1) then
--		FeiyuShow_Btn:Disable()										-- 禁用“确定”按钮
		FeiyuShow_Text1_But:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(DRESSITEM_POS, 0)
		DRESSITEM_POS = -1
		FeiyuShow_Zidong_ALLChoice_Init()
		FeiyuShow_Show()
	end
end
function FeiyuShow_Init()
	SetDefaultMouse();
	StopCareObject_FeiyuShow(objCared)
	FeiyuShow_DressClear()
	FeiyuShow_ItemClear()
	FeiyuShow_Text3 : SetText("");
end
function FeiyuShow_Clear()
	SetDefaultMouse();
	StopCareObject_FeiyuShow(objCared)
	FeiyuShow_DressClear()
	FeiyuShow_ItemClear()
	FeiyuShow_FakeObject : SetFakeObject("");
	FeiyuShow_Text3 : SetText("");
end
function FeiyuShow_OnHide()
	FeiyuShow_Clear()
	this:Hide() 
end

------------------------------------------------------
--
--	打开试衣间
--
function FeiyuShow_DestMode_Changed()
	local visualid = -1
	local _name,ComIdx = FeiyuShow_Zidong_ALLChoice:GetCurrentSelect()
	if ComIdx ~= nil and FeiyuDressVisualID[ComIdx] ~= nil then
		visualid = FeiyuDressVisualID[ComIdx]
	end
--	PushDebugMessage("DressReplaceColor : FeiyuOnDress(DRESS_POS, visualid)")
	if ComIdx==1 then
		local tableIndex = PlayerPackage : GetItemTableIndex( DRESSITEM_POS )
		local dressIndex = -1
		if tableIndex==g_FeiyuItemID[1] then
			dressIndex=g_FeiyuNewDressID[1]
		elseif tableIndex==g_FeiyuItemID[2] then
			dressIndex=g_FeiyuNewDressID[2]
		elseif tableIndex==g_FeiyuItemID[3] then
			dressIndex=g_FeiyuNewDressID[3]
		else
			return
		end
		DressReplaceColor : FeiyuOnNewDress(DRESS_POS, dressIndex)
	else
		DressReplaceColor : FeiyuOnDress(DRESS_POS, visualid)
	end
	-- 设置使用哪个模型
	FeiyuShow_FakeObject : SetFakeObject("");
	FeiyuShow_FakeObject : SetFakeObject("FeiyuDress_Player"); 
end
function FeiyuShow_Show()
	local visualid = -1
	local _name,ComIdx = FeiyuShow_Zidong_ALLChoice:GetCurrentSelect()
	if ComIdx ~= nil and FeiyuDressVisualID[ComIdx] ~= nil then
		visualid = FeiyuDressVisualID[ComIdx]
	end
--	PushDebugMessage("DressReplaceColor : FeiyuOnDress(DRESS_POS, visualid)")
	if ComIdx==1 then
		local tableIndex = PlayerPackage : GetItemTableIndex( DRESSITEM_POS )
		local dressIndex = -1
		if tableIndex==g_FeiyuItemID[1] then
			dressIndex=g_FeiyuNewDressID[1]
		elseif tableIndex==g_FeiyuItemID[2] then
			dressIndex=g_FeiyuNewDressID[2]
		elseif tableIndex==g_FeiyuItemID[3] then
			dressIndex=g_FeiyuNewDressID[3]
		else
			return
		end
		DressReplaceColor : FeiyuOnNewDress(DRESS_POS, dressIndex)
	else
		DressReplaceColor : FeiyuOnDress(DRESS_POS, visualid)
	end
	local n_szDressDesc, nRate,MaterBind = DressReplaceColor : GetDressVisualInfo(DRESS_POS)
	if n_szDressDesc == "" or nRate == 0 then
		return
	end
	-- 设置使用哪个模型
	FeiyuShow_FakeObject : SetFakeObject("");
	FeiyuShow_FakeObject : SetFakeObject("FeiyuDress_Player"); 
	
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

	FeiyuShow_Text3:SetText(strdic)
--	FeiyuShow_FakeObject : Show();

end

------------------------------------------------------
--
--	关心NPC
--
function BeginCareObject_FeiyuShow(objCaredId)
	g_ObjCared = objCaredId
	this:CareObject(g_ObjCared, 1, "FeiyuShow")
end


function StopCareObject_FeiyuShow(objCaredId)
	this:CareObject(g_ObjCared, 0, "FeiyuShow")
	g_ObjCared = -1
end

function FeiyuShow_Frame_On_ResetPos()
  FeiyuShow_Frame:SetProperty("UnifiedPosition", g_FeiyuShow_Frame_UnifiedPosition);
end

----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左)
--
function FeiyuShow_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			FeiyuShow_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			FeiyuShow_FakeObject:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右)
--
function FeiyuShow_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			FeiyuShow_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			FeiyuShow_FakeObject:RotateEnd();
		end
	end
end

function FeiyuShow_OKClick(bExpenCheck)
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end  
	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end 
	--- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90609_22}" )
		return  
	end
	if DRESS_POS==-1 then
		PushDebugMessage( "#{FYYR_200610_22}" )
		return
	end
	if DRESSITEM_POS==-1 then
		PushDebugMessage( "#{FYYR_200610_23}" )
		return
	end
	local _name,ComIdx = FeiyuShow_Zidong_ALLChoice:GetCurrentSelect()
	if ComIdx == nil or FeiyuDressVisualID[ComIdx] == nil then
		PushDebugMessage( "#{FYYR_200610_42}" )
		return
	end
	if bExpenCheck==1 then
		local szDressDesc,nRate,MaterBind = DressReplaceColor : GetDressVisualInfo(DRESS_POS)
		local szCurDesc = szDressDesc
		if nRate == 23000 then
			szCurDesc = ScriptGlobal_Format("#{SZRSYH_120912_07}", szDressDesc);
		elseif nRate == 14000 then
			szCurDesc = ScriptGlobal_Format("#{SZRSYH_120912_08}", szDressDesc)
		elseif nRate == 1000 then
			szCurDesc = ScriptGlobal_Format("#{SZRSYH_120912_09}", szDressDesc)
		end
		if ComIdx==1 then
			local strTip = ScriptGlobal_Format("#{FYYR_200610_44}", szCurDesc, FeiyuDressNames[ComIdx]);
			PushEvent( "FEIYUDRESS_PAINT_EXPSURE", strTip )
		else
			local strTip = ScriptGlobal_Format("#{FYYR_200610_43}", szCurDesc, FeiyuDressNames[ComIdx]);
			PushEvent( "FEIYUDRESS_PAINT_EXPSURE", strTip )
		end
		return
	end

	--绑定与否
	local equipBindState = PlayerPackage:GetItemBindStatusByIndex(DRESS_POS)
	if equipBindState~=1 then
		local itemBindState = PlayerPackage:GetItemBindStatusByIndex(DRESSITEM_POS)
--		PushDebugMessage("FeiyuShow_OKClick "..equipBindState.." "..itemBindState)
		if itemBindState==1 then
			PushEvent( "FEIYUDRESS_PAINT_BINDSURE", DRESS_POS, DRESSITEM_POS, FeiyuDressVisualID[ComIdx] )
			return
		end
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnFeiyuDressPaint")
		Set_XSCRIPT_ScriptID(830003)
		Set_XSCRIPT_Parameter(0, DRESS_POS)
		Set_XSCRIPT_Parameter(1, DRESSITEM_POS)
		Set_XSCRIPT_Parameter(2, FeiyuDressVisualID[ComIdx])
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end


