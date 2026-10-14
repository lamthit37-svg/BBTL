--******************************************
--周常肉鸽爬塔副本	展示buff界面
--create by  limengyue 
--2024-03-07
--******************************************

local g_Rouge_ShowBuff_Frame_UnifiedPosition;


local g_Buff_Info =	--boss不同图片
{
	[1] = {nBuffId = 52808,nName="#{RGPT_231130_480}",nBuffTips="#{RGPT_231130_507}",nBuffImg="set:Buff34 image:Buff34_11",},
	[2] = {nBuffId = 52809,nName="#{RGPT_231130_481}",nBuffTips="#{RGPT_231130_508}",nBuffImg="set:Buff34 image:Buff34_12",},
	[3] = {nBuffId = 52810,nName="#{RGPT_231130_482}",nBuffTips="#{RGPT_231130_509}",nBuffImg="set:Buff34 image:Buff34_13",},
	[4] = {nBuffId = 52811,nName="#{RGPT_231130_483}",nBuffTips="#{RGPT_231130_510}",nBuffImg="set:Buff34 image:Buff34_14",},
	[5] = {nBuffId = 52812,nName="#{RGPT_231130_484}",nBuffTips="#{RGPT_231130_511}",nBuffImg="set:Buff34 image:Buff34_15",},
	[6] = {nBuffId = 52813,nName="#{RGPT_231130_485}",nBuffTips="#{RGPT_231130_512}",nBuffImg="set:Buff34 image:Buff34_16",},
	[7] = {nBuffId = 52814,nName="#{RGPT_231130_486}",nBuffTips="#{RGPT_231130_513}",nBuffImg="set:Buff35 image:Buff35_1",},
	[8] = {nBuffId = 52815,nName="#{RGPT_231130_487}",nBuffTips="#{RGPT_231130_514}",nBuffImg="set:Buff35 image:Buff35_2",},
	[9] = {nBuffId = 52816,nName="#{RGPT_231130_488}",nBuffTips="#{RGPT_231130_515}",nBuffImg="set:Buff35 image:Buff35_3",},
	[10] = {nBuffId = 52820,nName="#{RGPT_231130_489}",nBuffTips="#{RGPT_231130_516}",nBuffImg="set:Buff35 image:Buff35_4",},
	[11] = {nBuffId = 52821,nName="#{RGPT_231130_490}",nBuffTips="#{RGPT_231130_517}",nBuffImg="set:Buff35 image:Buff35_5",},
	[12] = {nBuffId = 52822,nName="#{RGPT_231130_491}",nBuffTips="#{RGPT_231130_518}",nBuffImg="set:Buff35 image:Buff35_6",},
	[13] = {nBuffId = 52823,nName="#{RGPT_231130_492}",nBuffTips="#{RGPT_231130_519}",nBuffImg="set:Buff35 image:Buff35_7",},
	[14] = {nBuffId = 52824,nName="#{RGPT_231130_493}",nBuffTips="#{RGPT_231130_520}",nBuffImg="set:Buff35 image:Buff35_8",},
	[15] = {nBuffId = 52825,nName="#{RGPT_231130_494}",nBuffTips="#{RGPT_231130_521}",nBuffImg="set:Buff35 image:Buff35_9",},
	[16] = {nBuffId = 52826,nName="#{RGPT_231130_495}",nBuffTips="#{RGPT_231130_522}",nBuffImg="set:Buff35 image:Buff35_10",},
	[17] = {nBuffId = 52827,nName="#{RGPT_231130_496}",nBuffTips="#{RGPT_231130_523}",nBuffImg="set:Buff35 image:Buff35_11",},
	[18] = {nBuffId = 52828,nName="#{RGPT_231130_497}",nBuffTips="#{RGPT_231130_524}",nBuffImg="set:Buff35 image:Buff35_12",},
	[19] = {nBuffId = 52833,nName="#{RGPT_231130_498}",nBuffTips="#{RGPT_231130_525}",nBuffImg="set:Buff35 image:Buff35_14",},
	[20] = {nBuffId = 52834,nName="#{RGPT_231130_499}",nBuffTips="#{RGPT_231130_526}",nBuffImg="set:Buff35 image:Buff35_15",},
	[21] = {nBuffId = 52835,nName="#{RGPT_231130_500}",nBuffTips="#{RGPT_231130_527}",nBuffImg="set:Buff35 image:Buff35_16",},
	[22] = {nBuffId = 52837,nName="#{RGPT_231130_501}",nBuffTips="#{RGPT_231130_528}",nBuffImg="set:Buff36 image:Buff36_2",},
	[23] = {nBuffId = 52838,nName="#{RGPT_231130_502}",nBuffTips="#{RGPT_231130_529}",nBuffImg="set:Buff36 image:Buff36_3",},
	[24] = {nBuffId = 52839,nName="#{RGPT_231130_503}",nBuffTips="#{RGPT_231130_530}",nBuffImg="set:Buff36 image:Buff36_4",},
	[25] = {nBuffId = 52841,nName="#{RGPT_231130_504}",nBuffTips="#{RGPT_231130_531}",nBuffImg="set:Buff36 image:Buff36_6",},
	[26] = {nBuffId = 52842,nName="#{RGPT_231130_505}",nBuffTips="#{RGPT_231130_532}",nBuffImg="set:Buff36 image:Buff36_7",},
	[27] = {nBuffId = 52843,nName="#{RGPT_231130_506}",nBuffTips="#{RGPT_231130_533}",nBuffImg="set:Buff36 image:Buff36_8",},
}


