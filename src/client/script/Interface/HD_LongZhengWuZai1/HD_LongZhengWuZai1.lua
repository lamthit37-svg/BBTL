----------------------
-- HD_LongZhengWuZai1 ---
----------------------
local ActionButton;


local g_ItemID1 = 0;
local g_ItemID2 = 0;
local g_ItemID3 = 0;
local g_ItemID4 = 0;
local g_ItemID5 = 0;

local g_Item_Pos1 = -1;
local g_Item_Pos2 = -1;
local g_Item_Pos3 = -1;
local g_Item_Pos4 = -1;
local g_Item_Pos5 = -1;


local g_bBox1_full = 0
local g_bBox2_full = 0
local g_bBox3_full = 0
local g_bBox4_full = 0
local g_bBox5_full = 0

local FIVEYEAR_NPC_ID = -1
local objCared = -1
local MAX_OBJ_DISTANCE = 3.0;
local g_HD_LongZhengWuZai1_Frame_UnifiedPosition =nil;
--===============================================
-- PreLoad()
--===============================================
function HD_LongZhengWuZai1_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_FIVEYEARCARD")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

--===============================================
-- OnLoad()
--===============================================
function HD_LongZhengWuZai1_OnLoad()
	ActionButton = HD_LongZhengWuZai1_Object1
	g_HD_LongZhengWuZai1_Frame_UnifiedPosition = HD_LongZhengWuZai1_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function HD_LongZhengWuZai1_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 20120202) then
		FIVEYEAR_NPC_ID = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(FIVEYEAR_NPC_ID);
		BeginCareObject_HD_LongZhengWuZai1(objCared)		
		this:Show()
		HD_LongZhengWuZai1_Clear()
	elseif (event == "UPDATE_FIVEYEARCARD") and this : IsVisible() then
		
		if arg1 == nil then
			arg1 = 0
		end
		if arg0 ~= nil then
			
			HD_LongZhengWuZai1_Update(tonumber(arg0),tonumber(arg1));
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			
			--取消关心
			HD_LongZhengWuZai1_Cancel_Clicked()
		end
	elseif (event == "ADJEST_UI_POS") then
		HD_LongZhengWuZai1_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HD_LongZhengWuZai1_ResetPos()
	end
	
end

--===============================================
-- Cancel_Clicked
--===============================================
function HD_LongZhengWuZai1_Cancel_Clicked()
	HD_LongZhengWuZai1_Close();
	return;
end

function HD_LongZhengWuZai1_ResetPos()
	HD_LongZhengWuZai1_Frame:SetProperty("UnifiedPosition",g_HD_LongZhengWuZai1_Frame_UnifiedPosition)
end

--===============================================
-- Close()
--===============================================
function HD_LongZhengWuZai1_Close()
	--并设置，让背包里的位置变亮
	if( this:IsVisible() ) then
		if(g_Item_Pos1 ~= -1) then
			LifeAbility : Lock_Packet_Item(g_Item_Pos1,0);
		end
		
		if(g_Item_Pos2 ~= -1) then
			LifeAbility : Lock_Packet_Item(g_Item_Pos2,0);
		end
		
		if(g_Item_Pos3 ~= -1) then
			LifeAbility : Lock_Packet_Item(g_Item_Pos3,0);
		end
		
		if(g_Item_Pos4 ~= -1) then
			LifeAbility : Lock_Packet_Item(g_Item_Pos4,0);
		end
		
		if(g_Item_Pos5 ~= -1) then
			LifeAbility : Lock_Packet_Item(g_Item_Pos5,0);
		end
	end
	
	StopCareObject_EquipRepair(objCared)
	HD_LongZhengWuZai1_Clear()
	EQUIP_NPC_ID = -1
	return this:Hide()
end

function HD_LongZhengWuZai1_OnHiden()
	HD_LongZhengWuZai1_Clear()
	return this:Hide()
end

