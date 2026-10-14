-- 武林之巅
local g_WuLin_List_Frame_UnifiedPosition = nil 
local g_WuLin_List_CurType = -1
local g_WuLin_List_ButtonList = {}
local g_WuLin_List_RankTypeCount = 16
local g_WuLin_List_RankInfo =
{
	[1] = {ntype=0,name="#{PTFB_191228_147}",menpai = -1},
	[2] = {ntype=1,name="#{PTFB_191228_148}",menpai = 0},
	[3] = {ntype=2,name="#{PTFB_191228_149}",menpai = 1},
	[4] = {ntype=3,name="#{PTFB_191228_150}",menpai = 2},
	[5] = {ntype=4,name="#{PTFB_191228_151}",menpai = 3},
	[6] = {ntype=5,name="#{PTFB_191228_152}",menpai = 4},
	[7] = {ntype=6,name="#{PTFB_191228_153}",menpai = 5},
	[8] = {ntype=7,name="#{PTFB_191228_154}",menpai = 6},
	[9] = {ntype=8,name="#{PTFB_191228_155}",menpai = 7},
	[10] = {ntype=9,name="#{PTFB_191228_156}",menpai = 8},
	[11] = {ntype=10,name="#{PTFB_191228_157}",menpai = 10},
	[12] = {ntype=11,name="#{PTFB_191228_158}",menpai = 11},
	[13] = {ntype=12,name="#{PTFB_191228_159}",menpai = 12},
	[14] = {ntype=13,name="#{PTFB_191228_160}",menpai = 13},
	[15] = {ntype=14,name="#{PTFB_210720_01}",menpai = 14},
	[16] = {ntype=15,name="#{PTFB_240726_01}",menpai = 15},--menpai15
}
function WuLin_List_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("RECIVE_WLZDRANKINGLIST_DATA",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)

end



function WuLin_List_OnLoad()
	g_WuLin_List_Frame_UnifiedPosition = WuLin_List_Frame:GetProperty("UnifiedPosition")
end

function WuLin_List_BeginCareObject(objid)
	if (objid >= 0) then
		this:CareObject(objid, 1)
	end
end


function WuLin_List_OnEvent(event)
	if event == "UI_COMMAND" and arg0 == "20200326" then
		this:Show()
		local srvId = Get_XParam_INT(0)
		local npcid = Target:GetServerId2ClientId(srvId)
		WuLin_List_BeginCareObject(npcid)
		WuLin_List_Init()
		this:Activate()
	elseif event == "RECIVE_WLZDRANKINGLIST_DATA" then
		
		local nType  = tonumber(arg0)
		WuLin_List_OnShow(nType)
	elseif(event == "ADJEST_UI_POS") then
		WuLin_List_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_List_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_ListClose()	
	end

end

function WuLin_List_On_ResetPos()
	WuLin_List_Frame:SetProperty("UnifiedPosition", g_WuLin_List_Frame_UnifiedPosition)
end



function WuLin_List_Init()
	WuLin_ListDown_LeftList:Clear()
	WuLin_ListDown_RightListFrame:Clear()
	WuLin_List_AItem_MyRank:SetText("")
	WuLin_List_AItem_MyName:SetText("")
	WuLin_List_AItem_MyNum:SetText("")
	WuLin_List_AItem_MyTime:SetText("")
	local menpai = Player : GetData( "MEMPAI" );		--??????ID
	g_WuLin_List_ButtonList = {}
	local nAsktype = 0
	for i=1, g_WuLin_List_RankTypeCount, 1 do
		local ItemBar = WuLin_ListDown_LeftList:AddChild("WuLin_ListDown_LeftList_AItem")
		ItemBar:GetSubItem("WuLin_ListDown_LeftList_AItemSchool"):SetText(g_WuLin_List_RankInfo[i].name)
		ItemBar:GetSubItem("WuLin_ListDown_LeftList_AItemSchoolBK"):SetEvent("MouseButtonDown","WuLin_List_On_ListLeftClick("..g_WuLin_List_RankInfo[i].ntype..")")
		-- ItemBar:SetEvent( "MouseLClick", "WuLin_List_On_ListLeftClick("..g_WuLin_List_RankInfo[i].ntype..")" )
		if menpai == g_WuLin_List_RankInfo[i].menpai then
			nAsktype = g_WuLin_List_RankInfo[i].ntype
		end
		table.insert(g_WuLin_List_ButtonList,{ctrl = ItemBar, type = g_WuLin_List_RankInfo[i].ntype})
	end -- end for
	--WuLin_ListDown_LeftList:SetScrollPosition(0)
	


	Player:AskWLZDRankingList(nAsktype)
