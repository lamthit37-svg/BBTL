local TARGET_BUFF_MAX = 6;
local TARGET_IMPACT_CTL = {};

local TARGET_IMPACT_NUM = 40; --查询时要从20个里面选出优先级最高的6个

function TargetBuff_PreLoad()
	this:RegisterEvent("MAINTARGET_CHANGED",true);
	this:RegisterEvent("MAINTARGET_OPEN",true);
	this:RegisterEvent("MAINTARGET_BUFF_REFRESH",true);
	this:RegisterEvent("UI_SHOW_2DHEAD",true);
end

function TargetBuff_OnLoad()
	TARGET_IMPACT_CTL[1] = TargetBuff_Image1;
	TARGET_IMPACT_CTL[2] = TargetBuff_Image2;
	TARGET_IMPACT_CTL[3] = TargetBuff_Image3;
	TARGET_IMPACT_CTL[4] = TargetBuff_Image4;
	TARGET_IMPACT_CTL[5] = TargetBuff_Image5;
	TARGET_IMPACT_CTL[6] = TargetBuff_Image6;
end

function TargetBuff_OnEvent( event )

	if(0 == TargetBuff_IsTargetValid()) then
		TargetBuff_Clear();
		this:Hide();
		return;
	end


	if(event == "MAINTARGET_OPEN") then
		--AxTrace(0,0,"event1:"..event);
		TargetBuff_Update();
		TargetBuff_UpdateShow2DHead();
		this:Show();
	elseif(event == "MAINTARGET_CHANGED") then
		if(-1 ~= tonumber(arg0)) then
			--AxTrace(0,0,"event2.1:"..event);
			TargetBuff_Update();
			TargetBuff_UpdateShow2DHead();
			this:Show();
		else
			--AxTrace(0,0,"event2.2:"..event);
			TargetBuff_Clear();
			this:Hide();
		end
	elseif(event == "MAINTARGET_BUFF_REFRESH") then
		--AxTrace(0,0,"event3:"..event);
		TargetBuff_Update();
		TargetBuff_UpdateShow2DHead();
		this:Show();
	end

    if(event == "UI_SHOW_2DHEAD") then
		TargetBuff_UpdateShow2DHead();
		this:Show();
	end
end

-- 返回0，不显示。返回1，显示。
function TargetBuff_IsTargetValid()
	if(Target:IsPresent()) then
		return 1;
	elseif(Target:IsTargetTeamMember()) then
		return 1;
	else
		return 0;
	end
end

function TargetBuff_Update()
	TargetBuff_Clear()
	
	local tblBuff = Target:GetAllBuffIconName();
	for i=1, TARGET_BUFF_MAX do
		local objBuff = tblBuff[i];
		if objBuff ~= nil then
			TARGET_IMPACT_CTL[i]:SetProperty("ShortImage", objBuff.IconName);
			TARGET_IMPACT_CTL[i]:Show();
			TARGET_IMPACT_CTL[i]:SetToolTip(objBuff.Info);
		end
	end
	
end

function TargetBuff_Clear()
	local i = 0;
	while i < TARGET_BUFF_MAX do
		TARGET_IMPACT_CTL[i+1]:SetToolTip("");
		TARGET_IMPACT_CTL[i+1]:Hide();
		i = i + 1;
	end
end

function  TargetBuff_UpdateShow2DHead()

    if 1 == SystemSetup:IsClassic() then
	   	TargetBuff_Frame : SetProperty("UnifiedPosition", "{{0.0,318},{0.0,59}}");
    end
end