function HD_LongZhengWuZai1_Update(pos0,typeId)
	local pos_packet = tonumber(pos0)
	local theAction = EnumAction(pos_packet, "packageitem")
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
	--鼠标右键消息
	if (typeId == 0)  then
		if g_bBox1_full == 1 and g_bBox2_full == 1 and g_bBox3_full == 1 and g_bBox4_full == 1 and g_bBox5_full == 1 then
			PushDebugMessage("#{LZWZ_120117_82}")
			return
		end
		
		if g_bBox1_full == 0 then
			ActionButton:SetActionItem(theAction:GetID())
			g_ItemID1 = ItemID
			g_bBox1_full = 1
			g_Item_Pos1 = pos_packet
			LifeAbility : Lock_Packet_Item(pos_packet,1);
		elseif g_bBox2_full == 0 then
			HD_LongZhengWuZai1_Object2:SetActionItem(theAction:GetID())
			g_ItemID2 = ItemID
			g_Item_Pos2 = pos_packet
			g_bBox2_full = 1
			LifeAbility : Lock_Packet_Item(pos_packet,1);
		elseif g_bBox3_full == 0 then
			HD_LongZhengWuZai1_Object3:SetActionItem(theAction:GetID())
			g_ItemID3 = ItemID
			g_Item_Pos3 = pos_packet
			g_bBox3_full = 1
			LifeAbility : Lock_Packet_Item(pos_packet,1);
		
		elseif g_bBox4_full == 0 then
			HD_LongZhengWuZai1_Object4:SetActionItem(theAction:GetID())
			g_ItemID4 = ItemID
			g_Item_Pos4 = pos_packet
			g_bBox4_full = 1
			LifeAbility : Lock_Packet_Item(pos_packet,1);
		
		elseif g_bBox5_full == 0 then
			HD_LongZhengWuZai1_Object5:SetActionItem(theAction:GetID())
			g_ItemID5 = ItemID
			g_Item_Pos5 = pos_packet
			g_bBox5_full = 1
			LifeAbility : Lock_Packet_Item(pos_packet,1);
		end
	elseif (typeId == 2) then--拖拽第1个空
			if(g_bBox1_full == 0) then
				ActionButton:SetActionItem(theAction:GetID())
				g_ItemID1 = ItemID
				g_Item_Pos1 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox1_full = 1
			elseif(g_bBox1_full == 1) then
				ActionButton:SetActionItem(-1)
				LifeAbility : Lock_Packet_Item(g_Item_Pos1,0)
				--清掉原来的
				ActionButton:SetActionItem(theAction:GetID())
				g_ItemID1 = ItemID
				g_Item_Pos1 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox1_full = 1
				
			end
	elseif (typeId == 3) then--拖拽第2个空
			if(g_bBox2_full == 0) then
				HD_LongZhengWuZai1_Object2:SetActionItem(theAction:GetID())
				g_ItemID2 = ItemID
				g_Item_Pos2 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox2_full = 1
			elseif(g_bBox2_full == 1) then
				HD_LongZhengWuZai1_Object2:SetActionItem(-1)
				LifeAbility : Lock_Packet_Item(g_Item_Pos2,0)
				--清掉原来的
				HD_LongZhengWuZai1_Object2:SetActionItem(theAction:GetID())
				g_ItemID2 = ItemID
				g_Item_Pos2 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox2_full = 1
			end
	
	elseif (typeId == 24) then--拖拽第2个空
			if(g_bBox3_full == 0) then
				HD_LongZhengWuZai1_Object3:SetActionItem(theAction:GetID())
				g_ItemID3 = ItemID
				g_Item_Pos3 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox3_full = 1
			elseif(g_bBox3_full == 1) then
				HD_LongZhengWuZai1_Object3:SetActionItem(-1)
				LifeAbility : Lock_Packet_Item(g_Item_Pos3,0)
				--清掉原来的
				HD_LongZhengWuZai1_Object3:SetActionItem(theAction:GetID())
				g_ItemID3 = ItemID
				g_Item_Pos3 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox3_full = 1
			end
		elseif (typeId == 25) then--拖拽第2个空
			if(g_bBox4_full == 0) then
				HD_LongZhengWuZai1_Object4:SetActionItem(theAction:GetID())
				g_ItemID4 = ItemID
				g_Item_Pos4 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox4_full = 1
			elseif(g_bBox4_full == 1) then
				HD_LongZhengWuZai1_Object4:SetActionItem(-1)
				LifeAbility : Lock_Packet_Item(g_Item_Pos4,0)
				--清掉原来的
				HD_LongZhengWuZai1_Object4:SetActionItem(theAction:GetID())
				g_ItemID4 = ItemID
				g_Item_Pos4 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox4_full = 1
			end
		elseif (typeId == 26) then--拖拽第2个空
			if(g_bBox5_full == 0) then
				HD_LongZhengWuZai1_Object5:SetActionItem(theAction:GetID())
				g_ItemID5 = ItemID
				g_Item_Pos5 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox5_full = 1
			elseif(g_bBox5_full == 1) then
				HD_LongZhengWuZai1_Object5:SetActionItem(-1)
				LifeAbility : Lock_Packet_Item(g_Item_Pos5,0)
				--清掉原来的
				HD_LongZhengWuZai1_Object5:SetActionItem(theAction:GetID())
				g_ItemID5 = ItemID
				g_Item_Pos5 = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				g_bBox5_full = 1
			end
	end
	
	
	
end




