-- 时装镶嵌试衣间

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0 
local g_Dress_Gem_Frame_UnifiedPosition; 
local g_Dress_Gem_Frame_ItemIcon;
local g_Dress_Gem_Item = -1; 
local g_Dress_Gem_Stiletto_Confirm=0; 
local g_StilettoEx_YuanbaoPay = 1
local g_Dress_Gem_Money =
{
	[1] = 1710,
	[2] = 8250,
	[3] = 40950,
}
local g_Dress_Gem_AllMoney = 0

local g_Dress_Gem_Type =
{
	[1] = 31,
	[2] = 32,
	[3] = 33,
}
local g_Dress_Gem_SelectType_Item ={};
local g_Dress_Gem_SelectType_Animate ={};
local g_Dress_Gem_SelectType_Tips ={};
local g_Dress_Gem_SelectType_Text ={};
local g_Dress_Gem_SelectType_Level ={};
local g_Dress_Gem_SelectType_Max ={};
local g_Dress_Gem_SelectType_Pic ={};

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

-- 选中等级数据
local g_Dress_Gem_SelectItem = {-1,-1,-1}
local g_Dress_Gem_SelectQuality = {0,0,0}
local g_Dress_Gem_CurQuality = {0,0,0}
local g_Dress_Gem_CurItem = {-1,-1,-1}

function Dress_Gem_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OPEN_DRESS_GEM_FITTING");
	this:RegisterEvent("CLOSE_DRESS_GEM_FITTING");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("OPEN_STALL_SALE");
	this:RegisterEvent("PROGRESSBAR_SHOW");
	this:RegisterEvent("OPEN_EQUIP");
	this:RegisterEvent("SEX_CHANGED");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("YIGUI_OPEN")
	this:RegisterEvent("DRESS_GEMFITTING_UPDATE")
	this:RegisterEvent("DRESSGEM_ENCHASE_SENDMSG")
	this:RegisterEvent("DRESSGEM_STILETTO_SENDMSG")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("UPDATE_YUANBAO")
	this:RegisterEvent("FASHION_DEPOT_OP", false);				-- 华裳阁
	this:RegisterEvent("FEIYUSHOW_WINDOW", false)
	this:RegisterEvent("OPEN_SPECIALDRESSPAINT", false)
end


--g_XinShouYue_BaiBao_GetGiftsButtonList[i] : SetToolTip("#{XSHLY_150522_76}")	

function Dress_Gem_OnLoad()
	g_Dress_Gem_Frame_UnifiedPosition	=Dress_Gem_Frame:GetProperty("UnifiedPosition");
 	g_Dress_Gem_Frame_ItemIcon 				= Dress_Gem_Levelup_Dress; 
 	
 	g_Dress_Gem_SelectType_Item[1] = Dress_Gem_RightClient2_P1_Item;
 	g_Dress_Gem_SelectType_Item[2] = Dress_Gem_RightClient2_P2_Item;
 	g_Dress_Gem_SelectType_Item[3] = Dress_Gem_RightClient2_P3_Item;

 	g_Dress_Gem_SelectType_Animate[1] = Dress_Gem_RightClient2_P1_Item_Animate;
 	g_Dress_Gem_SelectType_Animate[2] = Dress_Gem_RightClient2_P2_Item_Animate;
 	g_Dress_Gem_SelectType_Animate[3] = Dress_Gem_RightClient2_P3_Item_Animate;

 	g_Dress_Gem_SelectType_Tips[1] = Dress_Gem_RightClient2_P1_Item_tips;
 	g_Dress_Gem_SelectType_Tips[2] = Dress_Gem_RightClient2_P2_Item_tips;
 	g_Dress_Gem_SelectType_Tips[3] = Dress_Gem_RightClient2_P3_Item_tips;

 	g_Dress_Gem_SelectType_Text[1] = Dress_Gem_RightClient2_P1_text2;
 	g_Dress_Gem_SelectType_Text[2] = Dress_Gem_RightClient2_P2_text2;
 	g_Dress_Gem_SelectType_Text[3] = Dress_Gem_RightClient2_P3_text2;

 	g_Dress_Gem_SelectType_Level[1] = Dress_Gem_Type1_Level;
 	g_Dress_Gem_SelectType_Level[2] = Dress_Gem_Type1_Leve2;
 	g_Dress_Gem_SelectType_Level[3] = Dress_Gem_Type1_Leve3;

 	g_Dress_Gem_SelectType_Max[1] = Dress_Gem_Type1_Level_max;
 	g_Dress_Gem_SelectType_Max[2] = Dress_Gem_Type1_Level2_max;
 	g_Dress_Gem_SelectType_Max[3] = Dress_Gem_Type1_Level3_max;
 	
 	g_Dress_Gem_SelectType_Pic[1] = Dress_Gem_Type1_Level_Pic;
 	g_Dress_Gem_SelectType_Pic[2] = Dress_Gem_Type1_Level2_Pic;
 	g_Dress_Gem_SelectType_Pic[3] = Dress_Gem_Type1_Level3_Pic;
 	
