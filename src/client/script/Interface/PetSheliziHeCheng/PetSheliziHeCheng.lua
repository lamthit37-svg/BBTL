local g_PetSheliziHeCheng_Frame_UnifiedPosition = nil 
local ActionButton_1;
local ActionButton_2;

local g_bAction1_full = 0
local g_bAction2_full = 0

local g_Item_Pos1 = -1
local g_Item_Pos2 = -1


local g_Max_Exp = 30000000
local g_objCareID = -1;

function PetSheliziHeCheng_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("SHELIZI_HECHENG_DRAG")
	this:RegisterEvent("SHELIZI_HECHENG_REMOVE")
	this:RegisterEvent("SHELIZI_HECHENG_CONFIRM")
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end 


function PetSheliziHeCheng_OnLoad()
	g_PetSheliziHeCheng_Frame_UnifiedPosition = PetSheliziHeCheng_Frame:GetProperty("UnifiedPosition");
	ActionButton_1 =PetSheliziHeCheng_ActionButton1
	ActionButton_2 =PetSheliziHeCheng_ActionButton2
end

function PetSheliziHeCheng_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		PetSheliziHeCheng_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		PetSheliziHeCheng_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		PetSheliziHeCheng_OnHidden()
	elseif(event == "UI_COMMAND") then
		local nUIIdx = tonumber(arg0)
		if nUIIdx == 20170826 then
			
			PetSheliziHeCheng_Init(Get_XParam_INT(0),Get_XParam_INT(1))
		end
	elseif(event == "SHELIZI_HECHENG_DRAG") then
		local BagIndex = tonumber(arg0)
		local Actionpos = tonumber(arg1)
		PetSheliziHeCheng_DragFinsh(BagIndex, Actionpos)
	elseif(event == "SHELIZI_HECHENG_REMOVE") then
		local pos = tonumber(arg0)
		PetSheliziHeCheng_RemoveAction(pos)
	elseif (event == "SHELIZI_HECHENG_CONFIRM") then
		local param1 = tonumber(arg0)
		if param1 >= 100 then
			--现在不会出现需要弹两次确认框的情况了
			PetSheliziHeCheng_OnConfirmlimit()
		end

	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_objCareID) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			PetSheliziHeCheng_StopCareObject()
			PetSheliziHeCheng_OnHidden()
		end			
	end
end

function PetSheliziHeCheng_StopCareObject()
	this:CareObject(g_objCareID, 0, "PetSheliziHeCheng");
	g_objCareID = -1;
end


function PetSheliziHeCheng_Init(targetNPCID, bagPosID)

		-- PushDebugMessage("targetNPCID="..targetNPCID..",bagPosID="..bagPosID)
		PetSheliziHeCheng_Clear()
		
		g_objCareID = DataPool : GetNPCIDByServerID(targetNPCID);
		PetSheliziHeCheng_BeginCareObject(g_objCareID)
		-- local str = ScriptGlobal_Format("#{ZSDHC_170828_11}", 0) 
		local str_2 = ScriptGlobal_Format("#{ZSDHC_170831_27}", PetSheliziHeCheng_FormatExp(0))
		PetSheliziHeCheng_Pet1_Text:SetText("#{ZSDHC_170828_11}")
		PetSheliziHeCheng_Pet2_Text:SetText("#{ZSDHC_170828_11}")
		PetSheliziHeCheng_Pet1_Text_jingyan:SetText(PetSheliziHeCheng_FormatExp(0))
		PetSheliziHeCheng_Pet2_Text_jingyan:SetText(PetSheliziHeCheng_FormatExp(0))
		-- PetSheliziHeCheng_Currently_JingYan_Text:SetText(str_2)
		PetSheliziHeCheng_Currently_JingYan:SetText(str_2)
		if( IsWindowShow("Packet") == false ) then
			ToggleContainer()
		end		
		
		if(bagPosID >= 0) then
			PetSheliziHeCheng_DragFinsh(bagPosID,0)		
		end
		
		PetSheliziHeCheng_OK:Disable()
		this:Show()
