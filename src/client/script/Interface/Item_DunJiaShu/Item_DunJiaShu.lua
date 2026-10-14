
-- zhangchenyue
-- 遁甲奇(天)书专用界面，请不要用于其他功能，
--

local g_SERVER_CONTROL_1 = 1122361   --遁甲天书使用界面
local g_SERVER_CONTROL_2 = 1122371   --遁甲奇书使用界面
local g_SERVER_CONTROL_3 = 330061	 --遁甲书VIP专用使用界面

local g_Client_ItemIndex = 0
local g_CurSelectIndex_DJTS = 0
local g_CurSelectIndex_DJQS = 0
local g_CurSelectIndex_DJVIP = 0

local g_CurSelectPage = 1

local g_DJTS_MAX_USETIMES =50
local g_DJTS_INIT_USETIMES =20
local g_DJQS_MAX_USETIMES =20


local g_Type	-- "useDJTS"使用遁甲天书
		        -- "useDJQS"使用遁甲奇书
		        -- "useDJVIP"使用遁甲书VIP

local g_Item_DunJiaShu_Frame_UnifiedPosition;

local PosBtnArray = {}
local PosBtnTextArray = {}
local YeQianBtnArray = {}

local g_defBtnTextCr = "#cfff263#e000001"

--缺省场景,仅显示需要
local DefaultScn=
{
	{"#{DJTS_110509_34}",401,223,225},	--秦皇地宫二层
	{"#{DJTS_110509_35}",203,31,33},	--秦皇地宫四层
	{"#{DJTS_110509_36}",161,13,25},	--燕王古墓三层
	{"#{DJTS_110509_37}",165,25,108},	--燕王古墓七层
}

--===============================================
-- PreLoad()
--===============================================
function Item_DunJiaShu_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--===============================================
-- OnLoad()
--===============================================
function Item_DunJiaShu_OnLoad()
	g_Item_DunJiaShu_Frame_UnifiedPosition=Item_DunJiaShu_Frame:GetProperty("UnifiedPosition");
	PosBtnArray[1] = Item_DunJiaShu_Btn01
	PosBtnArray[2] = Item_DunJiaShu_Btn02
	PosBtnArray[3] = Item_DunJiaShu_Btn03
	PosBtnArray[4] = Item_DunJiaShu_Btn04
	PosBtnArray[5] = Item_DunJiaShu_Btn05
	PosBtnArray[6] = Item_DunJiaShu_Btn06
	PosBtnArray[7] = Item_DunJiaShu_Btn07
	PosBtnArray[8] = Item_DunJiaShu_Btn08
	PosBtnArray[9] = Item_DunJiaShu_Btn09
	PosBtnArray[10] = Item_DunJiaShu_Btn10
	
	YeQianBtnArray[1] = Item_DunJiaShu_yeqian01
	YeQianBtnArray[2] = Item_DunJiaShu_yeqian02
	YeQianBtnArray[3] = Item_DunJiaShu_yeqian03

	PosBtnTextArray [1] = string.format("%s(%d,%d)", DefaultScn[1][1], DefaultScn[1][3], DefaultScn[1][4])
	PosBtnTextArray [2] = string.format("%s(%d,%d)", DefaultScn[2][1], DefaultScn[2][3], DefaultScn[2][4])
	PosBtnTextArray [3] = string.format("%s(%d,%d)", DefaultScn[3][1], DefaultScn[3][3], DefaultScn[3][4])
	PosBtnTextArray [4] = string.format("%s(%d,%d)", DefaultScn[4][1], DefaultScn[4][3], DefaultScn[4][4])
	PosBtnTextArray [5] = "#{DJTS_110509_07}"
	PosBtnTextArray [6] = "#{DJTS_110509_07}"
	PosBtnTextArray [7] = "#{DJTS_110509_07}"
	PosBtnTextArray [8] = "#{DJTS_110509_07}"
	PosBtnTextArray [9] = "#{DJTS_110509_07}"
	PosBtnTextArray [10] = "#{DJTS_110509_07}"
end

