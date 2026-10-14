-- NewBangHui_Bhxx_Amount   帮会id
-- NewBangHui_Bhxx_CreateTime 创建时间
-- NewBangHui_Bhxx_Create	创建人
-- NewBangHui_Bhxx_Master	现任帮主
-- NewBangHui_Bhxx_City	城市
-- NewBangHui_Bhxx_Locus	所在地
--	NewBangHui_Bhxx_CBD		商区
-- NewBangHui_Bhxx_Specialty	当前研究
-- NewBangHui_Bhxx_CityBuilding 当前建设
-- NewBangHui_Bhxx_Level	规模
-- NewBangHui_Bhxx_Info1	人数
-- NewBangHui_Bhxx_Info4	工业度
-- NewBangHui_Bhxx_Info5	农业度
-- NewBangHui_Bhxx_Info6	商业度
-- NewBangHui_Bhxx_Info7	国防度
-- NewBangHui_Bhxx_Info8	科技度
-- NewBangHui_Bhxx_Info9	扩张度
-- NewBangHui_Bhxx_Info3	国家资金
-- NewBangHui_Bhxx_Shangpiao 本日最大商票数
local g_NewBangHui_Bhxx_Frame_UnifiedPosition;
local g_NewBH_Ctrl = {}
local g_NewBH_huodong = {}
local g_MatchTestBeginTime = 20141218			--点击雄霸天下按钮时进行以下判断,当前时间是否处于2014年12月18日0点之后
local g_MatchTestBeg_LM	= 20141128				-- 龙门测试赛开始时间

local g_NewBH_StarSet = {}

local g_ZhiZunMax = 30000

-- 城战轮换（霸者天下）助战操作时间
local NewBangHui_Bhxx_AssistOpTime =
{
    [1] = {weekday = 5, begintime = 213000},
    [2] = {weekday = 6, endtime = 202000},
} -- end NewBangHui_Bhxx_AssistOpTime

function NewBangHui_Bhxx_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("GUILD_SHOW_DETAILINFO");
	this:RegisterEvent("GUILD_FORCE_CLOSE");
	this:RegisterEvent("GUILD_SELFEQUIP_CLICK");
    this:RegisterEvent("ACCELERATE_KEYSEND");
    this:RegisterEvent("SHOW_GUILDWAR_ANIMI");
	this:RegisterEvent("OPEN_GUILD_GIFT")
	this:RegisterEvent("GUILD_ZHANTUAN_OP")

    this:RegisterEvent( "GUILD_SHOW_MEMBERINFO" )
    this:RegisterEvent( "GUILD_LEAGUE_INFO" )
    this:RegisterEvent( "GUILDWAR_YXSSCHANGE" )

	this:RegisterEvent("GUILD_SHOW_ENEMYLIST")	

	this:RegisterEvent("OPEN_BUILD_INTRODUCE")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("ZHANTUAN_LIST_DATA");
	
	this:RegisterEvent("OPENMYALLIANCE");
	
	this:RegisterEvent("ZHIZUN_EQUIP_PROCESS_VALUE");
	this:RegisterEvent("ZHIZUN_EQUIP_PROCESS_REFRESH");
	this:RegisterEvent("GUILD_BIDDING_SHOWLIST")
	--this:RegisterEvent("TCITYWARLIMIT_OPENCANDIDATE")
end

function NewBangHui_Bhxx_OnLoad()
		g_NewBangHui_Bhxx_Frame_UnifiedPosition=NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition");
		g_NewBH_Ctrl = { curLeader = NewBangHui_Bhxx_Frame2_BZ_Lace_Text,
									GuildID = NewBangHui_Bhxx_Frame2_BHID_Lace_Text,
									curLeague = NewBangHui_Bhxx_Frame2_SSTM_Lace_Text,
									Creator = NewBangHui_Bhxx_Frame2_BHCSR_Lace_Text,
									CreateTime = NewBangHui_Bhxx_Frame2_BHCSSJ_Lace_Text,
									AllEquipPoint = NewBangHui_Bhxx_Frame2_ZZDL_Text1,
									FineEquipPoint = NewBangHui_Bhxx_Frame2_JYZL_Text1,
									City = NewBangHui_Bhxx_Frame2_BHCS_Lace_Text,
									Money = NewBangHui_Bhxx_Frame2_BHZJ_Lace_Text,
									CityScale = NewBangHui_Bhxx_Frame2_CSGM_Lace_Text,
									CityLoacl = NewBangHui_Bhxx_Frame2_CSSZ_Lace_Text,
									Maintain = NewBangHui_Bhxx_Frame2_WHZT_Lace_Text,
									MaintainMoneyBase = NewBangHui_Bhxx_Frame2_BZWHZJ_Money,
									MaintainMoneyCur	 = NewBangHui_Bhxx_Frame2_WHZJ_Money,
									Build = NewBangHui_Bhxx_Frame2_DQJS_Lace_Text,
									ZhiZunTime = NewBangHui_Bhxx_Jinjie_Time,
									Shangpiao = NewBangHui_Bhxx_Frame2_BRSPSL_Lace_Text,
									}
		g_NewBH_StarSet = { NewBangHui_Bhxx_StaticPart_Star4,
							NewBangHui_Bhxx_StaticPart_Star5,
							NewBangHui_Bhxx_StaticPart_Star6,
							NewBangHui_Bhxx_StaticPart_Star7,
							NewBangHui_Bhxx_StaticPart_Star8,
							NewBangHui_Bhxx_StaticPart_Star3,
							NewBangHui_Bhxx_StaticPart_Star2,
							NewBangHui_Bhxx_StaticPart_Star1
							}
		
		g_NewBH_huodong = {
										--百宝阁
										[1] = { name = "#{BHJM_140520_65}", openstr = "#{BHJM_140520_67}",
										           closestr = "#{BHJM_140520_66}", closetime = "#{BHJM_140520_68}",
												   costr = "#{BHJM_140520_69}", ccstr = "#{BHJM_140520_66}",
												   infostr = "#{BHJM_140520_70}"
												   },
										--神兵阁
										[2] = { name = "#{BHJM_140520_71}", openstr="#{BHJM_140520_72}",
													closestr = "#{BHJM_140520_66}", closetime ="#{BHJM_140520_68}",
													costr = "#{BHJM_140520_74}", ccstr = "#{BHJM_140520_66}",
												   infostr = "#{BHJM_140520_75}"
												   }
										}
										-- [3] = { name = "#{BHJM_140520_71}", openstr="#{BHJM_140520_72}",
													-- closestr = "#{BHJM_140520_66}", closetime ="#{BHJM_140520_68}",
													-- costr = "#{BHJM_140520_74}", ccstr = "#{BHJM_140520_66}"
												   -- infostr = "#{BHJM_140520_75}"
												   -- }									
									