end

function Dress_Gem_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Dress_Gem_OnHiden();
	end

	-- 镶嵌成功，如果试衣间开着，就先关闭
	if event == "UI_COMMAND" and tonumber(arg0) == 09111602 then
		if this:IsVisible() then
			Dress_Gem_OnHiden();										-- 关闭“镶嵌预览”试衣间，这里相关试衣物品的数据都没了，所以不能激活“镶嵌预览”按钮
		end
	end

	-- 关闭试衣间
	if (event == "CLOSE_DRESS_ENCHASE_FITTING") then
		if this:IsVisible() then
			Dress_Gem_OnHiden();										-- 这里是由于逻辑不合理、物品不合格关闭的试衣间，所以不能激活“镶嵌预览”按钮
		end
	end

	-- 开始摆摊
	if ( event == "OPEN_STALL_SALE" ) then
		if (this:IsVisible()) then
			Dress_Gem_OnClosed();										-- 关闭“镶嵌预览”试衣间，重新激活“镶嵌预览”按钮
		end
	end

	-- 读进度条中
	if ( event == "PROGRESSBAR_SHOW" ) then
		if (this:IsVisible()) then
			Dress_Gem_OnClosed();									-- 关闭“镶嵌预览”试衣间，重新激活“镶嵌预览”按钮
		end
	end

	-- 试衣的时候不能打开角色资料窗口
	if ( event == "OPEN_EQUIP" ) then
		if (this:IsVisible()) then
			Dress_Gem_OnClosed();									-- 关闭“镶嵌预览”试衣间，重新激活“镶嵌预览”按钮
		end
	end
	-- 试衣的时候不能打开衣柜窗口
	if ( event == "YIGUI_OPEN" ) then
		if (this:IsVisible()) then
			Dress_Gem_OnClosed();									-- 关闭“镶嵌预览”试衣间，重新激活“镶嵌预览”按钮
		end
	end 
	if (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1) then --华裳阁
		if (this:IsVisible()) then
			Dress_Gem_OnClosed();									
		end
	end
	
	-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			Dress_Gem_OnClosed();		
			return
		end
	end	
	
	if (event == "FEIYUSHOW_WINDOW" and tonumber(arg0) >= 0) or
		 (event == "OPEN_SPECIALDRESSPAINT" and tonumber(arg0) >= 0) then
		if (this:IsVisible()) then
			Dress_Gem_OnClosed();									
		end
	end
	if ( event == "DRESSGEM_STILETTO_SENDMSG" ) then
		 g_Dress_Gem_Stiletto_Confirm = 1;
		 Dress_Gem_Stiletto();
	end

	--不能和变性界面同时存在
	if (event == "UI_COMMAND" and tonumber(arg0) == 20120406) then
		if (this:IsVisible()) then
			Dress_Gem_OnClosed();									-- 关闭“镶嵌预览”试衣间，重新激活“镶嵌预览”按钮
		end
	end
	-- 打开试衣间
	if(event == "UI_COMMAND" and tonumber(arg0) == 20151208) then 
		
		PushEvent( "CLOSE_DRESSPREVIEW") 
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")
		-- 开始关心NPC 
		local npcID = Get_XParam_INT(0); 
		objCared = DataPool : GetNPCIDByServerID(npcID);
		if objCared == -1 then
			return;
		end  
		-- 设置使用哪个模型
		Dress_Gem_Model_FakeObject : SetFakeObject("");
		Dress_Gem_Model_FakeObject : SetFakeObject("DressGem_Player");
		FakeObj_SetCamera( "Dress_Gem",2,12)
    Dress_Gem_Model_FakeObject : Show(); 
		Dress_Gem_Model_LeftFrame_Text:SetText("")-- 打开界面时不显示时装风格
		Dress_Gem_Model_Jian:Hide()-- 打开界面时不显示鉴定按钮
		this:CareObject(objCared, 1, "Dress_Gem");   
		
		Dress_Gem_OnInitial();
		this:Show();
	end

		--升级完成回调
	if(event == "UI_COMMAND" and tonumber(arg0) == 20151215) then
		-- 试衣 
		local IsCan = Dress_Gem_IsCanLevelup(g_Dress_Gem_Item);  
	  if IsCan == 1 then
	  
	  	Dress_Gem_Update(g_Dress_Gem_Item); 
	  	Dress_Gem_UpdateInfoOnUpEquip();
	  	
	  elseif IsCan == 2 then   -- 没有任何宝石 
		  Dress_Gem_Clear();   
	  	return;
	  else	  	-- 满级
	  	Dress_Gem_Clear();   
	  	return;
	  end 	  
	  
		--
		
	end
 
	-- 关心NPC
	if (event == "OBJECT_CARED_EVENT") then
		
		if(tonumber(arg0) ~= objCared) then
			return;
		end

		--如果和商人的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE) or arg1=="destroy") then
			if this:IsVisible() then
				Dress_Gem_OnHiden();								-- 关闭“镶嵌预览”试衣间，由于距离NPC较远，镶嵌界面可能已经关闭了，所以不需要激活“镶嵌预览”按钮了。
			end
		end
	end

	-- 变性
	if event == "SEX_CHANGED" and  this:IsVisible() then
		Dress_Gem_Model_FakeObject : Hide();
		Dress_Gem_Model_FakeObject : Show();
		Dress_Gem_Model_FakeObject : SetFakeObject("Dress_Gem");
	elseif (event == "ADJEST_UI_POS" ) then
		Dress_Gem_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Dress_Gem_Frame_On_ResetPos()
	elseif (event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible()) then   
		Dress_Gem_RemoveEquip()  
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		--Dress_Gem_Yiyouyuangbao:SetText("#{BSZH_130220_10}"..tostring(Player:GetData("YUANBAO")))
		Dress_Gem_Yiyouyuangbao_Text:SetText(tostring(Player:GetData("YUANBAO")))
	--放入时装
	elseif( event == "DRESS_GEMFITTING_UPDATE") then 
		if arg0 == nil then
			return
		end	  
		local IsCan = Dress_Gem_IsCanLevelup(tonumber(arg0)); 
	  if IsCan == 1 then  
	  	Dress_Gem_Update(tonumber(arg0)); 
	  	Dress_Gem_UpdateInfoOnUpEquip();
	  elseif IsCan == 2 then   -- 没有任何宝石 
		  PushDebugMessage("#{SZBSYL_150327_55}")
	  	return;
	  else	  	-- 满级
	  	PushDebugMessage("#{SZBSYL_150327_107}")
	  	return;
	  end 	  
		
	--关闭时装
	elseif( event == "CLOSE_DRESS_GEM_FITTING") then
		Dress_Gem_Clear();
	end
	
