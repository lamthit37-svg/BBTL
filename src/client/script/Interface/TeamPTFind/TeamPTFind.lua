local g_Menpai = {
	"#{GMGameInterface_Script_DataPool_Info_ShaoLin}",
	"#{GMGameInterface_Script_DataPool_Info_Mingjiao}",
	"#{GMGameInterface_Script_DataPool_Info_GaiBang}",
	"#{GMGameInterface_Script_DataPool_Info_WuDang}",
	"#{GMGameInterface_Script_DataPool_Info_EMei}",
	"#{GMGameInterface_Script_DataPool_Info_XingXiu}",
	"#{GMGameInterface_Script_DataPool_Info_DaLi}",
	"#{GMGameInterface_Script_DataPool_Info_TianShan}",
	"#{GMGameInterface_Script_DataPool_Info_XiaoYao}",
	"#{GMGameInterface_Script_DataPool_Info_WuMenPai}",
	"#{GMGameInterface_Script_DataPool_Info_GuSu}",
	"#{XMPTM_130123_02}",
	"#{XMPGG_160524_02}", -- 鬼谷  
	"#{XQ_MP_15}", --桃花岛  
	"#{XMPHM_210604_01}",
	"#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
};

local g_isModify = 0;

function TeamPTFind_PreLoad()
	this:RegisterEvent("OPEN_WINDOW");
	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("TEAMBOARD_MODIFY_USER");
end


--初始化窗口的一些参数
function TeamPTFind_InitWindow()
	TeamPTFind_Name:SetText("#{INTERFACE_XML_773}".. Player:GetName());
	TeamPTFind_Level:SetText("#{ZDPT_XML_29}:"..Player:GetData("LEVEL"));

	local nMenpai = tonumber(Player:GetData("MEMPAI")) + 1;
	local strMenpai = g_Menpai[nMenpai];
	if strMenpai ~= nil then
		TeamPTFind_MenPai:SetText("#{ZDPT_XML_28}:"..strMenpai);
	end
	TeamPTFind_EditName:SetText(ParserString("ZDPT_091028_16","NoColor"))
	TeamPTFind_Cancel: SetText("#{INTERFACE_XML_542}");
	TeamPTFind_Mudi: SetCurrentSelect(0)--默认 任意;
	g_isModify = 0;
end

function TeamPTFind_OnLoad()
	TeamPTFind_Mudi:ResetList()
	local num = DataPool : GetTeamBoardGoalNum();
	if (num > 0) then
		for i = 0, num-1 do
			local _id,_name =DataPool : EnumTeamBoardGoal(i);
			if( _id >= 0 ) then
				TeamPTFind_Mudi:ComboBoxAddItem(_name,_id);
			end
		end
	end
end

function TeamPTFind_OnEvent( event )
	if(event == "OPEN_WINDOW") then
		if( arg0 == "TeamPTFindWindow") then
			--如果已经显示就应该关掉
			if ( this:IsVisible() ) then
				this:Hide();
				return;
			end
			TeamPTFind_InitWindow();
			CloseWindow("TeamPTZhaomuWindow")
			this:Show();
		end

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "TeamPTFindWindow") then
			this:Hide();
		end
	elseif(event == "TEAMBOARD_MODIFY_USER") then
		TeamPTFind_Modify(arg0,arg1)
		this:Show();
	end
end

function TeamPTFind_Modify(strTopic,strGoal)
	TeamPTFind_Name:SetText("#{INTERFACE_XML_773}".. Player:GetName());
	TeamPTFind_Level:SetText("#{ZDPT_XML_29}:"..Player:GetData("LEVEL"));

	local nMenpai = tonumber(Player:GetData("MEMPAI")) + 1;
	local strMenpai = g_Menpai[nMenpai];
	if strMenpai ~= nil then
		TeamPTFind_MenPai:SetText("#{ZDPT_XML_28}:"..strMenpai);
	end
	TeamPTFind_EditName:SetText(strTopic)
	TeamPTFind_Mudi: SetCurrentSelect(tonumber(strGoal))--默认 任意;
	TeamPTFind_Cancel: SetText("#{ZDPT_XML_23}");
	g_isModify = 1;

end
function TeamPTFind_Accept_Clicked()
	if( tonumber( Player:IsInTeam() ) == 1 ) then
		PushDebugMessage("#{ZDPT_091028_5}");
		return;
	end
	local strTopic = TeamPTFind_EditName:GetText();
	if( strTopic == "" ) then
		PushDebugMessage("#{ZDPT_091028_15}");
		return;
	end
	local strGoal, nGoalIndex = TeamPTFind_Mudi:GetCurrentSelect();

	if TeamBoardDataPool:SendUserSeekInfo(strTopic,nGoalIndex,g_isModify) < 0 then
		return
	end
	this:Hide();
end

function TeamPTFind_Close_Clicked()
	this:Hide();
end
function TeamPTFind_Cancel_Clicked()
	if g_isModify == 0 then
		this:Hide();
	else
		DataPool:OpenDelCheckBox(0);
	end
end


function TeamPTFind_ComboListChanged()
end
