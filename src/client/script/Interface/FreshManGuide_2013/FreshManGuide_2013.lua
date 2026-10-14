-- 新手指引ui
-- created by lixiang, apr 17th, 2013

    --!!!reloadscript =FreshManGuide_2013
-- 调整一下,希望使用起来更方便一些。。。maybe
-- 另有1中可能的做法,是仿照cegui的tooltip来实现,不过底层要加不少,想来想去,还是算了

local g_Frame_Width = 0
local g_Frame_Height = 0

local g_Text = {
    [1] = "#{XSRWGZ_110917_01}",
    [2] = "#{XSRWGZ_110917_02}",
    [3] = "#{XSRWGZ_110917_03}",
    [4] = "#{XSRWGZ_110917_04}",
    [5] = "#{XSRWGZ_110917_05}",
    [6] = "#{XSRWGZ_110917_06}",
    [7] = "#{XSRWGZ_110917_07}",
    [8] = "#{XSRWGZ_110917_11}",
    [9] = "#{XSRWGZ_110917_12}",
    [10] = "#{XSRWGZ_110917_13}",
    [11] = "#{XSRWGZ_110917_20}",
    [12] = "#{XSRWGZ_110917_21}",
    [13] = "#{XSRWGZ_110917_22}",
    [14] = "#{XSRWGZ_110917_23}",
    [15] = "#{XSRWGZ_110917_38}",
    [16] = "#{XSRWGZ_110917_39}",
    [17] = "#{XSRWGZ_110917_41}",
    [18] = "#{XSRWGZ_110917_50}",
    [19] = "#{XSRWGZ_110917_51}",
    [20] = "#{XSRWGZ_110917_107}",
    [21] = "#{XSRWGZ_110917_115}",
	[22] = "#{MPJJRW_110805_769}",--经脉界面
	[23] = "#{YLK_120307_24}",--周卡提示
	[24] = "#{ZYRW_120522_22}",  --点击初级凝练可获得真元
	[25] = "#{ZYRW_120522_23}",  --选中真元点击拾取，可将其放入真元包裹
	[26] = "#{ZYRW_120522_34}",  --选中任意盘眼后点击激活按钮，通过消耗真元碎片成功激活真元盘眼。
	[27] = "#{ZYRW_120522_35}",  --请将右侧的真元拖入已激活的盘眼中。
	[28] = "#{ZYRW_120522_36}",  --点击后可通过消耗元晶升级真元
	[29] = "#{ZYRW_120522_46}",  --点击可获得真元并有机会激活低级凝练
	[30] = "#{ZYRW_120522_47}",  --点击后有机会获得高品阶真元并有机会激活中极凝练
	[31] = "#{ZYRW_120522_48}",  --选中界面中的真元后点击炼化可获得元晶
	[32] = "#{ZYRW_120522_49}",  --将真元拖入此处，可直接炼化为元晶。真元品质、等级越高，炼化后获得的元晶也就越多
	[33] = "#{ZYRW_120522_59}",  --点击后通过消耗元晶升级真元
	[34] = "#{BBGX_120809_1}",
	[35] = "#{JDZY_120806_01}", --点击后可查看武林风云录，通过武林风云录可以查看%s0#cffff00的相关任务，完成任务后，可获得到%s1#cffff00等大礼！
	[36] = "#{JDZY_120806_33}", --点击后可查看武林风云录，完成相关任务可以获取价值不菲的神秘礼物！
	[37] = "#{WBSS_120727_93}", --装备位上可以一次镶嵌多颗宝石
	[38] = "#{JYYD_121010_06}", --点击此处即可前往玲珑岛中，一探究竟。
	[39] = "#{ZHYTS_120105_02}", --周活跃宝箱领奖提示
	[40] = "#{ZHYTS_120105_02}", --周活跃宝箱领奖提示
	[41] = "#{ZHYTS_120105_02}", --周活跃宝箱领奖提示
	[42] = "#{ZHYTS_120105_02}", --周活跃宝箱领奖提示
	[43] = "#{WLMJRW_20130226_26}",	-- 武林秘籍: 还未学习秘籍，右击背包道具栏中的武林秘籍即可学习。
	[44] = "#{WLMJRW_20130226_27}",	-- 武林秘籍: 在此可以查看已经学习的武林秘籍。
	[45] = "#{WLMJRW_20130226_45}",	-- 武林秘籍: 将一段式拖拽至任意快捷栏位中。
	[46] = "#{WLMJRW_20130226_67}",	-- 武林秘籍: 武学心得可以用来提升秘籍的层数，秘籍的层数越高，使用一段式后激活二段式和使用二段式后激活三段式的几率越大，同时还会更多的修为。
	[47] = "#{WLMJRW_20130226_80}",	-- 武林秘籍: 点击可以升级左侧已学习秘籍的领悟境界
	[48] = "#{WLMJRW_20130226_81}", -- 武林秘籍: 秘籍领悟境界提升，修为增加，修为越高，使用秘籍招式后，招式效果越大。
}

