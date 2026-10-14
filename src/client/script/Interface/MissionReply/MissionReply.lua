local MISSION_BUTTONS_NUM =3;
local Pet_Index = -1;
local objCared = -1;
local MISSION_ITEM_BUTTONS = {};
local MISSION_ITEM_TEXT ={};
local MAX_OBJ_DISTANCE = 3.0;
local	Accept_Clicked_Num = 0;				-- 是否已按过一次“确定”
local	scriptId = -1;								-- “血浴神兵”任务时，调用该界面的脚本ID
local g_MissionReply_Frame_UnifiedPosition;
--任务提交界面
local g_MissionReply_Frame_AbsoluteSize
local g_MissionReply_NeedItem1_AbsoluteSize
local g_MissionReply_NeedItem1_Info_AbsoluteSize

--界面调整及恢复，某些任务的界面需要在布局上动态做一些调整，比如“血浴神兵”有这个需求
local function ChangeUIForScript_500503(bChange)
	if bChange~=nil and bChange == true then
		MISSION_ITEM_BUTTONS[2]:Hide();
		MISSION_ITEM_BUTTONS[3]:Hide();
		MISSION_ITEM_TEXT[2]:Hide();
		MISSION_ITEM_TEXT[3]:Hide();
		MissionReply_NeedPet_Text:Hide();
		MissionReply_NeedPet_Info:Hide();
		MissionReply_PetList:Hide();
		MissionReply_Frame:SetProperty("AbsoluteSize", "w:310 h:320");
		MissionReply_NeedItem1:SetProperty("AbsolutePosition", "x:84.000000 y:188.000000");
		MissionReply_NeedItem1_Info:SetProperty("AbsolutePosition", "x:121.000000 y:188.000000");
	else
		MISSION_ITEM_BUTTONS[2]:Show();
		MISSION_ITEM_BUTTONS[3]:Show();
		MISSION_ITEM_TEXT[2]:Show();
		MISSION_ITEM_TEXT[3]:Show();
		MissionReply_NeedPet_Text:Show();
		MissionReply_NeedPet_Info:Show();
		MissionReply_PetList:Show();
		MissionReply_Frame:SetProperty("AbsoluteSize", g_MissionReply_Frame_AbsoluteSize);
		MissionReply_NeedItem1:SetProperty("AbsolutePosition", g_MissionReply_NeedItem1_AbsolutePosition);
		MissionReply_NeedItem1_Info:SetProperty("AbsolutePosition", g_MissionReply_NeedItem1_Info_AbsolutePosition);
	end
end
--===============================================
-- OnLoad
--===============================================
function MissionReply_PreLoad()

	this:RegisterEvent("REPLY_MISSION",true);						-- 提交任务界面
	this:RegisterEvent("QUEST_AFTER_CONTINUE",false);			-- 点击“继续”之后，奖品选择界面
	this:RegisterEvent("REPLY_MISSION_PET",false);				-- 珍兽刷新
	this:RegisterEvent("UPDATE_REPLY_MISSION",false);			-- 刷新提交任务界面
	this:RegisterEvent("OBJECT_CARED_EVENT",false);				-- 某逻辑对象的某些发生改变
	this:RegisterEvent("UPDATE_PET_PAGE",false);					-- 玩家身上的珍兽数据发生变化

		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	
end

function MissionReply_OnLoad()

	MISSION_ITEM_BUTTONS[1] = MissionReply_NeedItem1;
	MISSION_ITEM_BUTTONS[2] = MissionReply_NeedItem2;
	MISSION_ITEM_BUTTONS[3] = MissionReply_NeedItem3;
	
	MISSION_ITEM_TEXT[1] = MissionReply_NeedItem1_Info;
	MISSION_ITEM_TEXT[2] = MissionReply_NeedItem2_Info;
	MISSION_ITEM_TEXT[3] = MissionReply_NeedItem3_Info;
	g_MissionReply_Frame_UnifiedPosition=MissionReply_Frame:GetProperty("UnifiedPosition");

	g_MissionReply_Frame_AbsoluteSize = MissionReply_Frame:GetProperty("AbsoluteSize");
	g_MissionReply_NeedItem1_AbsolutePosition = MissionReply_NeedItem1:GetProperty("AbsolutePosition");
	g_MissionReply_NeedItem1_Info_AbsolutePosition = MissionReply_NeedItem1_Info:GetProperty("AbsolutePosition");