end

function WuLin_ListClose()
	PushEvent("CLOSE_WULIN_TEAMDET")
	this:Hide()
end

function WuLin_ListDown_LeftList_OnButtonClicked()

end


function WuLin_List_Newelement(ntype,Index)
	local a = {}
	local ItemBar = WuLin_ListDown_RightListFrame:AddChild("WuLin_List_AItem")
	a.txt[1] = ItemBar:GetSubItem("WuLin_List_AItem_Rank")
	a.txt[2] = ItemBar:GetSubItem("WuLin_List_AItem_Name")
	a.txt[3] = ItemBar:GetSubItem("WuLin_List_AItem_Num")
	a.txt[4] = ItemBar:GetSubItem("WuLin_List_AItem_Time")	
	ItemBar:SetEvent( "MouseLClick", "WuLin_List_On_ListRightClick("..Index..")" )
	return a

end



function WuLin_List_OnShow(nType)

	g_WuLin_List_CurType = nType
	WuLin_ListDown_LeftList:SetSelected(nType+1)
	WuLin_ListDown_LeftList:SetScrollPosition4Index(nType)
	WuLin_ListDown_RightListFrame:Clear()
	
	
	for i,v in ipairs(g_WuLin_List_ButtonList) do
		if v.type == nType then
			v.ctrl:GetSubItem("WuLin_ListDown_LeftList_AItemSchoolBK"):SetCheck(1)
		else
			v.ctrl:GetSubItem("WuLin_ListDown_LeftList_AItemSchoolBK"):SetCheck(0)
		end
	end

	local nDataCount = DataPool:GetWLZDRankingListDataCount()
	
	if nDataCount <= 0 then
		WuLin_List_FillMyInfoNone()
		return 
	end
	
	local myRank = -1
	local myRankfloor = -1
	local myRankTime = 0
	for i = 0, nDataCount-1 do
		local nRank,name,floor,usetime = DataPool:GetWLZDRankingListInfo(i);
		
		for j = 1,6 do
			local bValid,membname,menpai,level,score = DataPool:GetMLZDRankingListMemberInfo(i,j-1);

			if bValid == 1 and myRank < 0 then
				if membname == Player:GetName() then
					myRank = nRank
					myRankfloor = floor
					myRankTime = usetime
				end
			end
		end
		WuLin_List_AddNewItem(i,nRank,name,floor,usetime)

	end	
	if myRank > 0 then
		WuLin_List_FillMyInfo(myRank,myRankfloor,myRankTime)
	else
		WuLin_List_FillMyInfoNone()
	end
end


function WuLin_List_FillMyInfoNone()
	WuLin_List_AItem_MyRank:SetText("#{PTFB_191228_166}")
	WuLin_List_AItem_MyName:SetText(Player:GetName())
	local myfloor,myusetime = DataPool:GetWLZDRankingListMyInfo()
	WuLin_List_AItem_MyNum:SetText(myfloor)
	WuLin_List_AItem_MyTime:SetText("--:--")

end


function WuLin_List_FillMyInfo(myRank,myRankfloor,myRankTime)
	WuLin_List_AItem_MyRank:SetText(myRank)
	WuLin_List_AItem_MyName:SetText(Player:GetName())
	WuLin_List_AItem_MyNum:SetText(myRankfloor)
	WuLin_List_AItem_MyTime:SetText(WuLin_List_FormatTime(myRankTime))
end

function WuLin_List_On_ListLeftClick(index)
	Player:AskWLZDRankingList(index)
	--WuLin_ListDown_LeftList:SetSelected(index+1)
end

function WuLin_List_On_ListRightClick(index)
	if g_WuLin_List_CurType == 0 then
		PushEvent("OPEN_WLZDRANKLIST_TEAM",index)
	end
end

function WuLin_List_AddNewItem(index,rank,name,floor,usetime)
	local element = WuLin_List_Newelement(nType,index);
	element.txt[1]:SetText(rank)
	element.txt[2]:SetText(name)
	element.txt[3]:SetText(floor)
	element.txt[4]:SetText(WuLin_List_FormatTime(usetime))
end

function WuLin_List_FormatTime(nSec)
	local min = math.floor(nSec/60)
	local sec = math.mod(nSec,60)
	
	if min < 10 then
		return string.format("%02d:%02d",min,sec)
	else
		return string.format("%d:%02d",min,sec)
	end
	
end