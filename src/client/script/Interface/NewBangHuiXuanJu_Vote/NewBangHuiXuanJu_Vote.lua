local g_NewBangHuiXuanJu_Vote_Frame_UnifiedPosition = nil 
local g_state = -1	-- 1可投票，2是不可投票

local g_objCareID = -1;

local g_NewBangHuiXuanJu_Vote_positionInfo = {
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

local g_Picture_Top = 
{
	[0] = {"CommonFrame28","BHXJ_NO1"},
	[1] = {"CommonFrame28","BHXJ_NO2"},
	[2] = {"CommonFrame28","BHXJ_NO3"},
	[3] = {"Ach1","WDTXPMBtn_4_Normal"},
	[4] = {"Ach1","WDTXPMBtn_5_Normal"},
	[5] = {"Ach1","WDTXPMBtn_6_Normal"},
	[6] = {"Ach1","WDTXPMBtn_7_Normal"},
	[7] = {"Ach1","WDTXPMBtn_8_Normal"},
	[8] = {"Ach1","WDTXPMBtn_9_Normal"},
	[9] = {"Ach1","WDTXPMBtn_10_Normal"},
}

local g_Vote_UpdataCooldown = 5*1000;	--5s冷却
local g_Vote_InCooldown = 0
function NewBangHuiXuanJu_Vote_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("GC_LISTCAMPAINER")
	this:RegisterEvent("OBJECT_CARED_EVENT",false);

end 

-- NewBangHuiXuanJu_Vote_DragTitle => TLBB_DragTitle
-- NewBangHuiXuanJu_Vote_Client => DefaultWindow
-- NewBangHuiXuanJu_Vote_Close => TLBB_ButtonClose
function NewBangHuiXuanJu_Vote_OnLoad()
	g_NewBangHuiXuanJu_Vote_Frame_UnifiedPosition = NewBangHuiXuanJu_Vote_Frame:GetProperty("UnifiedPosition");
end

function NewBangHuiXuanJu_Vote_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		NewBangHuiXuanJu_Vote_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHuiXuanJu_Vote_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHuiXuanJu_Vote_On_Hide()
	elseif(event == "GC_LISTCAMPAINER" ) then
		if  tonumber(arg4) == 1 then
			this:Show()
			g_objCareID = DataPool : GetNPCIDByServerID(2);
			NewBangHuiXuanJu_Vote_BeginCareObject(g_objCareID)
		
			g_Vote_nContentButton = {}
			local votenum = tonumber(arg0)
			local votevalid = tonumber(arg1)
			g_state = tonumber(arg2)
			local myvoterank = tonumber(arg3)
			if g_state == 1 then
				NewBangHuiXuanJu_Vote_Explain:SetText("#{BHXJ_170606_37}")
			elseif g_state == 2 then
				NewBangHuiXuanJu_Vote_Explain:SetText("#{BHXJ_170606_40}")
			end
			NewBangHuiXuanJu_Vote_Test(myvoterank)
			local str1,str2,str3 = NewBangHuiXuanJu_Vote_GetValidStr(votenum,votevalid)
			local finstr = ScriptGlobal_Format("#{BHXJ_170606_56}",str1,str2,str3)
			-- NewBangHuiXuanJu_Vote_ResultExplain1:SetText(finstr)
			this:Show()
		else
			this:Hide()
			
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_objCareID) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			NewBangHuiXuanJu_Vote_StopCareObject(g_objCareID)
			NewBangHuiXuanJu_Vote_On_Hide()
		end		
	end
end


function NewBangHuiXuanJu_Vote_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "NewBangHuiXuanJu_Vote");
	g_objCareID = -1;
end

function NewBangHuiXuanJu_Vote_BeginCareObject(objid)
	g_Object = objid
	this:CareObject(g_Object, 1, "NewBangHuiXuanJu_Vote");
end


function NewBangHuiXuanJu_Vote_GetValidStr(votenum,votevalid)

	local param1,param2,param3
	if votenum < 3 then
		param1 = "#{BHXJ_170606_23}"..votenum
	else
		param1 = "#{BHXJ_170606_22}"..votenum
	end
	
	param2 = tostring(votevalid)
	
	if (votenum/votevalid < 0.5) or votenum < 3 then
		param3 = "#{BHXJ_170606_58}"
	else
		param3 = "#{BHXJ_170606_57}"
	end
	
	return param1,param2,param3	
end


function NewBangHuiXuanJu_Vote_ListBk_MyEnroll_Click()
	local myrank = Guild:GetCampaignerMyRank()
	
	for i,v in ipairs(g_Vote_nContentButton) do
		if i == myrank+1 then
			v:SetBarButtonSelected(true)
		else
			v:SetBarButtonSelected(false)
		end
	end
	
	if(myrank >= 0) then
		NewBangHuiXuanJu_Vote_ListBk_List:SetVertScrollbarPosition(80.0*myrank)
	else
		PushDebugMessage("#{BHXJ_170621_91}")
	end