end

function NewBangHui_Bhxx_OnEvent(event)
	if (event == "GUILD_SHOW_DETAILINFO") then
		NewBangHui_Bhxx_Clear();
        NewBangHui_Bhxx_SetDynamic_Pos()
		NewBangHui_Bhxx_Update();
		NewBangHui_Bhxx_SetTitle()
		NewBangHui_Bhxx_Show();
	elseif (event == "UI_COMMAND") then
		if(tonumber(arg0) == 30 and this:IsVisible()) then
			NewBangHui_Bhxx_Close();
		elseif(tonumber(arg0) == 31) then
			Guild:AskGuildDetailInfo();
		end
	elseif ( event == "GUILD_FORCE_CLOSE" ) then
		NewBangHui_Bhxx_Close()
	elseif( event == "SHOW_GUILDWAR_ANIMI" ) then	--帮战改变“帮会宣战”文字颜色 使用播放帮战动画的事件，如果以后这个显示和帮战动画不同步，那么需要建立新的事件。
		local type = arg0;
		if (arg0 == "show") then
			NewBangHui_Bhxx_Bhxz:SetText("#g0071BF#{BHJM_140520_04}")
			NewBangHui_Bhxx_Bhxz:SetToolTip("你的帮会正在帮战");
		else
		    NewBangHui_Bhxx_Bhxz:SetText("#{BHJM_140520_04}");
			NewBangHui_Bhxx_Bhxz:SetToolTip("");
		end
	elseif( event == "ZHIZUN_EQUIP_PROCESS_VALUE" ) then
		local nAddValue = tonumber(arg0)
		local nCurValue = tonumber(arg1)
		if( nAddValue > 0 and this:IsVisible() ) then
			NewBangHui_Bhxx_RefreshZhiZun(nCurValue, nAddValue)
		end
	elseif( event == "ZHIZUN_EQUIP_PROCESS_REFRESH" ) then
		local nIsOpen = tonumber(arg0)
		if nIsOpen > 0 then
			NewBangHui_Bhxx_RefreshZhiZun(0, 0)
		end
	elseif( event == "GUILD_SHOW_ENEMYLIST" ) then
		NewBangHui_Bhxx_Close()
	elseif (event == "GUILD_LEAGUE_INFO") then
		NewBangHui_Bhxx_Close()
	elseif (event == "GUILDWAR_YXSSCHANGE") then
		NewBangHui_Bhxx_Close()
	elseif (event == "OPEN_BUILD_INTRODUCE") then
		NewBangHui_Bhxx_Close()
	elseif (event == "GUILD_SHOW_MEMBERINFO") then
		NewBangHui_Bhxx_Close()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHui_Bhxx_Close()
	elseif (event == "ZHANTUAN_LIST_DATA" ) then
		this:Hide();
	elseif (event == "OPENMYALLIANCE") then
		this:Hide();
	elseif (event == "OPEN_GUILD_GIFT" ) then
		NewBangHui_Bhxx_Close()
	elseif event == "GUILD_BIDDING_SHOWLIST" then
		this:Hide()
	elseif event == "TCITYWARLIMIT_OPENCANDIDATE" then
		this:Hide()
	elseif event == "GUILD_ZHANTUAN_OP" then
		NewBangHui_Bhxx_Close()
	end
end

function NewBangHui_Bhxx_Close()
	this:Hide()
end
function NewBangHui_Bhxx_Clear()
	NewBangHui_Bhxx_DragTitle:SetText("");
end

function NewBangHui_Bhxx_SetDynamic_Pos()
    local selfGuildClanUnionPos = Variable:GetVariable("SelfGuildClanUnionPos")
	if( selfGuildClanUnionPos ~= nil) then
	    NewBangHui_Bhxx_Frame:SetProperty("UnifiedPosition", selfGuildClanUnionPos )
	end
end

function NewBangHui_Bhxx_RefreshZhiZun(nCurValue, nAddValue)

	for i = 1, table.getn(g_NewBH_StarSet) do
		if i <= 5 then 		
			g_NewBH_StarSet[i]:SetProperty("Animate", "Animate_StarDark");
			g_NewBH_StarSet[i]:Show()
		else
			g_NewBH_StarSet[i]:Hide()
		end
	end

	if nAddValue > 0 then
		for i = 1, table.getn(g_NewBH_StarSet) do
			if i <= nCurValue then 				
				if nCurValue < 5 then
					g_NewBH_StarSet[i]:SetProperty("Animate", "Animate_StarNoFlash");
				else
					g_NewBH_StarSet[i]:SetProperty("Animate", "Animate_Star");
				end
				g_NewBH_StarSet[i]:Show()
			end
		end
	else
		local ZhiZunValue = Guild:GetMyGuildDetailInfo( "zhizunprocess" )
		if ZhiZunValue <= 0 then
			-- 未开启			
		else
			for i = 1, table.getn(g_NewBH_StarSet) do
				if i <= ZhiZunValue then 			
					if ZhiZunValue < 5 then
						g_NewBH_StarSet[i]:SetProperty("Animate", "Animate_StarNoFlash");
					else
						g_NewBH_StarSet[i]:SetProperty("Animate", "Animate_Star");
					end
					g_NewBH_StarSet[i]:Show()
				end
			end
		end
		local ZhiZunTimes, nTips = Guild:GetMyGuildDetailInfo( "zhizunday" )
		g_NewBH_Ctrl.ZhiZunTime:SetText(ZhiZunTimes)
		g_NewBH_Ctrl.ZhiZunTime:SetToolTip(nTips)
	end			

