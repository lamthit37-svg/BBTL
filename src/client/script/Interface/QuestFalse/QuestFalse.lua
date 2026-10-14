
function QuestFalse_PreLoad()
	this:RegisterEvent("OPEN_QUESTFALSE");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function QuestFalse_OnLoad()
end

function QuestFalse_OnEvent(event)
	if ( event == "OPEN_QUESTFALSE" ) then
		QuestFalse_Open(arg0)
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	end
end

function QuestFalse_Open(arg0)
	if arg0 == nil then
		return
	end

	--if arg0 == "Fuli_NewSalaryTask" or arg0 == "NewSalaryTaskSP" then
		--QuestFalse_Title:SetText("#{FLJM_170527_05}")
		--QuestFalseGreeting_Desc:SetText("#{GZGZ_120514_48}")
	--end

	this:Show();
end

function QuestFalse_Closed()
		this:Hide();
end



function QuestFalse_OnHidden()
		this:Hide()
end
