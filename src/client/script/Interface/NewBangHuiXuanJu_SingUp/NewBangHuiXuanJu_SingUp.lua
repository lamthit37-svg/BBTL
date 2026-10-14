local g_NewBangHuiXuanJu_SingUp_Frame_UnifiedPosition = nil 
local g_NewBangHuiXuanJu_SingUp_buttontype = -1 --1是报名，2是我知道了
local g_objCareID = -1;

local g_CampaignerList = {}

local g_NewBangHuiXuanJu_SingUp_positionInfo = {
	"#G待批准　",
	"#{BHXJ_170606_51}",
	"#{BHXJ_170606_50}",
	"商人　　",
	"#{BHXJ_170606_49}",
	"#{BHXJ_170606_48}",
	"#{BHXJ_170606_47}",
	"#{BHXJ_170606_46}",
	"#{BHXJ_170606_45}",
};

local g_SignUp_UpdataCooldown = 5*1000;	--5s冷却
local g_SignUp_InCooldown = 0

function NewBangHuiXuanJu_SingUp_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("GC_RETELECTIONINFO")

	this:RegisterEvent("OPEN_ELECTION_HELP")
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("GC_LISTCAMPAINER");

end 

-- NewBangHuiXuanJu_SingUp_PageHeader_Name => TLBB_DragTitle
-- NewBangHuiXuanJu_SingUp_Client => DefaultWindow
-- NewBangHuiXuanJu_SingUp_Button_Close => TLBB_ButtonClose
function NewBangHuiXuanJu_SingUp_OnLoad()
	g_NewBangHuiXuanJu_SingUp_Frame_UnifiedPosition = NewBangHuiXuanJu_SingUp_Frame:GetProperty("UnifiedPosition");
	
	g_CampaignerList = {[1] = {name=NewBangHuiXuanJu_SingUp_List1_1, pos=NewBangHuiXuanJu_SingUp_List1_2,score=NewBangHuiXuanJu_SingUp_List1_3},
						[2] = {name=NewBangHuiXuanJu_SingUp_List2_1, pos=NewBangHuiXuanJu_SingUp_List2_2,score=NewBangHuiXuanJu_SingUp_List2_3},
						[3] = {name=NewBangHuiXuanJu_SingUp_List3_1, pos=NewBangHuiXuanJu_SingUp_List3_2,score=NewBangHuiXuanJu_SingUp_List3_3},
						[4] = {name=NewBangHuiXuanJu_SingUp_List4_1, pos=NewBangHuiXuanJu_SingUp_List4_2,score=NewBangHuiXuanJu_SingUp_List4_3},
						[5] = {name=NewBangHuiXuanJu_SingUp_List5_1, pos=NewBangHuiXuanJu_SingUp_List5_2,score=NewBangHuiXuanJu_SingUp_List5_3},
						[6] = {name=NewBangHuiXuanJu_SingUp_List6_1, pos=NewBangHuiXuanJu_SingUp_List6_2,score=NewBangHuiXuanJu_SingUp_List6_3},
						[7] = {name=NewBangHuiXuanJu_SingUp_List7_1, pos=NewBangHuiXuanJu_SingUp_List7_2,score=NewBangHuiXuanJu_SingUp_List7_3},
						[8] = {name=NewBangHuiXuanJu_SingUp_List8_1, pos=NewBangHuiXuanJu_SingUp_List8_2,score=NewBangHuiXuanJu_SingUp_List8_3},
						[9] = {name=NewBangHuiXuanJu_SingUp_List9_1, pos=NewBangHuiXuanJu_SingUp_List9_2,score=NewBangHuiXuanJu_SingUp_List9_3},
						[10] = {name=NewBangHuiXuanJu_SingUp_List10_1, pos=NewBangHuiXuanJu_SingUp_List10_2,score=NewBangHuiXuanJu_SingUp_List10_3},
						}
						
end

function NewBangHuiXuanJu_SingUp_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		NewBangHuiXuanJu_SingUp_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHuiXuanJu_SingUp_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHuiXuanJu_SingUp_On_Hide()
	elseif(event == "GC_RETELECTIONINFO") then
		local n1 = tonumber(arg0)	
		local n2 = tonumber(arg1)	
		local n3 = tonumber(arg2)	
		local n4 = tonumber(arg3)	
		local n5 = tonumber(arg4)	
	elseif(event == "OPEN_ELECTION_HELP") then
		if(arg0 == "3") then
			NewBangHuiXuanJu_SingUp_On_Hide()
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_objCareID) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			NewBangHuiXuanJu_SingUp_StopCareObject(g_objCareID)
			NewBangHuiXuanJu_SingUp_On_Hide()
		end
	elseif(event == "GC_LISTCAMPAINER" ) then
		if tonumber(arg4) == 0 then
			g_objCareID = DataPool : GetNPCIDByServerID(2);
			NewBangHuiXuanJu_SingUp_BeginCareObject(g_objCareID)
			g_NewBangHuiXuanJu_SingUp_buttontype = 1
			NewBangHuiXuanJu_SingUp_Init(0,0,0,0,0)
		else
			this:Hide()
		end
	end