end

function NewBangHui_Bhxx_Update()
	local szMsg = Guild:GetMyGuildDetailInfo("ChiefName");
	g_NewBH_Ctrl.curLeader:SetText(szMsg)
	
	local szID =  Guild:GetMyGuildDetailInfo("ID");
	g_NewBH_Ctrl.GuildID:SetText(szID)
	
	local szLeague = Guild:GetMyGuildDetailInfo("LeagueName");
	g_NewBH_Ctrl.curLeague:SetText(szLeague)
	

	
	local szCreator = Guild:GetMyGuildDetailInfo("Creator");
	g_NewBH_Ctrl.Creator:SetText(szCreator)
	
	local szFoundedTime = Guild:GetMyGuildDetailInfo("FoundedTime");
	g_NewBH_Ctrl.CreateTime:SetText(szFoundedTime)
	
	local nAllEquipPoint = Guild:GetMyGuildDetailInfo("AllEquipPoint");
	g_NewBH_Ctrl.AllEquipPoint:SetText(nAllEquipPoint)

	local nFineEquipPoint = Guild:GetMyGuildDetailInfo("FineEquipPoint");
	g_NewBH_Ctrl.FineEquipPoint:SetText(nFineEquipPoint)
		
	
	g_NewBH_Ctrl.City:SetToolTip("")
	local szCity = Guild:GetMyGuildDetailInfo("CityName");
	if szCity == "-1" then
		szCity = "#{BHJM_140520_45}";
		g_NewBH_Ctrl.City:SetToolTip("#{BHJM_140520_46}")
	end
	
	g_NewBH_Ctrl.City:SetText(szCity)
	
	
	local szCityScale = Guild:GetMyGuildDetailInfo("Level");
	g_NewBH_Ctrl.CityScale:SetText(szCityScale)
	
	local szLocus = Guild:GetMyGuildDetailInfo("LocalScene");
	if szLocus == "-1" then
		szLocus = "#{BHJM_140520_45}"
	end
	g_NewBH_Ctrl.CityLoacl:SetText(szLocus)
	
	
	
	local szMoney = Guild:GetMyGuildDetailInfo("FMoney");
	
	g_NewBH_Ctrl.Money:SetProperty("MoneyNumber", tostring(szMoney));
	
	local szMaintain = Guild:GetMyGuildDetailInfo("maintain")
	local strMaintain = ""
	g_NewBH_Ctrl.Maintain:SetToolTip("")
	if szMaintain == 1 then
		g_NewBH_Ctrl.Maintain:SetToolTip("#{BHJM_140520_58}")
		strMaintain = "#{BHJM_140520_56}"
	elseif szMaintain == 2 then
		g_NewBH_Ctrl.Maintain:SetToolTip("#{BHJM_140520_58}")
		strMaintain = "#{BHJM_140520_57}"
	else
		strMaintain = "#{BHJM_140520_45}"
	end
		
	g_NewBH_Ctrl.Maintain:SetText(strMaintain)
	
	local szBuild = Guild:GetMyGuildDetailInfo( "CurBuilding" );	
	if szBuild ~= "-1" then
	
		local bldprog = Guild:GetMyGuildDetailInfo("BldProg");
		local bldmaxprog = Guild:GetMyGuildDetailInfo("BldMaxProg");
		local bldDispatchedProg = Guild:GetMyGuildDetailInfo("BldDisPatched");
		
		local bldConstructTime =  Guild:GetMyGuildDetailInfo("ConstructTime");
		--szBuild = szBuild.."("..bldprog.."/"..bldDispatchedProg..")";
		--szBuild = szBuild.."("..bldConstructTime..")";
		local BuildInfo = ScriptGlobal_Format("#{JSRWY_160708_7}",szBuild,bldConstructTime)
		
		g_NewBH_Ctrl.Build:SetText(BuildInfo);
	else
		g_NewBH_Ctrl.Build:SetText("#{BHJM_140520_51}");
	end
	
	
	local basemoney = Guild:GetMyGuildDetailInfo( "basemoney" );
	g_NewBH_Ctrl.MaintainMoneyBase:SetProperty("MoneyNumber", tostring(basemoney));
	
	local maintainmoney = Guild:GetMyGuildDetailInfo( "maintainmoney" );
	--PushDebugMessage("maintainmoney="..maintainmoney)
	g_NewBH_Ctrl.MaintainMoneyCur:SetProperty("MoneyNumber", tostring(maintainmoney));

	if DataPool:Lua_IsPaoShangSvr() == 1 then
		local guildlevel = Guild:GetMyGuildDetailInfo("guildlevel");
		if guildlevel == 0  then
			szMsg = 0
		else 
			szMsg = 200 + (guildlevel - 1) * 25
		end   
		
		local totalTakenTimes , leftTakenTimes
		totalTakenTimes = Guild:GetMyGuildDetailInfo("TicketTaken")
		if totalTakenTimes == -1 then
			totalTakenTimes = 0
		end
	
		leftTakenTimes = szMsg - totalTakenTimes
		if leftTakenTimes < 0 then
			leftTakenTimes = 0
		end
		NewBangHui_Bhxx_Frame2_BRSPSL_Window:Show()
		g_NewBH_Ctrl.Shangpiao:Show()
		g_NewBH_Ctrl.Shangpiao:SetText(leftTakenTimes..'/'..szMsg)	
	else
		NewBangHui_Bhxx_Frame2_BRSPSL_Window:Hide()
		g_NewBH_Ctrl.Shangpiao:Hide()
	end
	-- 天道相关
	NewBangHui_Bhxx_RefreshZhiZun(0, 0)
	
end