--===============================================
-- OnEvent()
--===============================================
function Item_DunJiaShu_OnEvent(event)

	if ( event == "UI_COMMAND" ) and tonumber(arg0) == g_SERVER_CONTROL_1 then
		if tonumber(arg2)==1 then
			if PlayerPackage:CheckDunJiaShuPosInfo() == 0 then
				PlayerPackage:AskDunJiaShuPosInfo()
				return
			end
			g_Client_ItemIndex = tonumber(arg1)
			Item_DunJiaShu_Show("useDJTS") --使用遁甲天书
			g_Type = "useDJTS"
		else
		    Item_DunJiaShu_ShengYu:SetText("#{DJTS_110509_03} "..Get_XParam_INT(0).."/"..g_DJTS_MAX_USETIMES);
		end
	elseif ( event == "UI_COMMAND" ) and tonumber(arg0) == g_SERVER_CONTROL_2 then
		if tonumber(arg2)==1 then
			if PlayerPackage:CheckDunJiaShuPosInfo() == 0 then
				PlayerPackage:AskDunJiaShuPosInfo()
				return
			end
			g_Client_ItemIndex = tonumber(arg1)
			Item_DunJiaShu_Show("useDJQS")--使用遁甲奇书
			g_Type = "useDJQS"
		else
		   Item_DunJiaShu_ShengYu:SetText("#{DJTS_110509_03} "..Get_XParam_INT(0).."/"..g_DJQS_MAX_USETIMES);
		end
	elseif (event == "UI_COMMAND") and tonumber(arg0) == g_SERVER_CONTROL_3 then
		if PlayerPackage:CheckDunJiaShuPosInfo() == 0 then
			PlayerPackage:AskDunJiaShuPosInfo()
			return
		end
		g_Client_ItemIndex = tonumber(arg1)
		Item_DunJiaShu_Show("useDJVIP")--使用遁甲书VIP
		g_Type = "useDJVIP"

	elseif event == "HIDE_ON_SCENE_TRANSED"  then
	
			this:Hide()
	


	elseif (event == "ADJEST_UI_POS" ) then
		Item_DunJiaShu_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Item_DunJiaShu_Frame_On_ResetPos()
	end
end

--===============================================
-- Show()
--===============================================
function Item_DunJiaShu_Show(event)