end

--*******************************************************************************
-- 注意！！！
-- OnHiden() 函数关闭界面的时候，不会再次激活“镶嵌预览”按钮
-- OnClosed() 函数关闭界面的时候，会再次激活“镶嵌预览”按钮
-- 这两个函数不能通用~~
--*******************************************************************************
----------------------------------------------------------------------------------
--
-- 隐藏
--
function Dress_Gem_OnHiden()
	SetDefaultMouse();
 
	g_Dress_Gem_Frame_ItemIcon:SetActionItem(-1);

	--取消关心
	this:CareObject(objCared, 0, "Dress_Gem");
	objCared = -1
	Dress_Gem_Clear();
	this:Hide();

	if(IsWindowShow("DressJian") == true) then
		PushEvent( "CLOSE_DRESSJIAN_DLG")		
	end

end

----------------------------------------------------------------------------------
--
-- 关闭
--
function Dress_Gem_OnClosed()

	--取消关心
	this:CareObject(objCared, 0, "Dress_Gem");
	objCared = -1 
	
  g_Dress_Gem_Frame_ItemIcon:SetActionItem(-1); 
	Dress_Gem_Clear();
	this:Hide();

	if(IsWindowShow("DressJian") == true) then
		PushEvent( "CLOSE_DRESSJIAN_DLG")		
	end

end

----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左)
--
function Dress_Gem_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			Dress_Gem_Model_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			Dress_Gem_Model_FakeObject:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右)
--
function Dress_Gem_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			Dress_Gem_Model_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			Dress_Gem_Model_FakeObject:RotateEnd();
		end
	end
end

function Dress_Gem_Frame_On_ResetPos()
  Dress_Gem_Frame:SetProperty("UnifiedPosition", g_Dress_Gem_Frame_UnifiedPosition);
end
 