end


function NewBangHuiXuanJu_Vote_ListBk_Refresh_Click()
	if g_Vote_InCooldown == 1 then
		PushDebugMessage("#{BHXJ_170628_97}")
	else
		g_Vote_InCooldown = 1
		Guild:RefreshCampaignerList(1)
	
		SetTimer("NewBangHuiXuanJu_Vote","NewBangHuiXuanJu_Vote_UpdataCooldown()",g_Vote_UpdataCooldown);
	end

end

function NewBangHuiXuanJu_Vote_UpdataCooldown()

	g_Vote_InCooldown = 0;
	KillTimer("NewBangHuiXuanJu_Vote_UpdataCooldown()");
end



function NewBangHuiXuanJu_Vote_InsertInfo(szName,Votecount,equipscore,pos,index,myvoterank)
	local ItemBar = NewBangHuiXuanJu_Vote_ListBk_List:AddItemElement( "NewBHXJList", "LEFT", "NewBangHuiXuanJu_Vote","" ,"")

	ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	ItemBar:SetText1(ScriptGlobal_Format("#{BHXJ_170606_41}",szName))
	ItemBar:SetText2(ScriptGlobal_Format("#{BHXJ_170606_42}",equipscore))
	ItemBar:SetText3(ScriptGlobal_Format("#{BHXJ_170606_43}",Votecount))
	ItemBar:SetText4(ScriptGlobal_Format("#{BHXJ_170606_44}",g_NewBangHuiXuanJu_Vote_positionInfo[pos]))
	
	ItemBar:SetButton1Text("#{BHXJ_170606_52}")
	if g_state == 2 then
		ItemBar:SetButton1State(false)
	else
		if myvoterank >= 0 then
			if myvoterank == index then
				ItemBar:SetButton1Text("已投票")
				ItemBar:SetButton1State(false)
			else
				ItemBar:SetButton1State(false)
			
			end
		
		else
			ItemBar:SetButton1State(true)
		end
	end

	ItemBar:SetButton1Tips("#{BHXJ_170606_53}")
	ItemBar:SetButton2Text("#{BHXJ_170606_54}")
	
	if g_Picture_Top[index] ~= nil then
		if index >= 0 and index <= 2 then
			ItemBar:SetImage2(g_Picture_Top[index][1],g_Picture_Top[index][2])
			ItemBar:SetImage2Show()		
			ItemBar:SetImage1Hide()
		else
			ItemBar:SetImage1(g_Picture_Top[index][1],g_Picture_Top[index][2])
			ItemBar:SetImage1Show()
			ItemBar:SetImage2Hide()
		end
		-- PushDebugMessage(g_Picture_Top[i][1]..","..g_Picture_Top[i][2])
	end
	
	
	table.insert( g_Vote_nContentButton, ItemBar )
	
end
function NewBangHuiXuanJu_Vote_Test(myvoterank)
	NewBangHuiXuanJu_Vote_ListBk_List:CleanAllElement("NewBangHuiXuanJu_Vote")
	local nCount = Guild:GetCampaignerNum()
	
	for i = 0, nCount-1 do
	
		local name, votecount, equipscore, pos = Guild:GetCampaignerinfo(i)
		if name ~= nil then
			NewBangHuiXuanJu_Vote_InsertInfo(name,votecount,equipscore,pos,i,myvoterank)
		end
	end
	


	NewBangHuiXuanJu_Vote_ListBk_List:Show()
	NewBangHuiXuanJu_Vote_ListBk_List:Flash()	
end

function NewBangHuiXuanJu_Vote_On_ResetPos()
	NewBangHuiXuanJu_Vote_Frame:SetProperty("UnifiedPosition", g_NewBangHuiXuanJu_Vote_Frame_UnifiedPosition)
end

function NewBangHuiXuanJu_Vote_On_Hide()
	this:Hide()
end

function NewBangHuiXuanJu_Vote_Close_Click()
	this:Hide()
end


function NewBangHuiXuanJu_Vote_Explain1_btn_Click()
	 PushEvent( "UI_COMMAND", 20170620)
end


function NewBangHuiXuanJu_Vote_ResultExplain_Click()
	PushEvent( "OPEN_ELECTION_HELP", 1)
end
function NewBangHuiXuanJu_Vote_OnButton1Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	Guild:VoteCampaigner(nIndex)
end


function NewBangHuiXuanJu_Vote_OnButton2Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	local name = Guild:GetCampaignerinfo(nIndex)
	DataPool:ShowChatInfo(name)
	
end


function NewBangHuiXuanJu_Vote_OnItemClick()

	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if not nIndex then
		return
	end
	
	
	for i,v in ipairs(g_Vote_nContentButton) do
		if i == nIndex+1 then
			v:SetBarButtonSelected(true)
		else
			v:SetBarButtonSelected(false)
		end
	end
	
end