function NewBangHui_Bhxx_Show()
	this:Show()
	NewBangHui_Bhxx_HuodongList:CleanAllElement("NewBangHui_Bhxx_Frame")
	NewBangHui_Bhxx_SetGuildFuliPoint()
	NewBangHui_Bhxx_SetBuildFuli5()
	--NewBangHui_Bhxx_SetBuildFuli4()
	NewBangHui_Bhxx_Setbaibaoge()
	NewBangHui_Bhxx_Setshenbingge()
	--NewBangHui_Bhxx_Setjubaopen()
	NewBangHui_Bhxx_Settiangong()
	NewBangHui_Bhxx_SetZhenshoudan()
	NewBangHui_Bhxx_SetBuildFuli()
	NewBangHui_Bhxx_SetBuildFuli2()
	NewBangHui_Bhxx_SetBuildFuli3()
	g_NewBH_Ctrl.GuildID:SetText(szID)
	NewBangHui_Bhxx_Bhxx:SetCheck(1)

	if Player:GetData("Is2606S") == 1 then
		NewBangHui_Bhxx_Frame2_Lace3:Hide()
	else
		NewBangHui_Bhxx_Frame2_Lace3:Show()
	end
	
	-- -- 霸者天下小红点
	-- local bztxApplyNum = DataPool:TCWLGetAssistApplyNum()
	-- local bztxIsInTime = NewBangHui_Bhxx_Check_BZTXAssistEnrollTime()
	-- if (bztxIsInTime > 0) then
	-- 	if (bztxApplyNum <= 0) then
	-- 		NewBangHui_Bhxx_BZTX_Tips:Hide()
	-- 	else
	-- 		local isChiefOrAss = Guild:IsChieforAss()
	-- 		if (isChiefOrAss ~= 1) then
	-- 			NewBangHui_Bhxx_BZTX_Tips:Hide()
	-- 		else
	-- 			NewBangHui_Bhxx_BZTX_Tips:Show()
	-- 		end
	-- 	end
	-- else
	-- 	NewBangHui_Bhxx_BZTX_Tips:Hide()
	-- end
end

function NewBangHui_Bhxx_SetGuildFuliPoint()
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")		
	
	local strguild = ""
	local strDot = ""
	local strStatus = ""

	strguild = "#{BHFLGTMB_210714_64}" 
	
	local bOpen1, nP1, bOpen2, nP2, bOpen3, nP3, bOpen4, nP4, bOpen5, nP5 = Guild:GetMyGuildDetailInfo("FuliOpenStatus")
	if bOpen1 ~= nil and bOpen1 > 0 then
		strStatus = strStatus.."#{BHFLGTMB_210714_65}"
		strDot = "#{BHFLGTMB_210714_71}"
	end
	if bOpen2 ~= nil and bOpen2 > 0 then
		strStatus = strStatus..strDot.."#{BHFLGTMB_210714_66}"
		strDot = "#{BHFLGTMB_210714_71}"
	end
	if bOpen3 ~= nil and bOpen3 > 0 then
		strStatus = strStatus..strDot.."#{BHFLGTMB_210714_67}"
		strDot = "#{BHFLGTMB_210714_71}"
	end
	if bOpen4 ~= nil and bOpen4 > 0 then
		strStatus = strStatus..strDot.."#{BHFLGTMB_210714_68}"
		if nP4 == 1 then
			strStatus = strStatus.."#{BHFLGTMB_210714_140}"
		elseif nP4 == 2 then
			strStatus = strStatus.."#{BHFLGTMB_210714_141}"
		elseif nP4 == 3 then
			strStatus = strStatus.."#{BHFLGTMB_210714_142}"
		end
		strDot = "#{BHFLGTMB_210714_71}"
	end
	if bOpen5 ~= nil and bOpen5 > 0 then
		strStatus = strStatus..strDot.."#{BHFLGTMB_210714_69}"
		strDot = "#{BHFLGTMB_210714_71}"
	end
	
	if strStatus == "" then
		strStatus = "#{BHFLGTMB_210714_72}"
	end
			
	ItemBar:SetBanghuiJiangliMainText2(strguild..strStatus.."#r#{BHFLGTMB_210714_74}")	
	NewBangHui_Bhxx_HuodongList:Flash()
end

function NewBangHui_Bhxx_SetBuildFuli5()
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")
	local manorID = Guild:GetMyGuildDetailInfo("manor");
	local rank = Guild:GetMyGuildDetailInfo("manorrank");
	local strguild = ""
	if manorID == -1 then
		strguild = "#{BHSD_150205_54}#{BHSD_150205_55}#r" 
	elseif manorID == 432 then
		strguild = "#{BHSD_150205_54}#{BHSD_150205_56}#r" 
	elseif manorID == 434 then
		strguild = "#{BHSD_150205_54}#{BHSD_150205_57}#r" 
	elseif manorID == 202 then
		strguild = "#{BHSD_150205_54}#{BHSD_150205_58}#r" 
	end	
	
	local iteminfo = {"#{BHSD_150205_135}","#{BHSD_150205_136}","#{BHSD_150205_137}"}
	local monsterinfo = {"#{BHSD_150205_130}","#{BHSD_150205_131}","#{BHSD_150205_132}"}
	if rank >=1 and rank <= 3 then
		ItemBar:SetBanghuiJiangliMainText2(strguild..ScriptGlobal_Format("#{BHSD_150205_158}",rank,monsterinfo[rank],iteminfo[rank],iteminfo[rank],iteminfo[rank]))
	else
		ItemBar:SetBanghuiJiangliMainText2(strguild.."#{BHSD_150205_158}")
	end	
	NewBangHui_Bhxx_HuodongList:Flash()
end

function NewBangHui_Bhxx_SetBuildFuli4()
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")		
	
	local strguild = ""

	strguild = "#{BHZQ_140820_08}#{BHZQ_140820_09}#r" 
	ItemBar:SetBanghuiJiangliMainText2(strguild.."#{BHZQ_140820_11}")	
	NewBangHui_Bhxx_HuodongList:Flash()
end

