local g_Mount_Prolong_Frame_UnifiedPosition;

local Zuoqi_Button;
local Zuoqi_Bagpos = -1;
local Zuoqi_ItemIndex = -1;

local Zuoqi_Comfirm_Button;

local objCared = -1;

local ZQ_NPC_NAME = "伊天彩";
local ZQ_NPC_ID;

local g_Mount_Prolong_Level = 10;

local ProlongMaxDays = 360 --续期天数上限（暂定）

local ProlongDays = 30 --每次续期天数（暂定）

local DaysUI;
local PaysUI;

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Mount_Prolong_PreLoad()
	
	this:RegisterEvent("UI_COMMAND",true);
	
	
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("UPDATE_MOUNT_PROLONG",true);--挪入
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);--挪出
	this:RegisterEvent("UPDATE_YUANBAO",false); --元宝更新
	this:RegisterEvent("REFRESH_MOUNT",false)--坐骑更新？！
	

		
	this:RegisterEvent("OBJECT_CARED_EVENT",false);  --npc关心
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Mount_Prolong_OnEvent(event)
	
	if ( event == "ADJEST_UI_POS" ) then
		Mount_Prolong_ResetPos()
	elseif ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 810209011 then

			ZQ_NPC_ID = Get_XParam_INT(0);

				this:Show();
				
				if ZQ_NPC_ID == -1 then
					--donothing
				else
					objCared = DataPool : GetNPCIDByServerID(ZQ_NPC_ID);
					if objCared == -1 then
						PushDebugMessage("server传过来的数据有问题。");
						return;
					end
					BeginCareObject_Mount_Prolong()
				end
		end
	elseif( event == "UPDATE_MOUNT_PROLONG") then

		if arg0 == nil then
			return
		end

		Mount_Prolong_Update(tonumber(arg0));
	
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			Mount_Prolong_Close();
		end
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Mount_Prolong_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Mount_Prolong_OnHiden()		
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		Mount_Prolong_Yuanbao_Text:SetText(tostring(Player:GetData("YUANBAO")))
	elseif (event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() ) then
		Mount_Prolong_Clear();
	end
end

function Mount_Prolong_OnLoad()

	-- 保存界面的默认相对位置
	g_Mount_Prolong_Frame_UnifiedPosition=Mount_Prolong_Frame:GetProperty("UnifiedPosition");
	Zuoqi_Button = Mount_Prolong_Frame2_Item;
	--local str = ScriptGlobal_Format("%s", tostring(Player:GetData("YUANBAO")));
	Mount_Prolong_Yuanbao_Text:SetText(tostring(Player:GetData("YUANBAO")))
	Zuoqi_Comfirm_Button = Mount_Prolong_Frame2_Button;
	--Zuoqi_Comfirm_Button:Disable()
	
	DaysUI = Mount_Prolong_Text_Days;
	PaysUI = Mount_Prolong_Yuanbao_Number;
	
	DaysUI:SetProperty("Visible", "False");
	PaysUI:SetProperty("Visible", "False");

end


function Mount_Prolong_OnShow()

	Mount_Prolong_ResetPos();


end

function Mount_Prolong_OnHiden()
	Mount_Prolong_Clear();
	StopCareObject_Mount_Prolong()
	ZQ_NPC_ID = -1
	this:Hide();
end

function Mount_Prolong_ResetPos()
  Mount_Prolong_Frame:SetProperty("UnifiedPosition", g_Mount_Prolong_Frame_UnifiedPosition);
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_Mount_Prolong()

	this:CareObject(objCared, 1, "Mount_Prolong");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_Mount_Prolong()

	this:CareObject(objCared, 0, "Mount_Prolong");
	objCared = -1;

end

function Mount_Prolong_Clear()

		if Zuoqi_Bagpos ~= -1 then
			Zuoqi_Button : SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(Zuoqi_Bagpos,0);
			Zuoqi_Bagpos = -1;
			DaysUI:SetProperty("Visible", "False");
			PaysUI:SetProperty("Visible", "False");
		end
	--	Zuoqi_Comfirm_Button:Disable()
end