--周活跃宝箱名字
local g_TextWeekBox = {
	[1] = "#{ZHYTS_120105_20}",
	[2] = "#{ZHYTS_120105_21}",	
	[3] = "#{ZHYTS_120105_22}",	
	[4] = "#{ZHYTS_120105_23}",	
}
local g_TextParam = {

	{"#{JDZY_120806_03}" , "#{JDZY_120806_18}"},
	{"#{JDZY_120806_04}" , "#{JDZY_120806_19}"},
	{"#{JDZY_120806_05}" , "#{JDZY_120806_20}"},
	{"#{JDZY_120806_06}" , "#{JDZY_120806_21}"},
	{"#{JDZY_120806_07}" , "#{JDZY_120806_22}"},
	{"#{JDZY_120806_08}" , "#{JDZY_120806_23}"},
	{"#{JDZY_120806_09}" , "#{JDZY_120806_24}"},
	{"#{JDZY_120806_10}" , "#{JDZY_120806_25}"},
	{"#{JDZY_120806_12}" , "#{JDZY_120806_27}"},
	{"#{JDZY_120806_13}" , "#{JDZY_120806_28}"},
	{"#{JDZY_120806_15}" , "#{JDZY_120806_30}"},
	{"#{JDZY_120806_16}" , "#{JDZY_120806_31}"},
	
}

local g_X_Offset = 0  --相对目标窗口的偏移
local g_Y_Offset = 0  --同上
local g_Direct   = 0 --相对目标窗口的方位

local g_ArrowTextList = 
{
	[1]  = {strName = "UpPutOff_Flash", dTime = 20000 },			--	上箭头		点击关闭
	[2]  = {strName = "UpAutoPath_Flash", dTime = 20000 },			--	上箭头		点击自动寻路
	[3]  = {strName = "UpRightPushEquip_Flash", dTime = 20000 },		--	上箭头		右键点击装备
	[4]  = {strName = "DownLevelUp_Flash", dTime = 20000 },			--	下箭头		点此提升等级
	[5]  = {strName = "DownLookTask_Flash", dTime = 20000 },		--	下箭头		点击查看任务
	[6]  = {strName = "DownLookPet_Flash", dTime = 20000 },			--	下箭头		点击查看珍兽
	[7]  = {strName = "DownOpenBag_Flash", dTime = 20000 },			--	下箭头		点击打开包裹
	[8]  = {strName = "DownLookAttribute_Flash", dTime = 20000 },		--	下箭头		点击人物属性
	[9]  = {strName = "DownCallMount_Flash",dTime = 10000 },		--	下箭头		点击召唤坐骑
	[10] = {strName = "DownHurtUse_Flash", dTime = 20000 },			--	下箭头		受伤后可使用
	[11] = {strName = "RightPushOff_Flash", dTime = 20000 },		--	右箭头		点击关闭
	[12] = {strName = "RightPushOnEquip_Flash", dTime = 20000 },		--	右箭头		点击后装备
	[13] = {strName = "LeftPetPK_Flash", dTime = 20000 },			--	左箭头		珍兽出战
	[14] = {strName = "LeftPushOff_Flash", dTime = 20000 },			--	左箭头		点击关闭
	[15] = {strName = "LeftPushGetTask_Flash", dTime = 20000 },		--	左箭头		点击接取任务
	[16] = {strName = "LeftPushLevelUp_Flash", dTime = 20000 },		--	左箭头		点击升级
	[17] = {strName = "LeftPushSubmitTask_Flash", dTime = 20000 },		--	左箭头		点击提交任务
	[18] = {strName = "LeftPushFinishTask_Flash", dTime = 20000 },		--	左箭头		点击完成任务
	[19] = {strName = "LeftAllRightMount_Flash", dTime = 20000 },		--	左箭头		已装备坐骑
	[20] = {strName = "LeftMenpai_Flash", dTime = 20000 },			--	左箭头		选择一个门派加入
	[21] = {strName = "DownHurtUse_Flash", dTime = 20000 },			--	下箭头		受伤后可使用
	[22] = {strName = "FreshMan_ClickUpOpen_Flash", dTime = 20000 },			--上箭头		点击打开
	[23] = {strName = "FreshMan_ClickLeftOpenShop_Flash", dTime =20000},    --左箭头		打开商店
	[24] = {strName = "FreshMan_ClickDownOpen_Flash", dTime = 20000},				--下箭头		点击打开
	[25] = {strName = "FreshMan_Choise_Flash", dTime = 20000},		--一个闪烁的框框
	[26] = {strName = "FreshMan_Choise_Flash", dTime = 20000},		--也是一个闪烁的框框和上面的大小不一样
	[27] = {strName = "DownLookSetModelChange_Flash", dTime = 8000},				--下箭头		新增修长版模型
	[28] = {strName = "LeftPushSystemSet_Flash", dTime = 8000},				--左箭头		点击进入设置
	[29] = {strName = "LeftPushCheckModelChange_Flash", dTime = 8000},				--左箭头		选中即可设置
	[30] = {strName = "UpPushFenxianSet_Flash", dTime = 8000},
	[31] = {strName = "FreshMan_ClickDownOpen_Flash", dTime = 8000},	--	下箭头		查看宗门绝学技能
	[32] = {strName = "CheckViewZongMenSkill_Flash", dTime = 8000},	--			查看宗门绝学技能
} 

