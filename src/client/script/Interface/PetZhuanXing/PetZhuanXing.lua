-- PetZhuanXing.lua
-- 转性
local mainPet = { idx = -1, guid = { high = -1, low = -1 } }

-- 功能 NPC
local theNPC = -1
local MAX_OBJ_DISTANCE = 3.0

local currentChoose = -1
local g_ItemPos = -1

local g_Item_ZhuanXingDan = 30502009
local g_NeedMoney = 100000

local g_PetZhuanXing_Frame_UnifiedPosition

function PetZhuanXing_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("REPLY_MISSION_PET")			-- 玩家从列表选定一只珍兽
	this:RegisterEvent("UPDATE_PET_PAGE", false)				-- 玩家身上的珍兽数据发生变化
	this:RegisterEvent("DELETE_PET")					-- 玩家身上减少一只珍兽
	this:RegisterEvent("OBJECT_CARED_EVENT")			-- 关心 NPC 的存在和范围
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)				--交子普及 Vega
	this:RegisterEvent("OPEN_EXCHANGE_FRAME")			--打开交易界面
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	--this:RegisterEvent("QUICKUP_PET_SENDMSG")				--二次确认
	this:RegisterEvent("UPDATE_PET_ZHUANXING", false)
	this:RegisterEvent("UPDATE_PET_ZHUANXING_ITEM")	
	this:RegisterEvent("BUY_ITEM")
end

function PetZhuanXing_OnLoad()

	PetZhuanXing_Clear()
	g_PetZhuanXing_Frame_UnifiedPosition = PetZhuanXing_Frame:GetProperty("UnifiedPosition")
	
end

function PetZhuanXing_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 99814401 then		-- 打开界面
		if this:IsVisible() then									-- 如果界面开着，则不处理
			return
		end
		local npcObjId = Get_XParam_INT(0)
		BeginCareObject(npcObjId)
		PetZhuanXing_Clear()
		PetZhuanXing_Show()
		return
	end

	if ( event == "UPDATE_PET_ZHUANXING") then
		if not this:IsVisible() then			
			return					
		end
		PetZhuanXing_Clear()
		PetZhuanXing_Show()
	end

	if ( event == "UPDATE_PET_ZHUANXING_ITEM") then
		if not this:IsVisible() then								
			return
		end
		PetZhuanXing_UpdateItem(arg0)
	end

	-- 玩家选了一只珍兽
	if (event == "REPLY_MISSION_PET" and this:IsVisible())then
		PetZhuanXing_SelectPet(tonumber(arg0))
	
		PetZhuanXing_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		PetZhuanXing_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end

	-- 玩家身上的珍兽数据发生变化，包括珍兽出战、休息、增加一只珍兽
	if event == "UPDATE_PET_PAGE" and this:IsVisible() then

		PetZhuanXing_Clear()
		PetZhuanXing_Show()
		PetZhuanXing_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		PetZhuanXing_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end

	-- 玩家身上减少一只珍兽
	if event == "DELETE_PET" and this:IsVisible() then
		PetZhuanXing_Clear()
		PetZhuanXing_Show()
		PetZhuanXing_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		PetZhuanXing_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end

	-- 关心 NPC 的存在和范围
	if event == "OBJECT_CARED_EVENT" and this:IsVisible() then
		Pet : ShowPetList(0)
		if tonumber(arg0) ~= theNPC then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1 == "destroy" then			
			PetZhuanXing_Cancel_Clicked()
		end
		return
	end

	if (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		PetZhuanXing_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	end

	if (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		PetZhuanXing_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	end
	
	-- 打开交易界面的同时关闭该界面，但是需要刷新一下珍兽列表
	if (event == "OPEN_EXCHANGE_FRAME" and this:IsVisible()) then
		StopCareObject()
		PetZhuanXing_Clear()
		Pet:ShowPetList(0)
		Pet:ShowPetList(1)
		this:Hide()
	end
	
	if (event == "ADJEST_UI_POS" ) then
		PetZhuanXing_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetZhuanXing_Frame_On_ResetPos()
	end	
	
	if event == "BUY_ITEM" and this:IsVisible() then
	
		local item = tonumber(arg1)

		if g_Item_ZhuanXingDan ~= item then 
			return
		end
		
		PetZhuanXing_UpdateItem(PlayerPackage:GetBagPosByItemIndex(item))

	end
end

function PetZhuanXing_Show()

	--local check  = tonumber(Pet:GetYuanbaoBuyState(3));
	--if(check >= 1)then
		--PetZhuanXing_Blank_ButtonCheck:SetCheck(0);	
	--else
		--PetZhuanXing_Blank_ButtonCheck:SetCheck(1);
	--end	

	Pet:ShowPetList(0)
	Pet:ShowPetList(1)
	PetZhuanXing_Money:SetProperty("MoneyNumber", tostring(0))
	PetZhuanXing_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	PetZhuanXing_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))

	this:Show()
end