function NewBangHui_Bhxx_SetBuildFuli3()
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")		
	
	local strmicang = ""
	local micanglevel = Guild:GetMyGuildDetailInfo("micanglevel");
	if micanglevel == 0 then
		strmicang = "#{BHJM_140520_144}#{BHJM_140520_149}#r"
	elseif micanglevel == 1 then
		strmicang = "#{BHJM_140520_144}#{BHJM_140520_150}#r"
	elseif micanglevel == 2 then
		strmicang = "#{BHJM_140520_144}#{BHJM_140520_146}#r"
	elseif micanglevel == 3 then
		strmicang = "#{BHJM_140520_144}#{BHJM_140520_147}#r"
	elseif micanglevel == 4 then
		strmicang = "#{BHJM_140520_144}#{BHJM_140520_148}#r"
	end
	
	-- ItemBar:SetBanghuiJiangliName(strmicang)
	
	
	local strjiusi = ""
	local jiusilevel = Guild:GetMyGuildDetailInfo("jiusilevel");
	if jiusilevel == 1 then
		strjiusi = "#{BHJM_140520_156}#{BHJM_140520_151}#r"
	elseif jiusilevel == 2 then
		strjiusi = "#{BHJM_140520_156}#{BHJM_140520_152}#r"
	elseif jiusilevel == 3 then
		strjiusi = "#{BHJM_140520_156}#{BHJM_140520_153}#r"
	else
		strjiusi = "#{BHJM_140520_156}#{BHJM_140520_185}#r"
	end	
	
	-- ItemBar:SetBanghuiJiangliTime(strjiusi)
	local strjifang = ""
	local jifanglevel = Guild:GetMyGuildDetailInfo("jifanglevel");
	if jifanglevel == 0 then
		strjifang = "#{BHJM_140520_158}#{BHJM_140520_154}#r"
	elseif jifanglevel == 1 then
		strjifang = "#{BHJM_140520_158}#{BHJM_140520_155}#r"
	elseif jifanglevel == 2 then
		strjifang = "#{BHJM_140520_158}#{BHJM_140520_146}#r"
	elseif jifanglevel == 3 then
		strjifang = "#{BHJM_140520_158}#{BHJM_140520_147}#r"
	elseif jifanglevel == 4 then
		strjifang = "#{BHJM_140520_158}#{BHJM_140520_148}#r"
	end	
	
	local stryishe = ""
	local yishelevel = Guild:GetMyGuildDetailInfo("yishelevel");
	if jiusilevel == 1 then
		stryishe = "#{BHJM_140520_160}#{BHJM_140520_151}#r"
	elseif jiusilevel == 2 then
		stryishe = "#{BHJM_140520_160}#{BHJM_140520_152}#r"
	elseif jiusilevel == 3 then
		stryishe = "#{BHJM_140520_160}#{BHJM_140520_153}#r"
	else
		stryishe = "#{BHJM_140520_160}#{BHJM_140520_184}#r"
	end
	
	ItemBar:SetBanghuiJiangliMainText2(strmicang..strjiusi..strjifang..stryishe.."#{BHJM_140520_187}")	
	NewBangHui_Bhxx_HuodongList:Flash()
end

function NewBangHui_Bhxx_SetBuildFuli2()
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")
	local duantailevel = Guild:GetMyGuildDetailInfo("duantailevel");
	local strduantai = ""
	if duantailevel == 0 then
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_140}#{BHJM_140520_134}")
		-- ItemBar:SetBanghuiJiangliName("#{BHJM_140520_139}#{BHJM_140520_134}")
		strduantai = "#{BHJM_140520_140}#{BHJM_140520_134}#r#{BHJM_140520_139}#{BHJM_140520_134}#r#{BHJM_140520_141}#{BHJM_140520_134}#r"
	elseif duantailevel == 1 then
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_140}#{BHJM_140520_135}")
		-- ItemBar:SetBanghuiJiangliName("#{BHJM_140520_139}#{BHJM_140520_135}")
		strduantai = "#{BHJM_140520_140}#{BHJM_140520_135}#r#{BHJM_140520_139}#{BHJM_140520_135}#r#{BHJM_140520_141}#{BHJM_140520_135}#r"
	elseif duantailevel == 2 then
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_140}#{BHJM_140520_136}")
		-- ItemBar:SetBanghuiJiangliName("#{BHJM_140520_139}#{BHJM_140520_136}")
		strduantai = "#{BHJM_140520_140}#{BHJM_140520_136}#r#{BHJM_140520_139}#{BHJM_140520_136}#r#{BHJM_140520_141}#{BHJM_140520_136}#r"
	elseif duantailevel == 3 then
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_140}#{BHJM_140520_137}")
		-- ItemBar:SetBanghuiJiangliName("#{BHJM_140520_139}#{BHJM_140520_137}")
		strduantai = "#{BHJM_140520_140}#{BHJM_140520_137}#r#{BHJM_140520_139}#{BHJM_140520_137}#r#{BHJM_140520_141}#{BHJM_140520_137}#r"
	elseif duantailevel == 4 then
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_140}#{BHJM_140520_138}")
		-- ItemBar:SetBanghuiJiangliName("#{BHJM_140520_139}#{BHJM_140520_138}")
		strduantai = "#{BHJM_140520_140}#{BHJM_140520_138}#r#{BHJM_140520_139}#{BHJM_140520_138}#r#{BHJM_140520_141}#{BHJM_140520_138}#r"
	end
	
	
	local strjiusi = ""
	local jiusilevel = Guild:GetMyGuildDetailInfo("jiusilevel");
	if jiusilevel == 1 then
		strjiusi = "#{BHJM_140520_145}#{BHJM_140520_135}#r"
	elseif jiusilevel == 2 then
		strjiusi = "#{BHJM_140520_145}#{BHJM_140520_137}#r"
	elseif jiusilevel == 3 then
		strjiusi = "#{BHJM_140520_145}#{BHJM_140520_138}#r"
	else
		strjiusi = "#{BHJM_140520_145}#{BHJM_140520_185}#r"
	end	
	
	local stryishe = ""
	local yishelevel = Guild:GetMyGuildDetailInfo("yishelevel");
	if jiusilevel == 1 then
		stryishe = "#{BHJM_140520_159}#{BHJM_140520_135}#r"
	elseif jiusilevel == 2 then
		stryishe = "#{BHJM_140520_159}#{BHJM_140520_137}#r"
	elseif jiusilevel == 3 then
		stryishe = "#{BHJM_140520_159}#{BHJM_140520_138}#r"
	else
		stryishe = "#{BHJM_140520_159}#{BHJM_140520_184}#r"
	end
	
	ItemBar:SetBanghuiJiangliMainText2(strduantai..strjiusi..stryishe.."#{BHJM_140520_186}")	
	NewBangHui_Bhxx_HuodongList:Flash()