--一键剪裁
function Dress_Gem_Stiletto()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{WHYH_161121_8}")--字典号
		return
	end
	
	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
		
	-- 是否放入时装
	if g_Dress_Gem_Item == -1 then
		PushDebugMessage("#{SZZH_170111_108}")--请放入需要进行配饰升级的时装
		return;
	end
	
	local equipValidity = LifeAbility:Get_Equip_Validity(g_Dress_Gem_Item)
	if equipValidity ~= -1 then
		PushDebugMessage("#{SZZH_170306_149}")
		PushDebugMessage("#{SZZH_170306_140}")
		return
	end
		
	-- 新的配饰id有效
	if g_Dress_Gem_SelectItem[1] <= -1 and  g_Dress_Gem_SelectItem[2] <= -1 and  g_Dress_Gem_SelectItem[3] <= -1 then
		PushDebugMessage("#{SZZH_170111_109}")--请先选择至少1个配饰需要提升的等级
		return;
	end
	
	-- 新的等级有效
	if (g_Dress_Gem_SelectQuality[1] <= 1 or g_Dress_Gem_SelectQuality[1] > 4) -- 提升等级不能全在2-4外
		and (g_Dress_Gem_SelectQuality[2] <= 1 or g_Dress_Gem_SelectQuality[2] > 4) 
		and (g_Dress_Gem_SelectQuality[3] <= 1 or g_Dress_Gem_SelectQuality[3] > 4) then
		PushDebugMessage("#{SZZH_170111_109}")--请先选择至少1个配饰需要提升的等级
		return;
	end
	
	-- 当前配饰id有效
	if g_Dress_Gem_CurItem[1] <= -1 and  g_Dress_Gem_CurItem[2] <= -1 and  g_Dress_Gem_CurItem[3] <= -1 then
		PushDebugMessage("#{SZZH_170111_109}")--请先选择至少1个配饰需要提升的等级
		return;
	end	
	
	-- 当前配饰等级有效
	if (g_Dress_Gem_CurQuality[1] <= 0 or g_Dress_Gem_CurQuality[1] >= 4) -- 原来等级不能全在1-3外
		and (g_Dress_Gem_CurQuality[2] <= 0 or g_Dress_Gem_CurQuality[2] >= 4) 
		and (g_Dress_Gem_CurQuality[3] <= 0 or g_Dress_Gem_CurQuality[3] >= 4) then
		PushDebugMessage("#{SZZH_170111_109}")--请先选择至少1个配饰需要提升的等级
		return;
	end
	
	-- 配饰是否存在提升
	if (g_Dress_Gem_SelectQuality[1] <= g_Dress_Gem_CurQuality[1]) -- 原来等级不能存在大于新等级情况，必然有问题
		and (g_Dress_Gem_SelectQuality[2] <= g_Dress_Gem_CurQuality[2]) 
		and (g_Dress_Gem_SelectQuality[3] <= g_Dress_Gem_CurQuality[3]) then
		PushDebugMessage("#{SZZH_170111_109}")--请先选择至少1个配饰需要提升的等级
		return;
	end
	
		
	-- 是否二次确认
	if g_Dress_Gem_Stiletto_Confirm ~= 1 and Dress_Gem_cost:GetCheck() == 1 then
		-- AAA.A（X级）升级为AAA.A（Y级）
		local strMsg = {}
		for i = 1, 3 do
			strMsg[i] = ""
			if g_Dress_Gem_SelectItem[i] > 0 and g_Dress_Gem_CurItem[i] > 0 and g_Dress_Gem_SelectItem[i] ~= g_Dress_Gem_CurItem[i] then
				local itemName = DressGem:GetGemName(g_Dress_Gem_CurItem[i])
				local newName = DressGem:GetGemName(g_Dress_Gem_SelectItem[i])
				strMsg[i] = ScriptGlobal_Format("#{SZZH_170111_112}", itemName, newName)
			end
		end
		local strAllMsg = ""
		-- 拼接顿号
		if strMsg[1] ~= "" and strMsg[2] ~= "" and strMsg[3] ~= "" then
			strAllMsg = strMsg[1].."#{SZZH_170111_113}"..strMsg[2].."#{SZZH_170111_113}"..strMsg[3]
		elseif strMsg[1] ~= "" and strMsg[2] ~= "" then
			strAllMsg = strMsg[1].."#{SZZH_170111_113}"..strMsg[2]
		elseif strMsg[2] ~= "" and strMsg[3] ~= "" then
			strAllMsg = strMsg[2].."#{SZZH_170111_113}"..strMsg[3]
		elseif strMsg[1] ~= "" and strMsg[3] ~= "" then
			strAllMsg = strMsg[1].."#{SZZH_170111_113}"..strMsg[3]
		elseif strMsg[1] ~= "" then
			strAllMsg = strMsg[1]
		elseif strMsg[2] ~= "" then
			strAllMsg = strMsg[2]
		elseif strMsg[3] ~= "" then
			strAllMsg = strMsg[3]
		end
		if g_Dress_Gem_AllMoney > 0 and strAllMsg ~= "" then
			PushEvent("DRESSGEM_STILETTO_CONFIRM",g_Dress_Gem_AllMoney,strAllMsg); 
		end
		return;
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnDressGem_Enchase")
		Set_XSCRIPT_ScriptID(891736)
		Set_XSCRIPT_Parameter(0, g_Dress_Gem_Item)
		Set_XSCRIPT_Parameter(1, g_Dress_Gem_SelectItem[1])
		Set_XSCRIPT_Parameter(2, g_Dress_Gem_SelectItem[2])
		Set_XSCRIPT_Parameter(3, g_Dress_Gem_SelectItem[3])
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
	
	g_Dress_Gem_Stiletto_Confirm = 0;