-- 选择珍兽
function PetZhuanXing_SelectPet(petIdx)

	if -1 == petIdx then
		PushDebugMessage("#{ZSZHD_220620_13}")
		return
	end

	--珍兽已被其它界面选中
	if (Pet:GetPetLocation(petIdx) ~= -1) then
		return
	end
	
	--判断是否珍兽加锁
	if PlayerPackage:IsPetLock(petIdx) == 1 then
		PushDebugMessage("#{ZSZHD_220620_37}")
		return
	end

	--判断是否珍兽出战
	if Pet:GetIsFighting(petIdx) == 1 then
		PushDebugMessage("#{ZSZHD_220620_14}")
		return
	end

	local petName,status = Pet:GetPetList_Appoint(petIdx)
	--附体	
	if status == "on_possession" then
		PushDebugMessage("#{ZSZHD_220620_15}")
		return
	end

	if Pet:GetZXFlag(petIdx) > 0 then
		PushDebugMessage("#{ZSZHD_220620_16}")
		return
	end

	-- 如果原来已经选择了一个宠, 则清空原来的数据
	PetZhuanXing_RemoveMainPet()
	
	local guidH, guidL = Pet:GetGUID(petIdx)
	-- 记录该宠的位置号、GUID
	mainPet.idx = petIdx
	mainPet.guid.high = guidH
	mainPet.guid.low = guidL

	local strName,strName2,sex = Pet:GetID(petIdx);
	if sex == 1 then
		--雄性
		PetZhuanXing_FakeObject_Image1:Show()
		PetZhuanXing_FakeObject_Image2:Hide()
	else
		PetZhuanXing_FakeObject_Image1:Hide()
		PetZhuanXing_FakeObject_Image2:Show()
	end
	-- 将珍兽名字填到文本框中
	PetZhuanXing_Pet_Text:SetText(petName)
	-- 给珍兽上锁，设置珍兽已经提交到20号界面容器
	-- 容器编号对应 Client 代码中的 PET_LOCATION_TYPE
	Pet:SetPetLocation(petIdx, 20)
	-- 更新珍兽列表界面
	Pet:UpdatePetList()	
		
	--Model
	PetZhuanXing_FakeObject:SetFakeObject("")
	Pet:SetZhuanxingModel(petIdx)
	PetZhuanXing_FakeObject:SetFakeObject("My_PetZhuanXing")	
	PetZhuanXing_OK:Enable()
	if (g_ItemPos ~= -1) then
		PetZhuanXing_Money:SetProperty( "MoneyNumber", tostring(g_NeedMoney) )
	end
end


function PetZhuanXing_OK_Clicked()

	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZSZHD_220620_18}")
		return
	end
	
	if mainPet.idx == -1 then
		PushDebugMessage("#{ZSZHD_220620_23}")
		return
	end

	-- 您的金钱不足，请确认
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < g_NeedMoney then
		PushDebugMessage("#{ZSZHD_220620_27}")
		return
	end
	
	if g_ItemPos < 0 then
		--去掉检查因为有元宝直接购买过程
		--Clear_XSCRIPT()
			--Set_XSCRIPT_Function_Name("PetZX_Yuanbao_Pay")
			--Set_XSCRIPT_ScriptID(998144)
			--Set_XSCRIPT_Parameter(0, tonumber(Pet:GetYuanbaoBuyState(3)))		
			--Set_XSCRIPT_ParamCount(1)
		--Send_XSCRIPT()
		PushDebugMessage("#{ZSZHD_220620_38}")
		return
	end
	
	-- 发送 UI_Command 实现
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PetZhuanXing")
		Set_XSCRIPT_ScriptID(998144)
		Set_XSCRIPT_Parameter(0, mainPet.guid.high)
		Set_XSCRIPT_Parameter(1, mainPet.guid.low)	
		Set_XSCRIPT_Parameter(2, g_ItemPos)		
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function PetZhuanXing_SelectPet_Clicked()
	-- 关一下再开，清空数据
	Pet : ShowPetList(0)
	Pet : ShowPetList(1)
end

function PetZhuanXing_Close_Window()
	Pet : ShowPetList(0)
	StopCareObject()
	PetZhuanXing_Clear()
	
	--关闭二次确认界面
	PushEvent("CONVENIENT_BUY_CONFIRM_CLOSE");
	this:Hide()
end

function PetZhuanXing_RemoveMainPet()
	if mainPet.idx ~= -1 then
		Pet:SetPetLocation(mainPet.idx, -1)
		-- 更新珍兽列表界面
		Pet:UpdatePetList()
	end

	mainPet.idx = -1
	mainPet.guid.high = -1
	mainPet.guid.low = -1
end