end

function NewBangHui_Bhxx_SetBuildFuli()
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")
	local duantailevel = Guild:GetMyGuildDetailInfo("duantailevel");
	local strduantai = ""
	if duantailevel == 0 then
		strduantai = "#{BHJM_140520_133}#{BHJM_140520_134}#r";
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_139}#{BHJM_140520_134}")
		-- strduantai = "#{BHJM_140520_140}#{BHJM_140520_134}#r#{BHJM_140520_141}#{BHJM_140520_134}#r"
	elseif duantailevel == 1 then
		strduantai = "#{BHJM_140520_133}#{BHJM_140520_135}#r"
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_139}#{BHJM_140520_135}")
		-- strduantai = "#{BHJM_140520_140}#{BHJM_140520_135}#r#{BHJM_140520_141}#{BHJM_140520_135}#r"
	elseif duantailevel == 2 then
		strduantai = "#{BHJM_140520_133}#{BHJM_140520_136}#r"
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_139}#{BHJM_140520_136}")
		-- strduantai = "#{BHJM_140520_140}#{BHJM_140520_136}#r#{BHJM_140520_141}#{BHJM_140520_136}#r"
	elseif duantailevel == 3 then
		strduantai = "#{BHJM_140520_133}#{BHJM_140520_137}#r"
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_139}#{BHJM_140520_137}")
		-- strduantai = "#{BHJM_140520_140}#{BHJM_140520_137}#r#{BHJM_140520_141}#{BHJM_140520_137}#r"
	elseif duantailevel == 4 then
		strduantai = "#{BHJM_140520_133}#{BHJM_140520_138}#r"
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_139}#{BHJM_140520_138}")
		-- strduantai = "#{BHJM_140520_140}#{BHJM_140520_138}#r#{BHJM_140520_141}#{BHJM_140520_138}#r"
	end
	local strmicang = ""
	local micanglevel = Guild:GetMyGuildDetailInfo("micanglevel");
	if micanglevel == 0 then
		 -- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_142}#{BHJM_140520_134}")
		strmicang = "#{BHJM_140520_142}#{BHJM_140520_134}#r#{BHJM_140520_143}#{BHJM_140520_134}#r"
	elseif micanglevel == 1 then
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_142}#{BHJM_140520_135}")
		strmicang = "#{BHJM_140520_142}#{BHJM_140520_135}#r#{BHJM_140520_143}#{BHJM_140520_135}#r"
	elseif micanglevel == 2 then
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_142}#{BHJM_140520_136}")
		strmicang = "#{BHJM_140520_142}#{BHJM_140520_136}#r#{BHJM_140520_143}#{BHJM_140520_136}#r"
	elseif micanglevel == 3 then
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_142}#{BHJM_140520_137}")
		strmicang = "#{BHJM_140520_142}#{BHJM_140520_137}#r#{BHJM_140520_143}#{BHJM_140520_137}#r"
	elseif micanglevel == 4 then
		-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_142}#{BHJM_140520_138}")
		strmicang = "#{BHJM_140520_142}#{BHJM_140520_138}#r#{BHJM_140520_143}#{BHJM_140520_138}#r"
	end

	
	local strjifang = ""
	local jifanglevel = Guild:GetMyGuildDetailInfo("jifanglevel");
	if jifanglevel == 0 then
		strjifang = "#{BHJM_140520_157}#{BHJM_140520_134}#r"
	elseif jifanglevel == 1 then
		strjifang = "#{BHJM_140520_157}#{BHJM_140520_135}#r"
	elseif jifanglevel == 2 then
		strjifang = "#{BHJM_140520_157}#{BHJM_140520_136}#r"
	elseif jifanglevel == 3 then
		strjifang = "#{BHJM_140520_157}#{BHJM_140520_137}#r"
	elseif jifanglevel == 4 then
		strjifang = "#{BHJM_140520_157}#{BHJM_140520_138}#r"
	end	
	
	ItemBar:SetBanghuiJiangliMainText2(strduantai..strmicang..strjifang.."#{BHJM_140520_161}")	
	NewBangHui_Bhxx_HuodongList:Flash()
end
function NewBangHui_Bhxx_SetZhenshoudan()
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")
	ItemBar:SetBanghuiJiangliName("#{BHJM_140520_167}")
	-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_168}")
	ItemBar:SetBanghuiJiangliMainText2Hide()
	local applystate, Leavetime = Guild:GetShoudanApplystate();
	if(applystate == 0 or applystate == 3 ) then
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_168}#{BHJM_140520_169}")
	elseif applystate == 1 then
		local str = ScriptGlobal_Format("#{BHJM_140520_170}",Leavetime)
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_168}"..str)
	elseif applystate == 2 then
		local str = ScriptGlobal_Format("#{BHJM_140520_171}",Leavetime)
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_168}"..str)		
	end
	ItemBar:SetBanghuiJiangliMainText("#{BHJM_140520_172}")	
	NewBangHui_Bhxx_HuodongList:Flash()
end

function NewBangHui_Bhxx_Settiangong()
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")
	-- ItemBar:SetBanghuiJiangliName("#{BHJM_140520_117}")
	-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_126}")
	ItemBar:SetBanghuiJiangliMainText2Hide()
	local tiangongstate = Guild:GetMyGuildDetailInfo("tiangongstate");
	if tiangongstate == 0 then
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_117}#{BHJM_140520_118}")
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_126}#{BHJM_140520_127}")
	elseif tiangongstate == 1 then
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_117}#{BHJM_140520_121}")
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_126}#{BHJM_140520_128}")
	elseif tiangongstate == 2 then
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_117}#{BHJM_140520_122}")
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_126}#{BHJM_140520_129}")
	elseif tiangongstate == 3 then
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_117}#{BHJM_140520_123}")
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_126}#{BHJM_140520_130}")
	elseif tiangongstate == 4 then
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_117}#{BHJM_140520_124}")
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_126}#{BHJM_140520_131}")
	elseif tiangongstate == 5 then
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_117}#{BHJM_140520_125}")		
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_126}#{BHJM_140520_132}")
	end
	

	
	ItemBar:SetBanghuiJiangliMainText("#{BHJM_140520_120}")	
	NewBangHui_Bhxx_HuodongList:Flash()