end  

--!!!reloadscript =Dress_Gem
--=========================================================
--初始化数据
--=========================================================
function Dress_Gem_OnInitial()

	-- 二次确认标志清空
	g_Dress_Gem_Stiletto_Confirm = 0;
	
	-- 时装框清空
	if g_Dress_Gem_Item ~= -1 then 	 
		LifeAbility:Lock_Packet_Item(g_Dress_Gem_Item, 0)
	end
	g_Dress_Gem_Item 				  = -1;
	g_Dress_Gem_Frame_ItemIcon:SetActionItem(-1); 
		
	-- 配饰框重置
	for i = 1, 3 do
		-- 配饰框空
		g_Dress_Gem_SelectType_Item[i]:SetActionItem(-1); 
		-- 停止动画
		g_Dress_Gem_SelectType_Animate[i]:Hide();
		-- tips不显示
		g_Dress_Gem_SelectType_Tips[i]:SetToolTip(""); 
		-- 不显示文字
		g_Dress_Gem_SelectType_Text[i]:SetText("")
		-- 下拉框清空--文字固定显示--不可更改选项
		g_Dress_Gem_SelectType_Level[i]:Show()
		g_Dress_Gem_SelectType_Level[i]:ResetList()
		g_Dress_Gem_SelectType_Level[i]:ResetLastSelectIndex()
		g_Dress_Gem_SelectType_Level[i]:SetText("#{SZZH_170111_100}") 
		g_Dress_Gem_SelectType_Level[i]:Disable()
		g_Dress_Gem_SelectType_Pic[i]:Show()
		g_Dress_Gem_SelectType_Max[i]:Hide()
		-- 选项清空
		g_Dress_Gem_SelectItem[i] = -1;
		g_Dress_Gem_SelectQuality[i] = 0;
		g_Dress_Gem_CurItem[i] = -1;
		g_Dress_Gem_CurQuality[i] = 0;
	end
	
	-- 元宝显示 
	--Dress_Gem_Yiyouyuangbao:SetText("#{BSZH_130220_10}"..tostring(Player:GetData("YUANBAO")))
	--Dress_Gem_Suoxuyuangbao:SetText("#{BSZH_130220_09}")
	Dress_Gem_Yiyouyuangbao_Text:SetText(tostring(Player:GetData("YUANBAO")))
	Dress_Gem_Suoxuyuangbao_Text:SetText("0")
	g_Dress_Gem_AllMoney = 0
	
	-- 元宝支付确认
	Dress_Gem_cost:SetCheck(g_StilettoEx_YuanbaoPay)
	
end
 
--=========================================================
-- 更新界面
--=========================================================
function Dress_Gem_Update(itemIndex)
	local index = tonumber(itemIndex)
	local theAction = EnumAction(index, "packageitem")
	
	if theAction:GetID() ~= 0 then
		-- 如果空格内已经有对应物品了, 替换之
		if g_Dress_Gem_Item ~= -1 then
			Dress_Gem_Clear()
		end
		g_Dress_Gem_Frame_ItemIcon:SetActionItem(theAction:GetID())
		LifeAbility:Lock_Packet_Item(index, 1)
		g_Dress_Gem_Item = index; 
		Dress_Gem_DressFitting();
	else
		Dress_Gem_Clear();
	end
end