end

--===============================================
-- OnEvent
--===============================================
function MissionReply_OnEvent(event)
	
	--PushDebugMessage("MissionReply : "..event);

	-- 提交任务界面
	if ( event == "REPLY_MISSION" ) then
		--界面布局调整恢复，界面可能已经被“血浴神兵”改变了布局
		ChangeUIForScript_500503(false);
		if (arg0~=nil) then
			objCared = tonumber(arg0);
			BeginCareObject_MissionReply(tonumber(arg0));
		end
		
		-- “血浴神兵”任务时，得到调用该界面的 scriptId
		if (arg1~=nil) then
			scriptId = tonumber(arg1);
			if scriptId == 500503 or scriptId == 500504 then
				--“血浴神兵”需要改变界面布局
				--ChangeUIForScript_500503(true);
				return
			end
		end
		
		MissionReply_Frame_Update();
		this:Show();
		
	-- 刷新提交任务界面
	elseif( event == "UPDATE_REPLY_MISSION" )  then
		MissionReply_Frame_Update();
	
	-- 点击“继续”之后，奖品选择界面
	elseif ( event == "QUEST_AFTER_CONTINUE" and this:IsVisible() ) then
		StopCareObject_MissionReply(objCared)
		this:Hide();
	
	-- 珍兽刷新
	elseif ( event == "REPLY_MISSION_PET" and this:IsVisible() ) then
		--珍兽已被其它界面选中
		if (Pet:GetPetLocation(tonumber(arg0)) ~= -1) then
			return;
		end

		-- 取消当前珍兽的锁定状态（如果当前选的和上一次选的是同一只珍兽，不能解除锁定）
		if (Pet_Index >= 0) and (Pet_Index ~= tonumber(arg0)) then			
			Pet : SetPetLocation( Pet_Index, -1 )			
		end		

		Pet_Index = tonumber(arg0)		
		MissionReply_PetInfo_Update();

	-- 某逻辑对象的某些发生改变
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			
			--取消关心
			StopCareObject_MissionReply(objCared);
		end
	
	-- 玩家身上的珍兽数据发生变化，包括珍兽出战、休息、增加一只珍兽
	elseif (event == "UPDATE_PET_PAGE") then
		MissionReply_PetInfo_Update();
	end
		-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		MissionReply_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MissionReply_Frame_On_ResetPos()
	end
end

--===============================================
-- 更新显示界面数据
--===============================================
function MissionReply_Frame_Update()
	
	--任务信息，（需求、奖励、描述等
	--进入前先清除原有信息
	MissionReply_Desc:ClearAllElement();

	--显示NPC名字
	if( Target:IsPresent()) then
		MissionReply_PageHeader_Name:SetText("#gFF0FA0"..Target:GetDialogNpcName());
	end
	
	local nTextNum, nBonusNum = DataPool:GetMissionDemand_Num();
	if ( nTextNum>=1 ) then
		for i=1, nTextNum do
			local strInfo = DataPool:GetMissionDemand_Text(i-1);
			MissionReply_Desc:AddTextElement(strInfo);
		end
	end
	
	if ( nBonusNum>=1 ) then
		MissionReply_Desc:AddTextElement("需要物品");
		for i=1, nBonusNum do
			-- 需要的类型，需要物品ID，需要多少个
			local nItemID, nNum = DataPool:GetMissionDemand_Item(i-1);
			MissionReply_Desc:AddItemElement(nItemID, nNum, 0);
		end
	end	

	-- 任务需要的物品栏（玩家自己拖放）
	local i=1;
	while i<=MISSION_BUTTONS_NUM do
		local theAction = MissionReply:EnumItem(i-1);

		if theAction:GetID() ~= 0 then
			MISSION_ITEM_BUTTONS[i] : SetActionItem(theAction:GetID());
			MISSION_ITEM_TEXT[i] : SetText(theAction:GetName());
		else
			MISSION_ITEM_BUTTONS[i] : SetActionItem(-1);
			MISSION_ITEM_TEXT[i] : SetText("");
		end
		i = i+1;
	end

	-- 更新珍兽的界面数据
	MissionReply_PetInfo_Update();

end

