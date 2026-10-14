local g_XSPV_Frame_UnifiedXPosition
local g_XSPV_Frame_UnifiedYPosition
local Xuanshang_Preview_AwardItemList = {}
local Xuanshang_Preview_abArr = {}
local Xuanshang_Preview_aniArr = {}
local Xuanshang_Preview_maskArr = {}
local Xuanshang_Preview_BindArr = {}

function Xuanshang_Preview_PreLoad()
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OPEN_BOUNTY_PREVIEW",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end


function Xuanshang_Preview_OnLoad()
	g_XSPV_Frame_UnifiedXPosition	= Xuanshang_Preview_Frame_BK : GetProperty("UnifiedXPosition")
	g_XSPV_Frame_UnifiedYPosition	= Xuanshang_Preview_Frame_BK : GetProperty("UnifiedYPosition")
	
	Xuanshang_Preview_abArr[1] = "Xuanshang_Preview_Skill1_BKG"
	Xuanshang_Preview_abArr[2] = "Xuanshang_Preview_Skill2_BKG"
	Xuanshang_Preview_abArr[3] = "Xuanshang_Preview_Skill3_BKG"
	Xuanshang_Preview_abArr[4] = "Xuanshang_Preview_Skill4_BKG"
	Xuanshang_Preview_abArr[5] = "Xuanshang_Preview_Skill5_BKG"
	Xuanshang_Preview_abArr[6] = "Xuanshang_Preview_Skill6_BKG"
	
	Xuanshang_Preview_aniArr[1] = "Xuanshang_Preview_Skill1_Frame"
	Xuanshang_Preview_aniArr[2] = "Xuanshang_Preview_Skill2_Frame"
	Xuanshang_Preview_aniArr[3] = "Xuanshang_Preview_Skill3_Frame"
	Xuanshang_Preview_aniArr[4] = "Xuanshang_Preview_Skill4_Frame"
	Xuanshang_Preview_aniArr[5] = "Xuanshang_Preview_Skill5_Frame"
	Xuanshang_Preview_aniArr[6] = "Xuanshang_Preview_Skill6_Frame"

	Xuanshang_Preview_BindArr[1] = "Xuanshang_Preview_Skill1_Feibang"
	Xuanshang_Preview_BindArr[2] = "Xuanshang_Preview_Skill2_Feibang"
	Xuanshang_Preview_BindArr[3] = "Xuanshang_Preview_Skill3_Feibang"
	Xuanshang_Preview_BindArr[4] = "Xuanshang_Preview_Skill4_Feibang"
	Xuanshang_Preview_BindArr[5] = "Xuanshang_Preview_Skill5_Feibang"
	Xuanshang_Preview_BindArr[6] = "Xuanshang_Preview_Skill6_Feibang"

	Xuanshang_Preview_maskArr[1] = "Xuanshang_Preview_Skill1_BKG_Mask"
	Xuanshang_Preview_maskArr[2] = "Xuanshang_Preview_Skill2_BKG_Mask"
	Xuanshang_Preview_maskArr[3] = "Xuanshang_Preview_Skill3_BKG_Mask"
	Xuanshang_Preview_maskArr[4] = "Xuanshang_Preview_Skill4_BKG_Mask"
	Xuanshang_Preview_maskArr[5] = "Xuanshang_Preview_Skill5_BKG_Mask"
	Xuanshang_Preview_maskArr[6] = "Xuanshang_Preview_Skill6_BKG_Mask"
end

function Xuanshang_Preview_OnEvent(event)
	if( event == "OPEN_BOUNTY_PREVIEW") then
		Xuanshang_Preview_Open()	
	elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		Xuanshang_Preview_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Xuanshang_Preview_Cancel_Clicked()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_Xuanshang_Preview_ClientObjid) then
			return
		end

		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
			Xuanshang_Preview_Cancel_Clicked()
		end
	end
	
end

function Xuanshang_Preview_Open()	

	Xuanshang_Preview_StyleList:Clear()
	Xuanshang_Preview_AwardItemList={}
	local nCurDay = DataPool:GetServerDayTime()
	local nCurMinute = DataPool:GetServerMinuteTime()

	for x=1,60 do
		local ds,dt,taskNum,itemID,displayID,forceBind,itemCount,uiSeq,precious = ZhanTuanInterface:GetBountyTaskInfoByUISeq(x)
		local lineidx = math.mod(x-1, 6) + 1
		local arrIdx = math.floor(x-1/6) + 1
		if displayID==nil or displayID <= 0 then
			continue
		end
		if lineidx == 1 then
			local childitem = Xuanshang_Preview_StyleList:AddChild("Xuanshang_Preview_Item")
			Xuanshang_Preview_AwardItemList[arrIdx].citem = childitem
			for x2=1,6 do
				childitem:GetSubItem(Xuanshang_Preview_abArr[x2]):Hide()
			end
		end
		
		local theItem = Xuanshang_Preview_AwardItemList[arrIdx].citem
		local theAction = DataPool:CreateActionItemForShow(displayID, itemCount)
		if theAction:GetID() ~= 0 then
			theItem:GetSubItem(Xuanshang_Preview_abArr[lineidx]):Show()
			theItem:GetSubItem(Xuanshang_Preview_abArr[lineidx]):SetActionItem(theAction:GetID())	
		end
		
		if (nCurDay > dt) then
			theItem:GetSubItem(Xuanshang_Preview_maskArr[lineidx]):Show()
		elseif (nCurDay == dt and nCurMinute >= 213000) then
			theItem:GetSubItem(Xuanshang_Preview_maskArr[lineidx]):Show()
		else
			theItem:GetSubItem(Xuanshang_Preview_maskArr[lineidx]):Hide()
		end
		
		if precious==1 then
			theItem:GetSubItem(Xuanshang_Preview_aniArr[lineidx]):Show()
		else
			theItem:GetSubItem(Xuanshang_Preview_aniArr[lineidx]):Hide()
		end
		
		if forceBind==1 then
			theItem:GetSubItem(Xuanshang_Preview_BindArr[lineidx]):Hide()
		else
			theItem:GetSubItem(Xuanshang_Preview_BindArr[lineidx]):Show()
		end
			
	end
	this:Show()
end

function Xuanshang_Preview_On_ResetPos()
	Xuanshang_Preview_Frame_BK : SetProperty("UnifiedXPosition", g_XSPV_Frame_UnifiedXPosition)
	Xuanshang_Preview_Frame_BK : SetProperty("UnifiedYPosition", g_XSPV_Frame_UnifiedYPosition)
end

function Xuanshang_Preview_Cancel_Clicked()
	Xuanshang_Preview_OnHidden()
end

function Xuanshang_Preview_OnHidden()

	this:Hide()
end


function Xuanshang_Preview_Clicked(idx)

end