--=========================================================
--时装预览
--=========================================================
function Dress_Gem_DressFitting() 
	DressGem:RestoreDressGemFitting(); 
	Dress_Gem_Model_LeftFrame_Text:SetText("")-- 取消预览时不显示时装风格
	Dress_Gem_Model_Jian:Hide()-- 取消预览时不显示鉴定按钮
	--Dress_Gem_Suoxuyuangbao:SetText("#{BSZH_130220_09}");
	Dress_Gem_Suoxuyuangbao_Text:SetText("0");
	g_Dress_Gem_AllMoney = 0

	if g_Dress_Gem_Item == -1 then
		return
	end
			
	local nSelectCount= 0;-- 有几个配饰更改选项
	local nNeedYuanbao = 0;-- 所需花费
	
	-- 是否有选项改变
	for i = 1,3 do
		-- 下拉选项
		local __txt, id = g_Dress_Gem_SelectType_Level[i]:GetCurrentSelect();
		-- 选项有效
		if id ~= nil and id > 0 then
			-- 获得当前配饰
			local IsGemOnDress,DressGemQuality,DressGemGemIdx = DressGem:IsGemOnDressByType(g_Dress_Gem_Item,g_Dress_Gem_Type[i]); 
			-- 配饰有效
			if IsGemOnDress ~= nil and IsGemOnDress == 1 and DressGemQuality > 0 and DressGemQuality < 4 then
				-- 计算选项对应的配饰等级
				local SelectQuality = id + DressGemQuality -1;
				if SelectQuality > 0 and SelectQuality <= 4 then
					-- 获得当前配饰id和选项对应的配饰id
					local curItemID = DressGem:GetIndexIDByProperty( DressGemQuality,g_Dress_Gem_Type[i],DressGemGemIdx); 
					local selectItemID = DressGem:GetIndexIDByProperty( SelectQuality,g_Dress_Gem_Type[i],DressGemGemIdx); 
					if curItemID ~= nil and curItemID > 0 and selectItemID ~= nil and selectItemID > 0 then
						-- 修改配饰选项计数+1
						nSelectCount = nSelectCount + 1;
						-- 保存当前配饰id 等级 新的配饰id 等级
						g_Dress_Gem_SelectItem[i] = selectItemID;
						g_Dress_Gem_SelectQuality[i] = SelectQuality;
						g_Dress_Gem_CurItem[i] = curItemID;
						g_Dress_Gem_CurQuality[i] = DressGemQuality;
						-- 更新配饰框动画 当前等级不播放 等级提升则播放 若有提升则更新消费金钱数
						if id == 1 then
							-- 停止动画
							g_Dress_Gem_SelectType_Animate[i]:Hide()
						else
							-- 播放动画
							g_Dress_Gem_SelectType_Animate[i]:Show()
							-- 消费金钱数
							if SelectQuality > DressGemQuality then-- 正常走到这里 一定是会有等级提升的 不过还是加下判断吧~
								for j=DressGemQuality,SelectQuality-1 do
									nNeedYuanbao = nNeedYuanbao + g_Dress_Gem_Money[j]
								end
							end
						end
					end
				end
			end
		end
	end	

	-- 更新模型
	if nSelectCount == 0 then		
		DressGem:GemFittingOnOrigDress(g_Dress_Gem_Item);
	else
		DressGem:GemFittingOnDress(g_Dress_Gem_Item,nSelectCount,g_Dress_Gem_SelectItem[1],g_Dress_Gem_SelectItem[2],g_Dress_Gem_SelectItem[3]);
	end
	
	-- 显示时装时显示时装风格和鉴定按钮
	local strdic="";
	local nDressId = PlayerPackage : GetItemTableIndex( g_Dress_Gem_Item )
	if nDressId == g_FeiyuNewDressID[1] then
		strdic = g_FeiyuDressStr[1]
	elseif nDressId == g_FeiyuNewDressID[2] then
		strdic = g_FeiyuDressStr[2]
	elseif nDressId == g_FeiyuNewDressID[3] then
		strdic = g_FeiyuDressStr[3]
	else
		local n_szDressDesc, nRate, MaterBind = DressReplaceColor : GetDressVisualInfo(g_Dress_Gem_Item)
		if n_szDressDesc ~= "" and nRate ~= 0 then
	
			if nRate == 23000 then
				strdic = ScriptGlobal_Format("#{SZRSYH_120912_10}", n_szDressDesc)
			elseif nRate == 14000 then
				strdic = ScriptGlobal_Format("#{SZRSYH_120912_11}", n_szDressDesc)
			elseif nRate == 1000 then
				strdic = ScriptGlobal_Format("#{SZRSYH_120912_12}", n_szDressDesc)
			elseif nRate == -1 then
				strdic = "#G"..n_szDressDesc
			end
		end
	end
	Dress_Gem_Model_LeftFrame_Text:SetText(strdic)
	Dress_Gem_Model_Jian:Show()
	if(IsWindowShow("DressJian") == true) then
		Dress_Gem_Model_Jian_Clicked();
	end
	
	-- 更新需求元宝
	if nNeedYuanbao > 0 then
		--Dress_Gem_Suoxuyuangbao:SetText("#{BSZH_130220_09}"..nNeedYuanbao);
		Dress_Gem_Suoxuyuangbao_Text:SetText(tostring(nNeedYuanbao));
		g_Dress_Gem_AllMoney = nNeedYuanbao
	end
	