end

function PetSheliziHeCheng_BeginCareObject()
	this:CareObject(g_objCareID, 1, "PetSheliziHeCheng");
end


function PetSheliziHeCheng_RemoveAction(pos)

	if pos == 0 then
		if g_Item_Pos1 ~= -1 then
			LifeAbility : Lock_Packet_Item(g_Item_Pos1,0)
			ActionButton_1:SetActionItem(-1)
			g_Item_Pos1 = -1	
			g_bAction1_full = 0
			local str = "#{ZSDHC_170828_11}"
			PetSheliziHeCheng_Pet1_Text:SetText(str);
			PetSheliziHeCheng_Pet1_Text_jingyan:SetText(PetSheliziHeCheng_FormatExp(0))
		end	
	
	elseif pos == 1 then
		if g_Item_Pos2 ~= -1 then
			LifeAbility : Lock_Packet_Item(g_Item_Pos2,0)
			ActionButton_2:SetActionItem(-1)
			g_Item_Pos2 = -1	
			g_bAction2_full = 0
			local str = "#{ZSDHC_170828_11}"
			PetSheliziHeCheng_Pet2_Text:SetText(str);	
			PetSheliziHeCheng_Pet2_Text_jingyan:SetText(PetSheliziHeCheng_FormatExp(0))
		
		end
	
	end
	
	PetSheliziHeCheng_CalcTotalExp()

end


function PetSheliziHeCheng_On_ResetPos()
	PetSheliziHeCheng_Frame:SetProperty("UnifiedPosition", g_PetSheliziHeCheng_Frame_UnifiedPosition)
end

function PetSheliziHeCheng_OnHidden()
	PetSheliziHeCheng_Clear()
end

function PetSheliziHeCheng_FormatExp(ExpNum)
	if(ExpNum < 10000) then
	
		return "#Y"..ExpNum

	elseif(ExpNum < 100000000) then
	
		local high = math.floor(ExpNum/10000)
		local low = math.mod(ExpNum,10000)
		
		local str = string.format("#cff9900%d,#Y%04d",high,low)
		return str
	
	else
	
		local high = math.floor(ExpNum/100000000)
		local mid = math.mod(math.floor(ExpNum/10000),10000)
		local low = math.mod(ExpNum,10000)
		local str = string.format("#cff99ff%d,#cff9900%04d,#Y%04d#W",high,mid,low)
		return str
	end
		

end



function PetSheliziHeCheng_Clear()

	ActionButton_1:SetActionItem(-1)
	ActionButton_2:SetActionItem(-1)
	
	
	if g_Item_Pos1 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos1,0)
		g_Item_Pos1 = -1	
	end
	
	if g_Item_Pos2 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos2,0)
		g_Item_Pos2 = -1	
	end
	
	g_bAction1_full = 0
	g_bAction2_full = 0
end