function HD_LongZhengWuZai1_OK_Clicked()
	if (g_bBox1_full == 0) or (g_bBox2_full == 0) or (g_bBox3_full == 0) or (g_bBox4_full == 0) or (g_bBox5_full == 0) then
		PushDebugMessage("#{LZWZ_120117_86}")
		return
	end
	
	if (g_Item_Pos1 == nil) or (g_Item_Pos1 < 0) then
		PushDebugMessage("#{LZWZ_120117_86}")
		return
	end
	
	if (g_Item_Pos2 == nil) or (g_Item_Pos2 < 0) then
		PushDebugMessage("#{LZWZ_120117_86}")
		return
	end
	
	if (g_Item_Pos3 == nil) or (g_Item_Pos3 < 0) then
		PushDebugMessage("#{LZWZ_120117_86}")
		return
	end
	
	if (g_Item_Pos4 == nil) or (g_Item_Pos4 < 0) then
		PushDebugMessage("#{LZWZ_120117_86}")
		return
	end
	
	if (g_Item_Pos5 == nil) or (g_Item_Pos5 < 0) then
		PushDebugMessage("#{LZWZ_120117_86}")
		return
	end
	
	LifeAbility : Lock_Packet_Item(g_Item_Pos1,0)
	LifeAbility : Lock_Packet_Item(g_Item_Pos2,0)
	LifeAbility : Lock_Packet_Item(g_Item_Pos3,0)
	LifeAbility : Lock_Packet_Item(g_Item_Pos4,0)
	LifeAbility : Lock_Packet_Item(g_Item_Pos5,0)
	
	--local nPos = g_Item_Pos2 + 100*g_Item_Pos3
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ClientSumbitCard");
		Set_XSCRIPT_ScriptID(889669);
		Set_XSCRIPT_Parameter(0,FIVEYEAR_NPC_ID);
		Set_XSCRIPT_Parameter(1,g_Item_Pos1);
		Set_XSCRIPT_Parameter(2,g_Item_Pos2);
		Set_XSCRIPT_Parameter(3,g_Item_Pos3);
		Set_XSCRIPT_Parameter(4,g_Item_Pos4);
		Set_XSCRIPT_Parameter(5,g_Item_Pos5);
	--	Set_XSCRIPT_Parameter(6,0);
		Set_XSCRIPT_ParamCount(6);
	Send_XSCRIPT();			
	
	this : Hide()
end

function HD_LongZhengWuZai1_Clear()
	HD_LongZhengWuZai1_Object1:SetActionItem(-1);
	HD_LongZhengWuZai1_Object2:SetActionItem(-1);
	HD_LongZhengWuZai1_Object3:SetActionItem(-1);
	HD_LongZhengWuZai1_Object4:SetActionItem(-1);
	HD_LongZhengWuZai1_Object5:SetActionItem(-1);
	
	if g_Item_Pos1 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos1,0)
		g_Item_Pos1 = -1
	end
	
	if g_Item_Pos2 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos2,0)
		g_Item_Pos2 = -1
	end
	
	if g_Item_Pos3 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos3,0)
		g_Item_Pos3 = -1
	end
	
	if g_Item_Pos4 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos4,0)
		g_Item_Pos4 = -1
	end
		
	if g_Item_Pos5 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos5,0)
		g_Item_Pos5 = -1
	end
	
	g_bBox1_full = 0
	g_bBox2_full = 0
	g_bBox3_full = 0
	g_bBox4_full = 0
	g_bBox5_full = 0
end


--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_HD_LongZhengWuZai1(objCaredId)
	
	this:CareObject(objCaredId, 0, "HD_LongZhengWuZai1");
	g_Object = -1;

end
--=========================================================
--右键点击取消
--=========================================================
function HD_LongZhengWuZai1_Cancel1()
	if g_Item_Pos1 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos1,0)
		g_Item_Pos1 = -1
	end
	HD_LongZhengWuZai1_Object1:SetActionItem(-1);
	g_bBox1_full = 0
end

function HD_LongZhengWuZai1_Cancel2()
	if g_Item_Pos2 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos2,0)
		g_Item_Pos2 = -1
	end
	HD_LongZhengWuZai1_Object2:SetActionItem(-1);
	g_bBox2_full = 0
end

function HD_LongZhengWuZai1_Cancel3()
	if g_Item_Pos3 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos3,0)
		g_Item_Pos3 = -1
	end
	HD_LongZhengWuZai1_Object3:SetActionItem(-1);
	g_bBox3_full = 0
end

function HD_LongZhengWuZai1_Cancel4()
	if g_Item_Pos4 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos4,0)
		g_Item_Pos4 = -1
	end
	HD_LongZhengWuZai1_Object4:SetActionItem(-1);
	g_bBox4_full = 0
end

function HD_LongZhengWuZai1_Cancel5()
	if g_Item_Pos5 ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Item_Pos5,0)
		g_Item_Pos5 = -1
	end
	HD_LongZhengWuZai1_Object5:SetActionItem(-1);
	g_bBox5_full = 0
end
--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_HD_LongZhengWuZai1(objCaredId)
	
	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "HD_LongZhengWuZai1");

end
--帮助
function HD_LongZhengWuZai1_Help_Clicked()
end