end

--=========================================================
-- 打开鉴定界面
--=========================================================
function Dress_Gem_Model_Jian_Clicked()
	if g_Dress_Gem_Item ~= -1 then
		local canPaint = DressReplaceColor:DressCanPaint(g_Dress_Gem_Item)
		if canPaint ~= 1 then
			PushDebugMessage("该时装不能染色，不能查看图鉴。")
			return
		end
		DressReplaceColor:DressOpenDressJian(g_Dress_Gem_Item)
	end
end

--=========================================================
-- 重置界面
--=========================================================
function Dress_Gem_Clear()
	g_StilettoEx_YuanbaoPay = Dress_Gem_cost:GetCheck();  
	if g_Dress_Gem_Item ~= -1 then 	 
--		LifeAbility:Lock_Packet_Item(g_Dress_Gem_Item, 0)
		Dress_Gem_OnInitial();
	end

  -- 关闭“镶嵌预览”试衣间
	if (IsWindowShow("Dress_Gem")) then
		DressGem:RestoreDressGemFitting()
	end		
end

--=========================================================
-- 卸下装备
--=========================================================
function Dress_Gem_RemoveEquip()   
	--重刷界面
	Dress_Gem_Clear();
	Dress_Gem_DressFitting();  
	if(IsWindowShow("DressJian") == true) then
		PushEvent( "CLOSE_DRESSJIAN_DLG")		
	end

end

--=========================================================
-- 放入装备 更新信息
--=========================================================
function Dress_Gem_UpdateInfoOnUpEquip()   
	
	--如果没有装备 那么现实初始状态
	if  g_Dress_Gem_Item == -1 then
		Dress_Gem_OnInitial();
		return;
	end	
	
	-- 有时装时，清空界面
	for i=1,3 do
		-- 显示空框
		g_Dress_Gem_SelectType_Item[i]:SetActionItem(-1); 
		-- 停止动画
		g_Dress_Gem_SelectType_Animate[i]:Hide();
		-- 显示默认tips
		g_Dress_Gem_SelectType_Tips[i]:SetToolTip("#{SZZH_170111_35}")
		g_Dress_Gem_SelectType_Tips[i]:Show()
		-- 显示默认文字
		g_Dress_Gem_SelectType_Text[i]:SetText("#{SZZH_170111_36}")
		-- 下拉框清空--文字固定显示--不可更改选项
		g_Dress_Gem_SelectType_Level[i]:Show()
		g_Dress_Gem_SelectType_Level[i]:ResetList()
		g_Dress_Gem_SelectType_Level[i]:ResetLastSelectIndex()
		g_Dress_Gem_SelectType_Level[i]:SetText("#{SZZH_170111_101}") 
		g_Dress_Gem_SelectType_Level[i]:Disable()
		g_Dress_Gem_SelectType_Pic[i]:Show()
		-- 不显示最高等级框
		g_Dress_Gem_SelectType_Max[i]:Hide()
		-- 选项清空
		g_Dress_Gem_SelectItem[i] = -1;
		g_Dress_Gem_SelectQuality[i] = 0;
		g_Dress_Gem_CurItem[i] = -1;
		g_Dress_Gem_CurQuality[i] = 0;
	end
		
	-- 配饰框显示
	for i = 1, 3 do
		-- 存在配饰
		local IsGemOnDress,DressGemQuality,DressGemGemIdx = DressGem:IsGemOnDressByType( g_Dress_Gem_Item, g_Dress_Gem_Type[i] ); 
		if IsGemOnDress ~= nil and IsGemOnDress == 1 then
			-- 获得配饰图标
			local ItemID  	= DressGem:GetIndexIDByProperty( DressGemQuality,g_Dress_Gem_Type[i],DressGemGemIdx );
			if ItemID ~= nil and ItemID > 0 then
				local theAction = DataPool:CreateActionItemForShow(ItemID, 1)
				if theAction:GetID() ~= 0 then
			  	g_Dress_Gem_SelectType_Item[i]:SetActionItem(theAction:GetID())
			  	-- 获得配饰名字信息
					local nGemName,nGemInfo = DressGem:GetItemNameByProperty( DressGemQuality,g_Dress_Gem_Type[i],DressGemGemIdx);
					if nGemName ~= nil and nGemName ~= "" and nGemInfo ~= nil and nGemInfo ~= "" then
						-- 获得等级
						nGemInfo = string.sub(nGemInfo,2,string.len(nGemInfo)-1)
						-- 显示名字
				  	g_Dress_Gem_SelectType_Text[i]:SetText( ""..nGemName..nGemInfo )
				  	-- 原tips是否需要隐藏
						g_Dress_Gem_SelectType_Tips[i]:SetToolTip("")
						g_Dress_Gem_SelectType_Tips[i]:Hide()
						-- 最高等级
				  	if DressGemQuality == 4 then
				  		-- 下拉框隐藏
							g_Dress_Gem_SelectType_Level[i]:ResetList()
							g_Dress_Gem_SelectType_Level[i]:ResetLastSelectIndex()
							g_Dress_Gem_SelectType_Level[i]:SetText("") 
							g_Dress_Gem_SelectType_Level[i]:Disable()
							g_Dress_Gem_SelectType_Level[i]:Hide()
							g_Dress_Gem_SelectType_Pic[i]:Hide()
							-- 显示最高等级框
							g_Dress_Gem_SelectType_Max[i]:Show()
						else
					  	-- 显示默认文字
							g_Dress_Gem_SelectType_Level[i]:Show()
							g_Dress_Gem_SelectType_Level[i]:SetText("#{SZZH_170111_102}")--选择提升等级 
							-- 默认第一行为当前等级
							--g_Dress_Gem_SelectType_Level[i]:AddTextItem(nGemInfo,1)
							g_Dress_Gem_SelectType_Level[i]:AddTextItem("#{SZZH_170111_104}",1)
							g_Dress_Gem_SelectType_Level[i]:Enable()
							-- 下拉框图片隐藏			  	
							g_Dress_Gem_SelectType_Pic[i]:Hide()
							-- 最高等级框隐藏
							g_Dress_Gem_SelectType_Max[i]:Hide()
							-- 增加选项，从当前等级开始
							local nCombolListIndex = 2;
							for j = DressGemQuality+1 , 4 do 
								local szGemName,szGemInfo = DressGem:GetItemNameByProperty( j,g_Dress_Gem_Type[i],DressGemGemIdx);
								if szGemName ~= nil and szGemName ~= "" and szGemInfo ~= nil and szGemInfo ~= "" then
									-- 增加选项
									szGemInfo = string.sub(szGemInfo,2,string.len(szGemInfo)-1)
									--g_Dress_Gem_SelectType_Level[i]:AddTextItem(szGemInfo ,nCombolListIndex)  
									g_Dress_Gem_SelectType_Level[i]:AddTextItem(ScriptGlobal_Format("#{SZZH_170111_105}", szGemInfo) ,nCombolListIndex) 
									-- 下标加1  
									nCombolListIndex = nCombolListIndex + 1;
								end
							end
						end
					end 			  	
			  end
			end
		end
	end
	