function PetSheliziHeCheng_DragFinsh(BagIndex, Actionpos)

	local theAction = EnumAction(BagIndex,"packageitem")
	
	local ItemID = PlayerPackage : GetItemTableIndex(BagIndex)

	
	
	if PlayerPackage:IsLock(BagIndex) == 1 then
		PushDebugMessage("#{ZSDHC_170828_07}")
		return
	end
	
	
	if PetSheliziHeCheng_IsShelizi(ItemID) == 0 then
		PushDebugMessage("#{ZSDHC_170828_08}")
		--不是舍利子
		return
	end

	
	local sheliziEXP = PlayerPackage:GetSheliziExp(BagIndex)
		
	if sheliziEXP >=  g_Max_Exp then
		PushDebugMessage("#{ZSDHC_170828_09}")
		return
	end
	
	
	if Actionpos == -1 then
		if g_bAction1_full == 0 then
			Actionpos = 0
		elseif g_bAction2_full == 0 then
			Actionpos = 1
		else
			PushDebugMessage("#{ZSDHC_170828_10}")
		end
	end
	
	
	if Actionpos == 0 then
		if g_bAction1_full == 1 then
			if g_Item_Pos1 ~= -1 then
				ActionButton_1:SetActionItem(-1)
				LifeAbility : Lock_Packet_Item(g_Item_Pos1,0)
				g_Item_Pos1 = -1	
			end
		end
		
		ActionButton_1:SetActionItem(theAction:GetID())
		g_bAction1_full = 1
		g_Item_Pos1 = BagIndex
		LifeAbility : Lock_Packet_Item(BagIndex,1);

		local str = "#{ZSDHC_170828_11}" 
		PetSheliziHeCheng_Pet1_Text:SetText(str)
		PetSheliziHeCheng_Pet1_Text_jingyan:SetText(PetSheliziHeCheng_FormatExp(sheliziEXP))
		
		
	end
	
	if Actionpos == 1 then
	
		if g_bAction2_full == 1 then
			if g_Item_Pos2 ~= -1 then
				ActionButton_2:SetActionItem(-1)
				LifeAbility : Lock_Packet_Item(g_Item_Pos2,0)
				g_Item_Pos2 = -1	
			end
		end
		
		ActionButton_2:SetActionItem(theAction:GetID())
		g_bAction2_full = 1
		g_Item_Pos2 = BagIndex
		LifeAbility : Lock_Packet_Item(BagIndex,1);	
		
		local str = "#{ZSDHC_170828_11}"
		PetSheliziHeCheng_Pet2_Text:SetText(str)
		PetSheliziHeCheng_Pet2_Text_jingyan:SetText(PetSheliziHeCheng_FormatExp(sheliziEXP))
	end
	
	PetSheliziHeCheng_CalcTotalExp()
	
end


function PetSheliziHeCheng_CalcTotalExp()
	local exp1 = 0
	
	local exp2 = 0
	if g_Item_Pos1 ~= -1 then
		exp1 = PlayerPackage:GetSheliziExp(g_Item_Pos1)
	end
	
	if g_Item_Pos2 ~= -1 then
		exp2 = PlayerPackage:GetSheliziExp(g_Item_Pos2)
	
	end
	
	if g_bAction1_full == 1 and g_bAction2_full  == 1 then
		PetSheliziHeCheng_OK:Enable()
	else
		PetSheliziHeCheng_OK:Disable()
	end
	
	local total = exp1+exp2
	
	if total > g_Max_Exp then	
		local str = ScriptGlobal_Format("#{ZSDHC_170831_28}", total) 
		PetSheliziHeCheng_Currently_JingYan:SetText(str)
	else
		local str = ScriptGlobal_Format("#{ZSDHC_170831_27}", PetSheliziHeCheng_FormatExp(total)) 
		PetSheliziHeCheng_Currently_JingYan:SetText(str)	
	end
	

end


function PetSheliziHeCheng_Cancel_Clicked()
	this:Hide()
end

function PetSheliziHeCheng_Close_Click()
end




function PetSheliziHeCheng_OnConfirmlimit()
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("ClientAskMerge");
				Set_XSCRIPT_ScriptID(300270);
				Set_XSCRIPT_Parameter(0,tonumber(g_Item_Pos1));
				Set_XSCRIPT_Parameter(1, tonumber(g_Item_Pos2))
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();	

end