-- 	if IsInTServer() == 1 then
-- --		PushDebugMessage("#{BHKF_140909_327}")
-- 		PushDebugMessage("1")
-- 		return
-- 	end
	
	for i=1, table.getn(YeQianBtnArray) do
		if g_CurSelectPage == i then
			YeQianBtnArray[i]:SetCheck(1)
		else
			YeQianBtnArray[i]:SetCheck(0)
		end
	end

	if event == "useDJTS"  then
		local Level = 0;
		Level = Player:GetData("LEVEL");
		if Player ~= nil and Player:GetData("LEVEL") < 10 then
			PushDebugMessage("#{GMTripperObj_Resource_Info_Level_Not_Enough}");
			return
		end

		--Item_DunJiaShu_DingWei:SetText("#{DJTS_110509_05}")	        --定位
		--Item_DunJiaShu_ChuanSong:SetText("#{DJTS_110509_06}")	        --传送

        if SystemSetup:IsClassic() == 1 then
    		Item_DunJiaShu_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_Index")--遁甲天书
        else
            Item_DunJiaShu_Title:SetText("#{UIGZ_130816_2}")--遁甲天书
        end
		Item_DunJiaShu_Info:SetText("#{DJTS_110509_02}")		--遁甲天书介绍
		Item_DunJiaShu_BuChong:Show()

		for i=1,table.getn(PosBtnArray) do
			PosBtnArray[i]:SetCheck(0)
			local nIdx = (g_CurSelectPage-1)*10 + i-1 
			local sceneid, strText, count, posx, posy, init = PlayerPackage:GetDunJiaShuPosInfo(g_Client_ItemIndex, nIdx)
			strText = string.format("%s(%d,%d)", strText, posx, posy)
			if sceneid < 0 then
				if g_CurSelectPage == 1 then
					PosBtnArray[i]:SetText(g_defBtnTextCr..PosBtnTextArray[i])
				else
					PosBtnArray[i]:SetText(g_defBtnTextCr.."#{DJTS_110509_07}")
				end
			else
				PosBtnArray[i]:SetText(g_defBtnTextCr..strText)
 			end

			--第一次使用 彻地符箓
			if init==0 then
				count = g_DJTS_INIT_USETIMES
			end

			Item_DunJiaShu_ShengYu:SetText("#{DJTS_110509_03} "..count.."/"..g_DJTS_MAX_USETIMES);

		end

		local nCurPage = math.floor(g_CurSelectIndex_DJTS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJTS, 100)		
		if nCurIdx ~= 0 and PosBtnArray[nCurIdx] ~= nil and nCurPage == g_CurSelectPage then
			PosBtnArray[nCurIdx]:SetCheck(1)
		end

		-- 添加倒计时
		--Item_DunJiaShu_StopWatch : SetProperty("Timer",tostring(20));
		--Item_DunJiaShu_StopWatch:Show()

		if nCurIdx == 0 or nCurPage ~= g_CurSelectPage then
			Item_DunJiaShu_DingWei:Disable()
	        Item_DunJiaShu_ChuanSong:Disable()
		else
			Item_DunJiaShu_DingWei:Enable()
			Item_DunJiaShu_ChuanSong:Enable()
		end

		this:Show()

	elseif event == "useDJQS"  then
		local Level = 0;
		Level = Player:GetData("LEVEL");
		if Player ~= nil and Player:GetData("LEVEL") < 10 then
			PushDebugMessage("#{GMTripperObj_Resource_Info_Level_Not_Enough}");
			return
		end

		--Item_DunJiaShu_DingWei:SetText("#{DJTS_110509_05}")	--定位
		--Item_DunJiaShu_ChuanSong:SetText("#{DJTS_110509_06}")	--传送

        if SystemSetup:IsClassic() == 1 then
		    Item_DunJiaShu_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_Monster")--遁甲天书	        --遁甲奇书
        else
            Item_DunJiaShu_Title:SetText("#{UIGZ_130816_1}")--遁甲天书	        --遁甲奇书            
        end
		Item_DunJiaShu_Info:SetText("#{DJTS_110509_26}")	        --遁甲奇书介绍
		Item_DunJiaShu_BuChong:Show()

		for i=1,table.getn(PosBtnArray) do
			PosBtnArray[i]:SetCheck(0)
			local nIdx = (g_CurSelectPage-1)*10 + i-1 
			local sceneid, strText, count, posx, posy, init = PlayerPackage:GetDunJiaShuPosInfo(g_Client_ItemIndex, nIdx)
			strText = string.format("%s(%d,%d)", strText, posx, posy)
			if sceneid < 0 then
				if g_CurSelectPage == 1 then
					PosBtnArray[i]:SetText(g_defBtnTextCr..PosBtnTextArray[i])
				else
					PosBtnArray[i]:SetText(g_defBtnTextCr.."#{DJTS_110509_07}")
				end
			else
				PosBtnArray[i]:SetText(g_defBtnTextCr..strText)
 			end

			--第一次使用 通天符箓
			if init==0 then
				count = g_DJQS_MAX_USETIMES
			end

			Item_DunJiaShu_ShengYu:SetText("#{DJTS_110509_03} "..count.."/"..g_DJQS_MAX_USETIMES);

		end

		local nCurPage = math.floor(g_CurSelectIndex_DJQS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJQS, 100)
		
		if nCurIdx ~= 0 and nCurPage == g_CurSelectPage and PosBtnArray[nCurIdx] ~= nil then
			PosBtnArray[nCurIdx]:SetCheck(1)
		end

		-- 添加倒计时
		--Item_DunJiaShu_StopWatch : SetProperty("Timer",tostring(20));
		--Item_DunJiaShu_StopWatch:Show()

		if nCurIdx == 0 or nCurPage ~= g_CurSelectPage then
			Item_DunJiaShu_DingWei:Disable()
	        Item_DunJiaShu_ChuanSong:Disable()
		else
			Item_DunJiaShu_DingWei:Enable()
	        Item_DunJiaShu_ChuanSong:Enable()
		end

		this:Show()

	elseif event == "useDJVIP"  then
		local Level = Player:GetData("LEVEL")
		if Player:GetData("LEVEL") < 10 then
			PushDebugMessage("#{GMTripperObj_Resource_Info_Level_Not_Enough}")
			return
		end
		
        if SystemSetup:IsClassic() == 1 then
		    Item_DunJiaShu_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_VIP")		--遁甲书VIP
        else
            Item_DunJiaShu_Title:SetText("#{UIGZ_130816_3}")		--遁甲书VIP
        end
		Item_DunJiaShu_Info:SetText("#{VIPTQ_110908_70}")	--遁甲奇书介绍
		Item_DunJiaShu_BuChong:Hide()
		
		for i = 1, table.getn(PosBtnArray) do
			PosBtnArray[i]:SetCheck(0)
			local nIdx = (g_CurSelectPage-1)*10 + i-1 
			local sceneid, strText, posx, posy, usedCount, maxUseCount = PlayerPackage:GetDunJiaShuVIPPosInfo(g_Client_ItemIndex, nIdx)
			strText = string.format("%s(%d,%d)", strText, posx, posy)
			if sceneid < 0 then
				if g_CurSelectPage == 1 then
					PosBtnArray[i]:SetText(g_defBtnTextCr..PosBtnTextArray[i])
				else
					PosBtnArray[i]:SetText(g_defBtnTextCr.."#{DJTS_110509_07}")
				end
			else
				PosBtnArray[i]:SetText(g_defBtnTextCr..strText)
 			end
			
			--瞬影符箓
			Item_DunJiaShu_ShengYu:SetText("#{DJTS_110509_03} "..usedCount.."/"..maxUseCount)
		end
		
		local nCurPage = math.floor(g_CurSelectIndex_DJVIP / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJVIP, 100)
		if nCurIdx ~= 0 and PosBtnArray[nCurIdx] ~= nil and nCurPage == g_CurSelectPage then
			PosBtnArray[nCurIdx]:SetCheck(1)
		end
		
		if nCurIdx == 0 or nCurPage ~= g_CurSelectPage then
			Item_DunJiaShu_DingWei:Disable()
	        Item_DunJiaShu_ChuanSong:Disable()
		else
			Item_DunJiaShu_DingWei:Enable()
	        Item_DunJiaShu_ChuanSong:Enable()
		end
		
		this:Show()

	else
		return
	end