end


function NewBangHuiXuanJu_SingUp_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "NewBangHuiXuanJu_SingUp");
	g_objCareID = -1;
end


function NewBangHuiXuanJu_SingUp_BeginCareObject(objid)
	g_objCareID = objid
	this:CareObject(g_objCareID, 1, "NewBangHuiXuanJu_SingUp");
end


function NewBangHuiXuanJu_SingUp_ViewFrame()
	NewBangHuiXuanJu_SingUp_PageHeader_Name:SetText("#{BHXJ_170607_90}")
	NewBangHuiXuanJu_SingUp_Desc_Text:SetText("#{BHXJ_170606_10}")
	NewBangHuiXuanJu_SingUp_Accept:SetText("#{BHXJ_170606_11}")
	g_NewBangHuiXuanJu_SingUp_buttontype = 2
	this:Show()
	
end

function NewBangHuiXuanJu_SingUp_On_ResetPos()
	NewBangHuiXuanJu_SingUp_Frame:SetProperty("UnifiedPosition", g_NewBangHuiXuanJu_SingUp_Frame_UnifiedPosition)
end

function NewBangHuiXuanJu_SingUp_On_Hide()
	this:Hide()
end

function NewBangHuiXuanJu_SingUp_Button_Close_Click()
	NewBangHuiXuanJu_SingUp_On_Hide()

end


function NewBangHuiXuanJu_SingUp_Init(n1,n2,n3,n4,n5)

	local nCount = Guild:GetCampaignerNum()
	for i = 1,10 do
		g_CampaignerList[i].name:SetText("")
		g_CampaignerList[i].pos:SetText("")
		g_CampaignerList[i].score:SetText("")
	end
	local myrank = Guild:GetCampaignerMyRank()
	
	for i = 0, nCount-1 do
	
		local name, votecount, equipscore, pos = Guild:GetCampaignerinfo(i)
		if name ~= nil then
			if i == myrank then
				g_CampaignerList[i+1].name:SetText("#G"..name)
				g_CampaignerList[i+1].pos:SetText("#G"..g_NewBangHuiXuanJu_SingUp_positionInfo[pos])
				g_CampaignerList[i+1].score:SetText("#G"..equipscore)			
			else
				g_CampaignerList[i+1].name:SetText(name)
				g_CampaignerList[i+1].pos:SetText(g_NewBangHuiXuanJu_SingUp_positionInfo[pos])
				g_CampaignerList[i+1].score:SetText(equipscore)			
			end

		end
	end	
	this:Show()
end


function NewBangHuiXuanJu_SingUp_Accept_Click()
	if(g_NewBangHuiXuanJu_SingUp_buttontype == 1) then
		Guild:AskElectionLeader()
	elseif(g_NewBangHuiXuanJu_SingUp_buttontype == 2) then
		NewBangHuiXuanJu_SingUp_On_Hide()
	end
end


function NewBangHuiXuanJu_SingUp_split(Flag)

	local n1 = math.floor(Flag/10000);
	
	local n2 = math.mod(math.floor(Flag/1000),10);
	
	local n3 = math.mod(math.floor(Flag/100),10);
	
	local n4 = math.mod(math.floor(Flag/10),10);

	local n5 = math.mod(Flag,10);
	
	return n5,n4,n3,n2,n1;
end

function NewBangHuiXuanJu_SingUp_GetColor(ret)

	if ret == 1 then
		return "#{BHXJ_170606_22}"
	else
		return "#{BHXJ_170606_23}"
	end
end

function NewBangHuiXuanJu_SingUp_ShowReadme_Click()
	PushEvent( "UI_COMMAND", 20170620)
end


function NewBangHuiXuanJu_SingUp_F5_Click()
	if g_SignUp_InCooldown == 1 then
		PushDebugMessage("#{BHXJ_170628_97}")
	else
		g_SignUp_InCooldown = 1
		Guild:RefreshCampaignerList(0)
	
		SetTimer("NewBangHuiXuanJu_SingUp","NewBangHuiXuanJu_SingUp_UpdataCooldown()",g_SignUp_UpdataCooldown);
	end
end

function NewBangHuiXuanJu_SingUp_UpdataCooldown()
	g_SignUp_InCooldown = 0;
	KillTimer("NewBangHuiXuanJu_SingUp_UpdataCooldown()");
end