local g_ArrowSizeList = 
{
	[1]  = {width = 203, height = 119},
	[2]  = {width = 203, height = 119},
	[3]  = {width = 203, height = 119},
	[4]  = {width = 203, height = 116},
	[5]  = {width = 203, height = 116},
	[6]  = {width = 203, height = 116},
	[7]  = {width = 203, height = 116},
	[8]  = {width = 203, height = 116},
	[9]  = {width = 203, height = 116},
	[10] = {width = 203, height = 116},
	[11] = {width = 200, height = 68},
	[12] = {width = 222, height = 68},
	[13] = {width = 253, height = 68},
	[14] = {width = 197, height = 68},
	[15] = {width = 253, height = 68},
	[16] = {width = 201, height = 68},
	[17] = {width = 253, height = 68},
	[18] = {width = 253, height = 68},
	[19] = {width = 220, height = 68},
	[20] = {width = 305, height = 68},
	[21] = {width = 203, height = 116},
	[22] = {width = 203, height = 116},
	[23] = {width = 323, height = 68},
	[24] = {width = 203, height = 116},
	[25] = {width = 210, height = 90},		--一个闪烁的框框
	[26] = {width = 160, height = 52},		--一个闪烁的框框
	[27] = {width = 203, height = 116},
	[28] = {width = 253, height = 68},
	[29] = {width = 253, height = 68},
	[30] = {width = 203, height = 119},
	[31] = {width = 203, height = 119},
	[32] = {width = 203, height = 119},
}

local g_AnimateInterFace
--local g_FrameInterface

function FreshManGuide_2013_PreLoad()
	this:RegisterEvent("OPEN_FRESHMAN_GUIDE")
	this:RegisterEvent("OPEN_FRESHMAN_GUIDE_NEW2013")
	this:RegisterEvent("CLOSE_FRESHMAN_GUIDE")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function FreshManGuide_2013_OnLoad()
	g_AnimateInterFace = FreshManGuide_2013_Frame
	g_Frame_Width  = g_AnimateInterFace:GetProperty("AbsoluteWidth")
	g_Frame_Height = g_AnimateInterFace:GetProperty("AbsoluteHeight")
end