function Mount_Prolong_Update(param0)
	
	local pos_packet =tonumber(param0)
	
	local theAction = EnumAction(pos_packet, "packageitem");
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)

	if theAction:GetID() ~= 0 then

		if(Player:GetLevel() < g_Mount_Prolong_Level) then
			PushDebugMessage("#{XQZJ_180831_09}")  --您的等级不足10级，无法进行此操作。
			return
		end

		local isXushizuoqi = PlayerPackage:IsBagItemXSZQ(pos_packet); 
		--判断是不是续时坐骑
		if isXushizuoqi == 1 then
			--donothing
		elseif isXushizuoqi == 0 then
			PushDebugMessage("#{XQZJ_180831_11}");  --请您放入可续时坐骑。	
			return			
		end

	--是否加锁
	--	if PlayerPackage:IsLock(pos_packet) == 1 then
	--		PushDebugMessage("#{XQZJ_180831_10}");  --当前物品已加锁。
	--		return
	--	end

		local RemainingTime = XushizuoqiGetUsefulLife(pos_packet)
	
		if(RemainingTime == -1)then  
		--还没开始绑定计时
		PushDebugMessage("#{XQZJ_180831_26}"); --已绑定的续期坐骑才可进行续期
			return
		end
		
		Zuoqi_Button:SetActionItem(theAction:GetID());
		PushDebugMessage("#{XQZJ_180831_12}");  --放入坐骑成功。	
		if Zuoqi_Bagpos ~= -1 then
			LifeAbility : Lock_Packet_Item(Zuoqi_Bagpos,0);
		end
			--让之前的东西变亮
			
		Zuoqi_Bagpos = pos_packet;
		LifeAbility : Lock_Packet_Item(Zuoqi_Bagpos,1);
		Zuoqi_ItemIndex = ItemID;
		
		
		DaysUI:SetProperty("Visible", "True");
		PaysUI:SetProperty("Visible", "True");
		--Zuoqi_Comfirm_Button:Enable()

		else

			Zuoqi_Button:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(Zuoqi_Bagpos,0);
			Zuoqi_Bagpos = -1;
			DaysUI:SetProperty("Visible", "False");
			PaysUI:SetProperty("Visible", "False");
		--	Zuoqi_Comfirm_Button:Disable()
			return
		end
end


function Mount_Prolong_Item_RClick()
	
	Mount_Prolong_Clear();
end

function Mount_Prolong_Clicked()
	
	if Zuoqi_Bagpos == -1 then
		PushDebugMessage("#{XQZJ_180831_13}");  --请您放入可续时坐骑。	
		return
	end
	
--	if PlayerPackage:IsLock(Zuoqi_Bagpos) == 1 then
--		PushDebugMessage("#{XQZJ_180831_10}");  --当前物品已加锁。
--		return
--	end
	
	local RemainingTime = XushizuoqiGetUsefulLife(Zuoqi_Bagpos)
	--PushDebugMessage("RemainingTime"..RemainingTime); 
	
	if(RemainingTime == -1)then  
		--还没开始绑定计时
		PushDebugMessage("#{XQZJ_180831_26}"); --已绑定的续期坐骑才可进行续期
	elseif(RemainingTime == -2)	 then
		--过期--从当前日期续期
		PushEvent( "MOUNT_PROLONG_CONFIRM", Zuoqi_Bagpos, ProlongDays );	
	elseif(RemainingTime < ProlongMaxDays - ProlongDays and RemainingTime >= 0) then
		PushEvent( "MOUNT_PROLONG_CONFIRM", Zuoqi_Bagpos, ProlongDays );	--正常续期
	elseif(RemainingTime >= ProlongMaxDays - ProlongDays) then
		PushDebugMessage("#{XQZJ_180831_15}")  --大于可续期上限
	else
		PushDebugMessage("#{XQZJ_180831_13}"); --请您放入可续时坐骑。	
	end
	
--	PushDebugMessage("去执行服务器脚本！"); 
--	Clear_XSCRIPT();
--		Set_XSCRIPT_Function_Name( "DoProlong" );	-- 函数名
--		Set_XSCRIPT_ScriptID( 892941 );			-- 脚本号
--		Set_XSCRIPT_Parameter( 0, Zuoqi_Bagpos );			-- 坐骑bagpos
--		Set_XSCRIPT_ParamCount( 1 );			-- 参数个数
--	Send_XSCRIPT();
end