end

-- function NewBangHui_Bhxx_Setjubaopen()
-- 	local Jubaopen_Grade = {
-- 		{str="镶木聚宝盆", CostMoney=20000000},
-- 		{str="镶铜聚宝盆", CostMoney=30000000},
-- 		{str="镶银聚宝盆", CostMoney=40000000},
-- 		{str="镶金聚宝盆", CostMoney=50000000},
-- 		{str="镶玉聚宝盆", CostMoney=60000000},
-- 	}
-- 	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
-- 	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")
-- 	ItemBar:SetBanghuiJiangliMainText("#{BHJM_140520_116}")	
-- 	local jubaostate = Guild:GetMyGuildDetailInfo("jubaostate");
-- 	local IsJubaopenOnTime = Guild:GetMyGuildDetailInfo("IsJubaopenOnTime")
-- 	local jubaohour = Guild:GetMyGuildDetailInfo("JubaopenOnTimeHour");
-- 	local jubaomin = Guild:GetMyGuildDetailInfo("JubaopenOnTimeMin");
-- 	local JubaopenOnTimeGrade = Guild:GetMyGuildDetailInfo("JubaopenOnTimeGrade")
-- 	local jubaoontime
-- 	if IsJubaopenOnTime == 1 then
-- 		jubaoontime = ScriptGlobal_Format("#{DSKQ_141110_82}", jubaohour, jubaomin, Jubaopen_Grade[JubaopenOnTimeGrade].str)
-- 	else
-- 		jubaoontime = "#{DSKQ_141110_80}"
-- 	end
-- 	ItemBar:SetBanghuiJiangliTime("#{DSKQ_141110_79}"..jubaoontime)
	
-- 	if( tonumber(jubaostate) == 0 ) then
-- 		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_111}#{BHJM_140520_112}")
-- 	elseif ( tonumber(jubaostate) == 1) then
-- 		local jubaograde = Guild:GetMyGuildDetailInfo("jubaograde");
-- 		local str = ScriptGlobal_Format("#{BHJM_140520_113}",jubaograde)
-- 		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_111}"..str)
-- 	elseif( tonumber(jubaostate) == 2) then
-- 		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_111}#{BHJM_140520_114}")
-- 	end
-- 	NewBangHui_Bhxx_HuodongList:Flash()
-- end
function NewBangHui_Bhxx_Setshenbingge()
	local Fuben_Grade = {
		{str="#{DSKQ_141110_28}", CostMoney=20000000},
		{str="#{DSKQ_141110_29}", CostMoney=30000000},
		{str="#{DSKQ_141110_30}", CostMoney=40000000},
		{str="#{DSKQ_141110_31}", CostMoney=50000000},
		{str="#{DSKQ_141110_32}", CostMoney=60000000},
	}
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")
	local shenbinglevel =  Guild:GetMyGuildDetailInfo("shenbinglevel");
	local shenbingstate = Guild:GetMyGuildDetailInfo("shenbingstate");
	local IsFubenOnTime = Guild:GetMyGuildDetailInfo("IsFubenOnTime")
	local shenbinghour = Guild:GetMyGuildDetailInfo("FubenOnTimeHour");
	local shenbingmin = Guild:GetMyGuildDetailInfo("FubenOnTimeMin");
	local FubenOnTimeGrade = Guild:GetMyGuildDetailInfo("FubenOnTimeGrade")
	local shenbingontime
	if IsFubenOnTime == 1 then
		shenbingontime = ScriptGlobal_Format("#{DSKQ_141110_81}", shenbinghour, shenbingmin, Fuben_Grade[FubenOnTimeGrade].str)
	else
		shenbingontime = "#{DSKQ_141110_80}"
	end
	ItemBar:SetBanghuiJiangliOnTime("#{DSKQ_141110_79}"..shenbingontime)
	
	if(tonumber(shenbinglevel) == 0) then
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_71}#{BHJM_140520_66}")
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_68}#{BHJM_140520_66}")
	else
		local str = ScriptGlobal_Format("#{BHJM_140520_72}",shenbinglevel)
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_71}"..str)
		if tonumber(shenbingstate) == 0 then
			ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_68}#{BHJM_140520_74}")
		else
			ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_68}#{BHJM_140520_73}")
		end
	end
	ItemBar:SetBanghuiJiangliMainText3Show()
	ItemBar:SetBanghuiJiangliMainText3("#{BHJM_140520_75}")	
	NewBangHui_Bhxx_HuodongList:Flash()
end
function NewBangHui_Bhxx_Setbaibaoge()
	local ItemBar = NewBangHui_Bhxx_HuodongList:AddItemElement( "GuildButton", "LEFT", "NewBangHui_Bhxx","" ,"")
	ItemBar:SetProperty("GuildButtonHover","GuildHoverSection")
	-- ItemBar:SetBanghuiJiangliName("#{BHJM_140520_65}")
	-- ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_68}")
	ItemBar:SetBanghuiJiangliMainText2Hide()
	local baibaolevel =  Guild:GetMyGuildDetailInfo("baibaolevel");
	if tonumber(baibaolevel) == 0 then
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_65}#{BHJM_140520_66}")
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_68}#{BHJM_140520_66}")
	else
		local str = ScriptGlobal_Format("#{BHJM_140520_67}",baibaolevel)
		ItemBar:SetBanghuiJiangliName("#{BHJM_140520_65}"..str)
		ItemBar:SetBanghuiJiangliTime("#{BHJM_140520_68}#{BHJM_140520_69}")
	end
	ItemBar:SetBanghuiJiangliMainText("#{BHJM_140520_70}")	
	NewBangHui_Bhxx_HuodongList:Flash()
end

function NewBangHui_Bhxx_Szxx_Close_Clicked()
	this:Hide()
end

function NewBangHui_Bhxx_Bhxx_Clicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:AskGuildDetailInfo();
	Guild:CloseKickGuildBox();