function FreshManGuide_2013_OnEvent(event)
	--	需要的参数：打开方式，目的图片，目的窗口位置（X,Y），目的窗口大小(w,h)，客户端窗口大小，目的显示位置
	if event == "OPEN_FRESHMAN_GUIDE_NEW2013" then
		--	检查客户端窗口大小
		local nClientW = tonumber(arg5)
		local nClientH = tonumber(arg6)
		if 1 ~=  FreshManGuide_2013_CheckSize(nClientW, nClientH) then
			return
		end

		--	区分打开方式
		local nType =  tonumber(arg0)
		if 1 == nType then	--	重新设置
			local nTipPosX = tonumber(arg1)
			local nTipPosY = tonumber(arg2)
			local nDestW = tonumber(arg3)
			local nDestH = tonumber(arg4)
			local nTipIndex = tonumber(arg7)
			local nDir = tonumber(arg8)
			FreshManGuide_2013_FrameReset(nTipPosX, nTipPosY, nDestW, nDestH, nClientW, nClientH, nTipIndex, nDir)
			SetTimer("FreshManGuide_2013", "FreshManGuide_2013_Close()", g_ArrowTextList[nTipIndex].dTime)
		elseif 2 == nType then	--	更新位置
			local nTipPosX = tonumber(arg1)
			local nTipPosY = tonumber(arg2)
			local nDestW = tonumber(arg3)
			local nDestH = tonumber(arg4)
			FreshManGuide_2013_FrameModify(nTipPosX, nTipPosY, nDestW, nDestH, nClientW, nClientH, g_Direct)
			--SetTimer("FreshManGuide_2013", "FreshManGuide_2013_Close()", g_ArrowTextList[nTipIndex].dTime)
		end

		
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" or event == "CLOSE_FRESHMAN_GUIDE" then
		FreshManGuide_2013_Close()
		return
	end
end

function FreshManGuide_2013_FrameReset(nTipPosX, nTipPosY, nDestW, nDestH, nClientWidth, nClientHeight, nTipIndex, nDir)
	KillTimer("FreshManGuide_2013_Close()")
	--	重置控件大小	
	FreshManGuide_2013_ResetSize(nTipIndex)

	FreshManGuide_2013_FrameModify(nTipPosX, nTipPosY, nDestW, nDestH, nClientWidth, nClientHeight, nDir)

	this:Show()
end

function FreshManGuide_2013_FrameModify(nTipPosX, nTipPosY, nDestW, nDestH, nClientWidth, nClientHeight, nDir)
	
	local tempDir = tonumber(nDir)	
	if tempDir < 0 or tempDir > 3 then
		tempDir	= g_Direct
	end

	--	检查显示位置	不做位置自动调整，这里注释掉
	--tempDir = FreshManGuide_2013_PositionCheck(nTipPosX, nTipPosY, nDestW, nDestH, nClientWidth, nClientHeight, tempDir)
	--	计算显示位置
	FreshManGuide_2013_ResetPosition(nTipPosX, nTipPosY, tempDir)
	
end


function FreshManGuide_2013_Close()
	if not this:IsVisible() then
		return
	end
	
	KillTimer("FreshManGuide_2013_Close()")
	this:Hide()
end

function FreshManGuide_2013_Reset(nTextID, nTipPosX, nTipPosY, nClientWidth, nClientHight, szCorner)
	KillTimer("FreshManGuide_2013_Close()")
	if GetFreshManGuideOwner() == "PlayerFrame" and (nTextID == 34 or nTextID == 35 or nTextID == 36)then
		SetTimer("FreshManGuide_2013", "FreshManGuide_2013_Close()", 10000)
	elseif GetFreshManGuideOwner() == "MiniMap" and (nTextID == 39 or nTextID == 40 or nTextID == 41 or nTextID == 42)then
		SetTimer("FreshManGuide_2013", "FreshManGuide_2013_Close()", 10000)			--- 10秒关闭 周活跃奖励
	elseif GetFreshManGuideOwner() == "PlayerFrame" or GetFreshManGuideOwner() == "MiniMap" then --游龙卡特写 家园按钮
		SetTimer("FreshManGuide_2013", "FreshManGuide_2013_Close()", 30000)	--30秒关闭;如果有渐变需求,缩小elapse,然后在回调中计数并更新alpha
	elseif GetFreshManGuideOwner() == "ZhenYuanNingLian" or GetFreshManGuideOwner() == "ZhenYuanActivation" or GetFreshManGuideOwner() == "ZhenYuan" then
		SetTimer("FreshManGuide_2013", "FreshManGuide_2013_Close()", 10000)
	elseif GetFreshManGuideOwner() == "EquipBaoshiChange" then      --- 30秒关闭，一键换宝石
		SetTimer("FreshManGuide_2013", "FreshManGuide_2013_Close()", 30000)
	else
		SetTimer("FreshManGuide_2013", "FreshManGuide_2013_Close()", 5000)	--5秒关闭;如果有渐变需求,缩小elapse,然后在回调中计数并更新alpha
	end

	this:Show()