end

function Item_DunJiaShu_TimeOut()
	this:Hide()
end

--===============================================
-- 补充符咒
--===============================================
function Item_DunJiaShu_BuChong_Clicked()

	if g_Type == "useDJTS"  then

		PlayerPackage:UseDunJiaTianShuBuChong(g_Client_ItemIndex)

	elseif g_Type == "useDJQS"  then

		PlayerPackage:UseDunJiaQiShuBuChong(g_Client_ItemIndex)
	end

	--this:Hide()
end

--===============================================
-- 定位
--===============================================
function Item_DunJiaShu_DingWei_Clicked()

	if g_Type == "useDJTS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJTS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJTS, 100)
		
		if nCurIdx <= 0 or nCurPage ~= g_CurSelectPage then
			return
		end

		if nCurIdx <= table.getn(DefaultScn) then
			PlayerPackage:UseDunJiaTianShuSetpos(g_Client_ItemIndex, nCurPage, nCurIdx-1, DefaultScn[nCurIdx][2], DefaultScn[nCurIdx][3], DefaultScn[nCurIdx][4])
		else
			PlayerPackage:UseDunJiaTianShuSetpos(g_Client_ItemIndex, nCurPage, nCurIdx-1)
		end

	elseif g_Type == "useDJQS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJQS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJQS, 100)
		
		if nCurIdx <= 0 or nCurPage ~= g_CurSelectPage then
			return
        end

		if nCurIdx <= table.getn(DefaultScn) then
			PlayerPackage:UseDunJiaQiShuSetpos(g_Client_ItemIndex, nCurPage, nCurIdx-1, DefaultScn[nCurIdx][2], DefaultScn[nCurIdx][3], DefaultScn[nCurIdx][4])
		else
			PlayerPackage:UseDunJiaQiShuSetpos(g_Client_ItemIndex, nCurPage, nCurIdx-1)
		end
		
	elseif g_Type == "useDJVIP" then
		
		local nCurPage = math.floor(g_CurSelectIndex_DJVIP / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJVIP, 100)
		
		if nCurIdx <= 0 or nCurPage ~= g_CurSelectPage then
			return
        end
		
		if nCurIdx <= table.getn(DefaultScn) then
			PlayerPackage:UseDunJiaVIPSetpos(g_Client_ItemIndex, nCurPage, nCurIdx-1, DefaultScn[nCurIdx][2], DefaultScn[nCurIdx][3], DefaultScn[nCurIdx][4])
		else
			PlayerPackage:UseDunJiaVIPSetpos(g_Client_ItemIndex, nCurPage, nCurIdx-1)
		end

	end

	this:Hide()