end

-- 装备是否可以升级
function Dress_Gem_IsCanLevelup( itemindex )
	local IsGemOnDress_S,DressGemQuality_S,DressGemGemIdx_S = DressGem:IsGemOnDressByType(itemindex,g_Dress_Gem_Type[1]);
	local IsGemOnDress_W,DressGemQuality_W,DressGemGemIdx_W = DressGem:IsGemOnDressByType(itemindex,g_Dress_Gem_Type[2]);
	local IsGemOnDress_F,DressGemQuality_F,DressGemGemIdx_F = DressGem:IsGemOnDressByType(itemindex,g_Dress_Gem_Type[3]);
	
 	-- 可以升级 
	if ( IsGemOnDress_S ~= nil and DressGemQuality_S < 4 and DressGemQuality_S > 0) or
		 ( IsGemOnDress_W ~= nil and DressGemQuality_W < 4 and DressGemQuality_W > 0) or
		 ( IsGemOnDress_F ~= nil and DressGemQuality_F < 4 and DressGemQuality_F > 0) then
		 	return 1;
	-- 身上没有宝石不可以
	elseif (IsGemOnDress_S == nil or IsGemOnDress_S == 0) and 
					(IsGemOnDress_W == nil or IsGemOnDress_W == 0) and 
					(IsGemOnDress_F == nil or IsGemOnDress_F == 0) then
			return 2;
	end
	-- 其他情况 我认为正常只有一种情况 那就是满级了  
	return 0;
end

-- 选择等级
function Dress_Gem_Levelup_Seleceted(nIndex)
	
	-- 参数无效
	if nIndex == nil or nIndex <= 0 or nIndex > table.getn(g_Dress_Gem_Type) then
		return
	end
	
	-- 获得选项
	local __txt, id = g_Dress_Gem_SelectType_Level[nIndex]:GetCurrentSelect();
	if id == -1 then 
		return
	end
	
	-- 时装未放入
	if g_Dress_Gem_Item == -1 then
		return
	end

	-- 更新模型
	Dress_Gem_DressFitting();
		
end