--===============================================
-- 更新珍兽显示界面数据
--===============================================
function MissionReply_PetInfo_Update()
	
	--进入前先清除原有显示信息
	MissionReply_NeedPet_Info: SetText("");	
	
	--任务需要的宠物栏（玩家自己选择）
	if Pet_Index ~= -1 then
		-- 判断珍兽的状态
		local szPetName, szOn = Pet:GetPetList_Appoint(Pet_Index);
		if(szPetName ~= "")   then
			-- 珍兽在背包里
			if ( szOn == "on_packa" ) then
				-- 给珍兽上锁，设置珍兽已经提交到7号界面容器
				Pet : SetPetLocation( Pet_Index, 7 )
				MissionReply_NeedPet_Info : SetText(Pet:GetName(Pet_Index));
			else
				-- 给珍兽解锁，设置珍兽已经从当前界面容器释放
				Pet : SetPetLocation( Pet_Index, -1 )
				Pet_Index = -1
				MissionReply_NeedPet_Info : SetText("");
			end
		end
	end
	-- 更新珍兽列表界面
	Pet:UpdatePetList();

end

--===============================================
-- 宠物 (暂时不能完成)
--===============================================
function MissionReply_Pet_Clicked()
	MissionReply:OpenPetFrame();
end

--===============================================
-- 确定
--===============================================
function MissionReply_Accept_Clicked()
		
	--神器重铸需要进行密保和安全时间验证
	if scriptId == 500504 then
		--判断电话密保和二级密码保护2012.6.11-LIUBO
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
			return
		end
		-- 判断是否为安全时间2012.6.11-LIUBO
		if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
			PushDebugMessage("#{ZYXT_120528_16}")
			return
		end
	end
	-- 如果是“血浴神兵”中的“神器铸造”或“神器重铸”任务调用的该界面
	if ( scriptId == 500503 ) or ( scriptId == 500504 ) then

		--if (Accept_Clicked_Num == 0) then
			--MissionReply:OpenSecondConfirmFrame(scriptId);		-- 根据调用该界面的scriptId，打开对应的二次确认页面
			--Accept_Clicked_Num = 1;

		--else 	 

			--MissionReply:OnContinue(Pet_Index);
			--StopCareObject_MissionReply(objCared)
			--if Pet_Index >= 0 then
				--Pet : SetPetLocation( Pet_Index, -1 )
			--end
			--Pet_Index = -1;
			--Accept_Clicked_Num = 0; 													-- 第2次点击“确定”后，恢复 Accept_Clicked_Num 为未按过“确定”按钮。
			--this:Hide();
		--end
		
	else
		MissionReply:OnContinue(Pet_Index);
		StopCareObject_MissionReply(objCared)
		if Pet_Index >= 0 then
			Pet : SetPetLocation( Pet_Index, -1 )
		end
		Pet_Index = -1;
		this:Hide();
	end
	
end

--===============================================
-- 取消
--===============================================
function MissionReply_Cancel_Clicked()

	-- 如果是“血浴神兵”中的“神器铸造”或“神器重铸”任务调用的该界面
	if ( scriptId == 500503 ) or ( scriptId == 500504 ) then
		--Accept_Clicked_Num = 0; 														-- 点击“取消”后，恢复 Accept_Clicked_Num 为未按过“确定”按钮。
	end
	
	StopCareObject_MissionReply(objCared)
	if Pet_Index >= 0 then
		Pet : SetPetLocation( Pet_Index, -1 )
	end
	Pet_Index = -1;
	this:Hide();

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_MissionReply(objCaredId)


	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "MissionReply");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_MissionReply(objCaredId)
	this:CareObject(objCaredId, 0, "MissionReply");
	g_Object = -1;
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function MissionReply_OnClose()
	DataPool:CloseMissionFrame();
	Pet : ShowPetList(0);
	MissionReply_Cancel_Clicked();
	if Pet_Index >= 0 then
		Pet : SetPetLocation( Pet_Index, -1 )
	end
	Pet_Index = -1
end

function MissionReply_ToggleShowPetList()
	DataPool : ToggleShowPetList();
end

--=========================================================
-- 点击图标
--=========================================================
function MissionReply_NeedItem_Click(nIndex)
	MissionReply:DoAction(nIndex);
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MissionReply_Frame_On_ResetPos()
  MissionReply_Frame:SetProperty("UnifiedPosition", g_MissionReply_Frame_UnifiedPosition);
end