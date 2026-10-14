
function UnionChoose_PreLoad()
	this:RegisterEvent("RAID_UPDATE_INVITATION")
	this:RegisterEvent("OPEN_WINDOW")
end

function UnionChoose_OnLoad()

end

function UnionChoose_OnEvent(event)
	if ( event == "RAID_UPDATE_INVITATION" ) then
		if(this:IsVisible()) then
			UnionChoose_Update()
		end
	elseif (event == "OPEN_WINDOW") then
		if arg0 == "UnionChoose" then
			UnionChoose_Update()
			UnionChoose_InvitationList:SetSelectItem(0)
			this:Show()
		end
	end
end

function UnionChoose_Update()
	UnionChoose_InvitationList:RemoveAllItem()
	local invtCount = Raid:GetInvitationCount()
	if invtCount > 0 then
		for i = 0, invtCount - 1 do
			local name, level = Raid:GetInvitationByIdx(i)
			UnionChoose_InvitationList:AddNewItem(name, 0, i)
			UnionChoose_InvitationList:AddNewItem(level, 1, i)
		end
	end
end

function UnionChoose_Accept_Clicked()
	local selectIdx = UnionChoose_InvitationList:GetSelectItem()
	if selectIdx ~= -1 then
		Player:SendAcceptRaidInvitation(selectIdx)
	end
	this:Hide()
	CloseWindow("Team_Frame", true)
end

function UnionChoose_Cancel_Clicked()
	local selectIdx = UnionChoose_InvitationList:GetSelectItem()
	if selectIdx ~= -1 then
		Player:SendRejectRaidInvitation(selectIdx)
	end
	this:Hide()
end