local g_Pata_targetId = -1;
--===============================================
-- OnLoad()
--===============================================
function Rouge_ShowBuff_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--===============================================
-- OnLoad()
--===============================================
function Rouge_ShowBuff_OnLoad()   
	-- 保存界面的默认相对位置
	g_Rouge_ShowBuff_Frame_UnifiedPosition = Rouge_ShowBuff_MainFrame:GetProperty("UnifiedPosition");
	
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Rouge_ShowBuff_Frame_On_ResetPos()
	Rouge_ShowBuff_MainFrame:SetProperty("UnifiedPosition", g_Rouge_ShowBuff_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function Rouge_ShowBuff_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 99894715) then
		--打开界面
		if(IsWindowShow("Rouge_ShowBuff")) then
			CloseWindow("Rouge_ShowBuff", true)
		end
		Rouge_ShowBuff_Open(Get_XParam_INT(0),Get_XParam_INT(1))
	end
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Rouge_ShowBuff_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Rouge_ShowBuff_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       Rouge_ShowBuff_OnClose()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end
         
end

--===============================================
-- Rouge_ShowBuff_OnClose()
--===============================================
function Rouge_ShowBuff_OnClose()
	this:Hide()
end


--=========================================================
--默认打开界面
--nBuffId boss索引
--nRandomList本期场地元素列表 需要拆分
--=========================================================
function Rouge_ShowBuff_Open(nBuffID,nType)
	--PushDebugMessage(" nBuffID="..nBuffID)
	--如果未获得
	if nBuffID < 0 then
		--显示未获得
		Rouge_ShowBuff_Client1:Hide()
		Rouge_ShowBuff_Client2:Show()
		if  nType == 2 then
			Rouge_ShowBuff_Client2_Text:SetText("#{RGPT_231130_633}");
		else
			Rouge_ShowBuff_Client2_Text:SetText("#{RGPT_231130_476}");
		end
		Rouge_ShowBuff_BK:SetProperty( "Image","set:RouGe1 image:Defeat")
	else
		--显示buff信息
		Rouge_ShowBuff_Client1:Show()
		Rouge_ShowBuff_Client2:Hide()
		if  nType == 1 then
			--buff
			Rouge_ShowBuff_BK:SetProperty( "Image","set:RouGe1 image:Success")
			Rouge_ShowBuff_Client1_Text:SetText("#{RGPT_231130_478}");
			--展示
			for index=1,table.getn(g_Buff_Info)  do
				if nBuffID == g_Buff_Info[index].nBuffId then
					--PushDebugMessage(" nBuffId="..nBuffID.." index="..index)
					Rouge_ShowBuff_Client1_Item_Text:SetText(g_Buff_Info[index].nName);
					Rouge_ShowBuff_Client1_Item:SetToolTip(g_Buff_Info[index].nBuffTips)
					Rouge_ShowBuff_Client1_Item:SetProperty( "Image", g_Buff_Info[index].nBuffImg )
				end
			end
		else
			--技能
			Rouge_ShowBuff_BK:SetProperty( "Image","set:RouGe1 image:Congratulation")
			Rouge_ShowBuff_Client1_Text:SetText("#{RGPT_231130_659}");
			--展示
			local nSkillImg =GetRougepataSkillImg(nBuffID)
			local nTips = GetRougepataSkillTips(nBuffID);
			local nSkillName = GetRougepataSkillName(nBuffID);	
			Rouge_ShowBuff_Client1_Item_Text:SetText(ScriptGlobal_Format("#{RGPT_231130_479}",nSkillName) );
			Rouge_ShowBuff_Client1_Item:SetToolTip(nTips)
			Rouge_ShowBuff_Client1_Item:SetProperty( "Image", nSkillImg)
		end
	end
	
	this:Show()		
end

--=========================================================
--boss选择确认
--=========================================================
function Rouge_ShowBuff_Confirm()
	Rouge_ShowBuff_OnClose()
end