end

--===============================================
-- 传送
--===============================================
function Item_DunJiaShu_ChuanSong_Clicked()
	if g_Type == "useDJVIP" then
		local pos, strText, posx, posy, count, maxUseCount = PlayerPackage:GetDunJiaShuVIPPosInfo(g_Client_ItemIndex, 0)
		if count == 0 then
			PushDebugMessage("#{VIPTQ_110908_74}")
			this:Hide()
			return
		end
	else
		local pos, strText, count, posx, posy, init = PlayerPackage:GetDunJiaShuPosInfo(g_Client_ItemIndex, 0)
		if init~=0 and count == 0 then
			PushDebugMessage("#{DJTS_110509_51}"); --符咒耗尽，请使用遁地符补充符咒
			this:Hide()
			return
		end
	end

	if g_Type == "useDJTS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJTS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJTS, 100)
		
		if nCurIdx <= 0 or nCurPage ~= g_CurSelectPage then
			return
		end

		if nCurIdx <= table.getn(DefaultScn) then
			PlayerPackage:UseDunJiaTianShuChuanSong(g_Client_ItemIndex, nCurPage, nCurIdx-1, DefaultScn[nCurIdx][2], DefaultScn[nCurIdx][3], DefaultScn[nCurIdx][4])
		else
			PlayerPackage:UseDunJiaTianShuChuanSong(g_Client_ItemIndex, nCurPage, nCurIdx-1)
		end

	elseif g_Type == "useDJQS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJQS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJQS, 100)
		
		if nCurIdx <= 0 or nCurPage ~= g_CurSelectPage then
			return
        end

		if nCurIdx <= table.getn(DefaultScn) then
			PlayerPackage:UseDunJiaQiShuChuanSong(g_Client_ItemIndex, nCurPage, nCurIdx-1, DefaultScn[nCurIdx][2], DefaultScn[nCurIdx][3], DefaultScn[nCurIdx][4])
		else
			PlayerPackage:UseDunJiaQiShuChuanSong(g_Client_ItemIndex, nCurPage, nCurIdx-1)
		end

	elseif g_Type == "useDJVIP" then
		local nCurPage = math.floor(g_CurSelectIndex_DJVIP / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJVIP, 100)
		
		if nCurIdx <= 0 or nCurPage ~= g_CurSelectPage then
			return
        end

		if nCurIdx <= table.getn(DefaultScn) then
			PlayerPackage:UseDunJiaVIPChuanSong(g_Client_ItemIndex, nCurPage, nCurIdx-1, DefaultScn[nCurIdx][2], DefaultScn[nCurIdx][3], DefaultScn[nCurIdx][4])
		else
			PlayerPackage:UseDunJiaVIPChuanSong(g_Client_ItemIndex, nCurPage, nCurIdx-1)
		end

	end

	this:Hide()
end

--===============================================
-- 帮助
--===============================================
function Item_DunJiaShu_Help()

end

function Item_DunJiaShu_Frame_On_ResetPos()
  Item_DunJiaShu_Frame:SetProperty("UnifiedPosition", g_Item_DunJiaShu_Frame_UnifiedPosition);
end