end
function NewBangHui_Bhxx_Tmxx_Clicked()
	NewBangHui_Bhxx_Bhxx:SetCheck(1)
	--在K服只有服务器配置保留原服"帮会同盟"信息的时候,才响应相应的按钮事件
	if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
		PushDebugMessage("#{KVKBH_140124_66}")
		return;
	end
    local id=Player:GetData("GUILDLEAGUE")
	if id == nil or id < 0 then
        PushDebugMessage( "#{KVKSL_110628_305}" )
        return
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
    GuildLeague:ShowInfoWindow()
end

function NewBangHui_Bhxx_Bhxz_Clicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
    City:OpenNewGuildWarDlg();
	Guild:CloseKickGuildBox();
	NewBangHui_Bhxx_Bhxx:SetCheck(1)
end

function NewBangHui_Bhxx_Hygl_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ToggleGuildDetailInfo()
end

function NewBangHui_Bhxx_YXSS_Clicked()
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildYXSSInfo();
end

function NewBangHui_Bhxx_JZWJS_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ShowCityBuildIntroduce()
end

--拍卖
function NewBangHui_Bhxx_Auction_Clicked()
  --if KaJi:LuaFnIsKaJiServer() == 1 then
  --	PushDebugMessage("#{SCBHPM_20220815_143}")
 --	return
  --end
  if GetSceneID() ~= 850 then
	PushDebugMessage("#{SCBHPM_20220815_02}")
	return
  end
	
  if Player:GetLevel() < 85 then
	PushDebugMessage("#{SCBHPM_20220815_03}")
	return
  end
	
  if( -1 == Player:GetData("GUILD")) then
	PushDebugMessage("#{SCBHPM_20220815_04}")
	return
  end
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildBiddingInfo(0, 1, -1)
end

--
function NewBangHui_Bhxx_BZZT_Clicked()
	local selfzoneid = DataPool:GetSelfZoneWorldID()
	if (KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(181) > 0) or 
		DataPool:Lua_IsNewServerPlayerByZWID(selfzoneid) == 1 or
		Player:GetData("IsOriginalJD")  == 1 or
		Player:GetData("Is2606S")  == 1 or 
		Player:GetData("SPECKAJI89") > 0 then
	  PushDebugMessage("#{ZTXT_260511_151}")
	  return
	end
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("GUILD_ZHANTUAN_OP", 1)
end
function NewBangHui_Bhxx_SetTitle()
	local szName = Guild:GetMyGuildName("Name");
	local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
	if string.len(szName) <= 0 then
		title = ""
	end	
	NewBangHui_Bhxx_PageHeader:SetText(title)
end

function NewBangHui_Bhxx_ListContentItemClick()

end

--帮会联赛 by wangbin
function NewBangHui_Bhxx_BHLS_Clicked()
	local nCurTime = tonumber(DataPool:GetServerDayTime());
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
	if selfZoneWorldID == 9031 or selfZoneWorldID == 9015 then
		if ( nCurTime < g_MatchTestBeg_LM ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Bhxx_Bhxx:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	else
		if ( nCurTime < g_MatchTestBeginTime ) then
			PushDebugMessage( "#{BHKF_140909_419}" );
			NewBangHui_Bhxx_Bhxx:SetCheck(1);
			Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
			return
		end
	end
	
	local nStatus = ZhanTuanInterface:GetZhanTuanInfo();
	if(0 == tonumber(nStatus)) then
		NewBangHui_Bhxx_Bhxx:SetCheck(1)
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1);
end

function NewBangHui_Bhxx_BangHuiFuLi_Clicked()
	local myPos = Guild:GetMyPosition()
	if 9 ~= myPos and 8 ~= myPos then
		PushDebugMessage( "#{DSKQ_141110_12}" )
		return
	end
	
	local szMsg = Guild:GetMyGuildDetailInfo("CityName")
	if(szMsg == "-1") then
		PushDebugMessage( "#{DSKQ_141110_78}" )
		return
	end
	
	PushEvent("OPEN_BANGHUIFULI")
end

function NewBangHui_Bhxx_KVKLeague_Clicked()
	local alliancemark = 0;
end



function NewBangHui_Bhxx_HB_OnClicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1)
	Guild:OpentGuildGiftUI()
end

function NewBangHui_Bhxx_BZTX_Clicked()
	-- if (Player:GetData("TCWLSvrOpenFlag") < 0) then
	-- 	NewBangHui_Bhxx_BZTX:SetCheck(0)
	-- 	NewBangHui_Bhxx_Bhxx:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_161}")
	-- elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
	-- 	NewBangHui_Bhxx_BZTX:SetCheck(0)
	-- 	NewBangHui_Bhxx_Bhxx:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_154}")
	-- else
	-- 	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Bhxx_Frame:GetProperty("UnifiedPosition"), 1)
	-- 	Guild:TCWLOpenLCandidateUI()
	-- end
end -- end func NewBangHui_Bhxx_BZTX_Clicked()

--*****************************************************************************
-- 城战轮换（霸者天下）是否在助战申请时间内
--*****************************************************************************
function NewBangHui_Bhxx_Check_BZTXAssistEnrollTime()
	local curWeekDay = DataPool:GetServerWeekDay()
	if (curWeekDay == 0) then
		-- 星期天特殊处理一下
		curWeekDay = 7
	end

	local beginDay = NewBangHui_Bhxx_AssistOpTime[1].weekday
	local beginTime = NewBangHui_Bhxx_AssistOpTime[1].begintime
	local endDay = NewBangHui_Bhxx_AssistOpTime[2].weekday
	local endTime = NewBangHui_Bhxx_AssistOpTime[2].endtime

	if (curWeekDay >= beginDay and curWeekDay <= endDay) then
		local curMinTime = DataPool:GetServerMinuteTime()
		if (curWeekDay == beginDay) then
			if (curMinTime >= beginTime) then
				return 1
			else
				return -1
			end
		elseif (curWeekDay == endDay) then
			if (curMinTime < endTime) then
				return 1
			else
				return -1
			end
		else
			return 1
		end
	end

    return -1
end -- end func NewBangHui_Bhxx_Check_BZTXAssistEnrollTime()