end

function FreshManGuide_2013_To(nXPos, nYPos)
	g_AnimateInterFace:SetProperty("AbsoluteXPosition", nXPos)
	g_AnimateInterFace:SetProperty("AbsoluteYPosition", nYPos)
end

--	检查显示位置是否没问题，如有问题，更改显示位置
function FreshManGuide_2013_PositionCheck(nParPosX, nParPosY, nParWidth, nParHeight, nClientWidth, nClientHeight, nDir)
	if nDir < 0 and g_Direct > 0 then
		nDir = g_Direct
	end

	if nDir > 3 and g_Direct > 0 then
		nDir = g_Direct
	end

	if nDir == 0 then		--	上
		--	上变下
		if nParPosY - g_Frame_Height < 0 then
			return 1
		end
	elseif nDir == 1 then		--	下
		--	下变上
		if nParPosY + g_Frame_Height > nClientHeight then
			return 0
		end
	elseif nDir == 2 then		--	左
		--	左变右
		if nParPosX - g_Frame_Width < 0 then
			return 3
		end
	elseif nDir == 3 then		--	右
		--	右变左
		if nParPosX + g_Frame_Width > nClientWidth then
			return 2
		end
	end

	--	没问题，返回原先值
	return nDir
end

--	参数：目的位置X, 目的位置Y, 目的控件宽度, 目的控件高度, 目的显示位置(上、下、左、右)
function FreshManGuide_2013_ResetPosition(nParPosX, nParPosY, nDir)
	--	根据显示方向，计算显示位置
	local nFrameX = 0
	local nFrameY = 0

	if nDir > 3 or nDir < 0 then
		return
	end

	if nDir == 0 then		--	上
		nFrameX = math.floor(nParPosX - (g_Frame_Width * 0.5))
		nFrameY = math.floor(nParPosY - g_Frame_Height)
		g_Direct = nDir
	elseif nDir == 1 then		--	下
		nFrameX = math.floor(nParPosX - (g_Frame_Width * 0.5))
		nFrameY = math.floor(nParPosY)
		g_Direct = nDir
	elseif nDir == 2 then		--	左
		nFrameX = math.floor(nParPosX - g_Frame_Width)
		nFrameY = math.floor(nParPosY - (g_Frame_Height * 0.5))
		g_Direct = nDir
	elseif nDir == 3 then		--	右
		nFrameX = math.floor(nParPosX)
		nFrameY = math.floor(nParPosY - (g_Frame_Height * 0.5))
		g_Direct = nDir
	end

	FreshManGuide_2013_To(nFrameX, nFrameY)
end

function FreshManGuide_2013_ResetSize(nIndex)
	if nIndex > 32 then
		return
	end

	if nIndex <= 0 then
		return
	end
	g_Frame_Width = g_ArrowSizeList[nIndex].width
	g_Frame_Height = g_ArrowSizeList[nIndex].height

	g_AnimateInterFace:SetProperty("AbsoluteHeight", g_Frame_Height)
	g_AnimateInterFace:SetProperty("AbsoluteWidth", g_Frame_Width)

	g_AnimateInterFace:SetProperty("Animate", g_ArrowTextList[nIndex].strName)

	--g_FrameInterface:SetProperty("AbsoluteHeight", g_Frame_Height)
	--g_FrameInterface:SetProperty("AbsoluteWidth", g_Frame_Width)
end

function FreshManGuide_2013_CheckSize(nClientWidth, nClientHight)
    if g_Frame_Width - nClientWidth > 0 or g_Frame_Height - nClientHight > 0 then
        return 0
    end
    return 1
end

--30，35，38，40，45，50，65，70，75，80，85，90
function FreshManGuide_2013_LevelToIndex(level)
	if level == 30 then
		return 1
	elseif level == 35 then
		return 2
	elseif level == 38 then
		return 3
	elseif level == 40 then
		return 4
	elseif level == 45 then
		return 5
	elseif level == 50 then
		return 6
	elseif level == 65 then
		return 7
	elseif level == 70 then
		return 8
	elseif level == 75 then
		return 9
	elseif level == 80 then
		return 10
	elseif level == 85 then
		return 11
	elseif level == 90 then
		return 12
	else
		return 0
	end
end