function Item_DunJiaShu_Btn_Clicked(arg)
	if g_Type == "useDJTS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJTS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJTS, 100)
		if nCurIdx > 0 and PosBtnArray[nCurIdx] ~= nil and nCurPage == g_CurSelectPage then
			PosBtnArray[nCurIdx]:SetCheck(0)
		end
		if PosBtnArray[arg] ~= nil then 
			g_CurSelectIndex_DJTS = arg + g_CurSelectPage * 100
			PosBtnArray[arg]:SetCheck(1)
		end
		Item_DunJiaShu_DingWei:Enable()
		Item_DunJiaShu_ChuanSong:Enable()
	elseif g_Type == "useDJQS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJQS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJQS, 100)
		if nCurIdx > 0 and PosBtnArray[nCurIdx] ~= nil and nCurPage == g_CurSelectPage then
			PosBtnArray[nCurIdx]:SetCheck(0)
		end
		if PosBtnArray[arg] ~= nil then 
			g_CurSelectIndex_DJQS = arg + g_CurSelectPage * 100
			PosBtnArray[arg]:SetCheck(1)
		end
		Item_DunJiaShu_DingWei:Enable()
        Item_DunJiaShu_ChuanSong:Enable()
	elseif g_Type == "useDJVIP" then
		local nCurPage = math.floor(g_CurSelectIndex_DJVIP / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJVIP, 100)
		if nCurIdx > 0 and PosBtnArray[nCurIdx] ~= nil and nCurPage == g_CurSelectPage then
			PosBtnArray[nCurIdx]:SetCheck(0)
		end
		if PosBtnArray[arg] ~= nil then 
			g_CurSelectIndex_DJVIP = arg + g_CurSelectPage * 100
			PosBtnArray[arg]:SetCheck(1)
		end
		Item_DunJiaShu_DingWei:Enable()
        Item_DunJiaShu_ChuanSong:Enable()
	end
end

function Item_DunJiaShu_Btn_MouseLeave()
		
	for i=1, table.getn(YeQianBtnArray) do
		if g_CurSelectPage == i then
			YeQianBtnArray[i]:SetCheck(1)
		else
			YeQianBtnArray[i]:SetCheck(0)
		end
	end

	if g_Type == "useDJTS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJTS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJTS, 100)
		for i=1,table.getn(PosBtnArray) do
			if i == nCurIdx and nCurPage == g_CurSelectPage then
				PosBtnArray[i]:SetCheck(1)
			else
				PosBtnArray[i]:SetCheck(0)
			end
		end
	
	elseif g_Type == "useDJQS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJQS / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJQS, 100)
		for i=1,table.getn(PosBtnArray) do
			if i == nCurIdx and nCurPage == g_CurSelectPage then
				PosBtnArray[i]:SetCheck(1)
			else
				PosBtnArray[i]:SetCheck(0)
			end
		end
	
	elseif g_Type == "useDJVIP"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJVIP / 100)
		local nCurIdx = math.mod(g_CurSelectIndex_DJVIP, 100)
		for i=1,table.getn(PosBtnArray) do
			if i == nCurIdx and nCurPage == g_CurSelectPage then
				PosBtnArray[i]:SetCheck(1)
			else
				PosBtnArray[i]:SetCheck(0)
			end
		end
	
	end
end

function Item_DunJiaShu_PageClick(nPageIdx)

	g_CurSelectPage = nPageIdx
	
	if g_Type == "useDJTS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJTS / 100)
		if nCurPage ~= g_CurSelectPage then
			g_CurSelectIndex_DJTS = 0
		end
	elseif g_Type == "useDJQS"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJQS / 100)
		if nCurPage ~= g_CurSelectPage then
			g_CurSelectIndex_DJQS = 0
		end
	elseif g_Type == "useDJVIP"  then
		local nCurPage = math.floor(g_CurSelectIndex_DJVIP / 100)
		if nCurPage ~= g_CurSelectPage then
			g_CurSelectIndex_DJVIP = 0
		end
	end
	
	if g_Type == "useDJTS" or g_Type == "useDJQS" or g_Type == "useDJVIP" then
		Item_DunJiaShu_Show(g_Type)
	end
	
end