function PetZhuanXing_Clear()
	PetZhuanXing_RemoveMainPet()

	PetZhuanXing_FakeObject_Image1:Hide()
	PetZhuanXing_FakeObject_Image2:Hide()
	PetZhuanXing_Pet_Text:SetText("")
	PetZhuanXing_Money:SetProperty("MoneyNumber", tostring(0))
	PetZhuanXing_SelfJiaozi:SetProperty("MoneyNumber", tostring(0))
	PetZhuanXing_SelfMoney:SetProperty("MoneyNumber", tostring(0))

	PetZhuanXing_OK:Disable()
	
	PetZhuanXing_FakeObject:SetFakeObject("")

	PetZhuanXing_ClearItem()
end

--model turn left
function PetZhuanXing_Model_TurnLeft(start)
	--start
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		PetZhuanXing_FakeObject:RotateBegin(-0.3);
	--stop
	else
		PetZhuanXing_FakeObject:RotateEnd();
	end
end

--model turn right
function PetZhuanXing_Model_TurnRight(start)
	--start
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		PetZhuanXing_FakeObject:RotateBegin(0.3);
	--stop
	else
		PetZhuanXing_FakeObject:RotateEnd();
	end
end

function PetZhuanXing_UpdateSelected()
	-- 判断被选中的珍兽是否还在背包里
	if mainPet.idx ~= -1 then
		local newIdx = Pet:GetPetIndexByGUID(mainPet.guid.high, mainPet.guid.low)
		Pet:SetPetLocation(mainPet.idx, -1)
		-- 如果不在则删掉
		if newIdx == -1 then
			mainPet.idx = -1
			mainPet.guid.high = -1
			mainPet.guid.low = -1
			PetZhuanXing_Pet:SetText("")
			PetZhuanXing_Text2:SetText("")
			PetZhuanXing_OK:Disable()
			PetZhuanXing_RemoveMainPet()
		-- 否则判断珍兽的位置是否发生变化
		elseif newIdx ~= mainPet.idx then
			-- 如果发生变化则对位置进行更新
			mainPet.idx = newIdx
		end
	end

	PetZhuanXing_SelectPet(mainPet.idx)
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject(objCaredId)
	theNPC = DataPool:GetNPCIDByServerID(objCaredId)
	if theNPC == -1 then
		PushDebugMessage("未发现 NPC")
		this:Hide()
		return
	end

	this:CareObject(theNPC, 1, "PetZhuanXing")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject()
	this:CareObject(theNPC, 0, "PetZhuanXing")
	Pet:ShowPetList(0)
	theNPC = -1
end


function PetZhuanXing_Frame_On_ResetPos()
  PetZhuanXing_Frame:SetProperty("UnifiedPosition", g_PetZhuanXing_Frame_UnifiedPosition)
end


function PetZhuanXing_Blank_ButtonClick() 

	--local check  = tonumber(Pet:GetYuanbaoBuyState(3));
	
	--if(check>=1)then
		--PetZhuanXing_Blank_ButtonCheck:SetCheck(1);
		--Pet:SetYuanbaoBuyState(3, 0);
	--else
		--PetZhuanXing_Blank_ButtonCheck:SetCheck(0);
		--Pet:SetYuanbaoBuyState(3, 1);
	--end	

end

function PetZhuanXing_UpdateItem(pos_packet)
	if (pos_packet == nil) then
		return
	end

	local BagPos = tonumber(pos_packet)

	--是否加锁....
	if (PlayerPackage:IsLock(BagPos) == 1) then
		PushDebugMessage("#{Item_Locked}")
		return
	end

	--更新材料界面
	local ItemID = PlayerPackage:GetItemTableIndex(BagPos)
	if (ItemID <= 0) then
		PushDebugMessage("#{GMActionSystem_Item_CantUseInPetSkillStudy}")
		return
	end

	if ItemID ~= g_Item_ZhuanXingDan then
		PushDebugMessage("#{GMActionSystem_Item_CantUseInPetSkillStudy}")
		return
	end

	if (g_ItemPos ~= -1) then
		LifeAbility:Lock_Packet_Item( g_ItemPos, 0 )
	end

	LifeAbility:Lock_Packet_Item( BagPos, 1 )
	g_ItemPos = BagPos

	--更新珍兽还童的珍兽界面
	local theAction = EnumAction( BagPos, "packageitem" )
	if (theAction:GetID() == 0) then
		return
	end

	PetZhuanXing_Item:SetActionItem(theAction:GetID())

	--更新珍兽还童需要花费的金钱
	if (-1 ~= mainPet.idx) then
		PetZhuanXing_Money:SetProperty( "MoneyNumber", tostring(g_NeedMoney) )
		PetZhuanXing_OK:Enable()
	end
end

function PetZhuanXing_OnHidden(  )
	-- body
	PetZhuanXing_Close_Window()
end

function PetZhuanXing_ClearItem()

	if (g_ItemPos ~= -1) then
		LifeAbility:Lock_Packet_Item( g_ItemPos, 0 )
	end

	g_ItemPos = -1

	PetZhuanXing_Item:SetActionItem(-1)
	--PetZhuanXing_OK:Disable()
end