--点了绑定物品二次确认
--之前的检测都不用再做了
function PetSheliziHeCheng_OnConfirmBind()

	local exp1 = 0
	
	local exp2 = 0
	if g_Item_Pos1 ~= -1 then
		exp1 = PlayerPackage:GetSheliziExp(g_Item_Pos1)
	end
	
	if g_Item_Pos2 ~= -1 then
		exp2 = PlayerPackage:GetSheliziExp(g_Item_Pos2)
	
	end

	if exp1 >= g_Max_Exp then
		PushDebugMessage("#{ZSDHC_170828_18}")
		return 		
	end
	
	if exp2 >= g_Max_Exp then
		PushDebugMessage("#{ZSDHC_170828_19}")
		return 	
	end
	
	if exp1+exp2 > g_Max_Exp then
		--还要发一个二次确认
		PushEvent("SHELIZI_HECHENG_CONFIRM",2, tonumber((exp1+exp2)-g_Max_Exp));
		return 
	end
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("ClientAskMerge");
				Set_XSCRIPT_ScriptID(300270);
				Set_XSCRIPT_Parameter(0,tonumber(g_Item_Pos1));
				Set_XSCRIPT_Parameter(1, tonumber(g_Item_Pos2))
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();		
	

end

--合成功能
function PetSheliziHeCheng_OK_Clicked()

	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZBSX_130625_62}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end	
	
	if g_Item_Pos1 == -1 then
		PushDebugMessage("#{ZSDHC_170828_17}")
		return 
	end
	
	if g_Item_Pos2 == -1 then
		PushDebugMessage("#{ZSDHC_170828_17}")
		return 	
	end
	
	local exp1 = 0
	
	local exp2 = 0
	if g_Item_Pos1 ~= -1 then
		exp1 = PlayerPackage:GetSheliziExp(g_Item_Pos1)
	end
	
	if g_Item_Pos2 ~= -1 then
		exp2 = PlayerPackage:GetSheliziExp(g_Item_Pos2)
	
	end

	if exp1 >= g_Max_Exp then
		PushDebugMessage("#{ZSDHC_170828_18}")
		return 		
	end
	
	if exp2 >= g_Max_Exp then
		PushDebugMessage("#{ZSDHC_170828_19}")
		return 	
	end
	
	--检查背包空间
	if(CalcItemSpace(30900058) < 1) then
		PushDebugMessage("#{ZSDHC_170828_26}")
		return 
	end
	
	
	--绑定状态监测
	local equiplock_1 =  PlayerPackage:GetItemBindStatusByIndex(g_Item_Pos1)
	local equiplock_2 =  PlayerPackage:GetItemBindStatusByIndex(g_Item_Pos2)
	
	
	if ((equiplock_1 == 1 or equiplock_2 == 1 ) and equiplock_1 ~= equiplock_2 ) and exp1+exp2 > g_Max_Exp then
		PushEvent("SHELIZI_HECHENG_CONFIRM",3, tonumber((exp1+exp2)-g_Max_Exp));
		return
	
	else
	
	
	
		-- PushDebugMessage("equiplock_1="..equiplock_1..",equiplock_2="..equiplock_2)
		if (equiplock_1 == 1 or equiplock_2 == 1 ) and equiplock_1 ~= equiplock_2 then
			--需要发送二次确认框
			
			-- PushDebugMessage("????????????????/")
			PushEvent("SHELIZI_HECHENG_CONFIRM",1);
			
			return
		end
		
		
		if exp1+exp2 > g_Max_Exp then
			--还要发一个二次确认
			PushEvent("SHELIZI_HECHENG_CONFIRM",2, tonumber((exp1+exp2)-g_Max_Exp));
			return 
		end
	end
	
	
	
	
	
	
	
	
	
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("ClientAskMerge");
				Set_XSCRIPT_ScriptID(300270);
				Set_XSCRIPT_Parameter(0,tonumber(g_Item_Pos1));
				Set_XSCRIPT_Parameter(1, tonumber(g_Item_Pos2))
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();	
			
			
end

function PetSheliziHeCheng_IsShelizi(itemid)
	if itemid == 30900058 or itemid == 30900059 or itemid == 30900124 or itemid == 38001301 then
		return 1
		
	else
		return 0
		
	end

end
