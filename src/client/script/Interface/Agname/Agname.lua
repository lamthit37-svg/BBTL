--Write by Manda
local g_Agname_Frame_UnifiedPosition;

--当前使用的属性称号
local g_Agname_curEffIndex = -1;  --所有称号的索引
--当前使用的称号
local g_Agname_curIndex = -1;  --所有称号的索引

--所有称号属性缓存
local g_Agname_EffTbl_Str = {};
local g_Agname_EffTbl_Str_Odd = {};
local g_Agname_EffTbl_Name = {};
local g_Agname_EffNum = 1;

--拥有称号属性缓存

local g_Agname_Owner_EffTbl_Index = {};
local g_Agname_Owner_EffTbl_Name = {};
local g_Agname_Owner_EffNum = 1;

--把拥有的称号保存一下
local g_Agname_HAVEGET_Index = {};
local g_Agname_HAVEGET_Name = {};
local g_Agname_HAVEGET_Name_EffNum = 1;

--YueLi点
local g_Agname_YueLi_Index = {};
local g_Agname_YueLi_Name = {};
local g_Agname_YueLi_Name_EffNum = 1;
local g_Agname_YueLi_curEffIndex = 1;

local g_AgnameListScrollbarPos = 0.0
local g_AgnameAllCnt = 0



local g_nTitleLeftButton = {}
local g_nTableIndex = 1
local g_nCurSelectListIndex = 1	--当前选中的列表项 阅历
local g_nCurSelectAllTileListIndex = 1
local g_TitleListImage = "Ach_AchIcon_Cup" --无效的 调用的时候，显示空图片
local g_TitleListImageSet = "Ach" --无效的 调用的时候，显示空图片
local g_TitleListTextImage = "ChenHao_X" --有效的 
local g_TitleListTextImageSet = "CommonFrame37" --有效的
local g_TitleListTextImage_shuxing = "ChenHao_S" --属性 有效的 
local g_TitleListTextImageSet_shuxing = "CommonFrame37" --属性 有效的
local g_TitleListTextImage_shuangxian = "ChenHao_Z" --双显 有效的 
local g_TitleListTextImageSet_shuangxian = "CommonFrame37" --双显 有效的 



local g_TitleButtonFlag = 1



local g_nTitleLeftButton_shuxing = {}
local g_nTitleLeftButton_Yueli = {}

local enum_Cur = 1
local enum_Shuxing = 0
local enum_Double = 2
local g_Agname_Zoneworldid = -1
local g_LongMenPingBi = {
[1453]=1,
[1454]=1,
[1455]=1,
[1492]=1,
[1493]=1,
[1494]=1,
[1495]=1,
[1554]=1,
[1555]=1,
[1556]=1,
[1557]=1
}
function Agname_PreLoad()
	this:RegisterEvent("OPEN_AGNAME",true);
	this:RegisterEvent("CLOSE_AGNAME",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("CUR_TITLE_CHANGED",false)
	this:RegisterEvent("CHANGE_VIRTUAL_TITLE",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND", true);
end

function Agname_OnLoad()
  g_Agname_Frame_UnifiedPosition=Agname_Frame:GetProperty("UnifiedPosition");
  g_Agname_Zoneworldid = DataPool:GetSelfZoneWorldID();
end

-- OnEvent
function Agname_OnEvent(event)
	if ( event == "OPEN_AGNAME" ) then
		this:TogleShow();
		g_nTableIndex = 1
		Agname_Chenghao:SetCheck(1)
		Agname_Yueli:SetCheck(0)
		Agname_UpdateFrame();
	end
	if ( event == "CUR_TITLE_CHANGED" ) then
		--Lua_TDU_Log("CUR_TITLE")


		--Agname_SelectAgname:ClearListBox();
		--Agname_UpdateFrame的展开实现
		Agname_PlayerTitle:SetText("")
		
		if g_nTableIndex == 0 or g_nTableIndex == 1 then
			Agname_Frame_FenYeWindow1:SetProperty("Visible" , "True" )
			Agname_Frame_FenYeWindow2:SetProperty("Visible" , "False" )
		else
			Agname_Frame_FenYeWindow1:SetProperty("Visible" , "False" )
			Agname_Frame_FenYeWindow2:SetProperty("Visible" , "True" )	
		end

		Agname_LeftLoad()
		if g_Agname_curIndex ~= -1 then
			g_nCurSelectAllTileListIndex = g_Agname_curIndex
		end
		--Lua_TDU_Log("g_nCurSelectAllTileListIndex="..g_nCurSelectAllTileListIndex)
		Agname_Frame_SetLeftButtonSelected(g_nCurSelectAllTileListIndex)
		Agname_ShowIcon(g_nCurSelectAllTileListIndex)
		
	end
	if ( event == "CHANGE_VIRTUAL_TITLE" ) then
		--Lua_TDU_Log("VIRTUALTITLE")


		--Agname_SelectAgname:ClearListBox();
		--Agname_UpdateFrame的展开实现
		Agname_PlayerTitle:SetText("")
		
		if g_nTableIndex == 0 or g_nTableIndex == 1 then
			Agname_Frame_FenYeWindow1:SetProperty("Visible" , "True" )
			Agname_Frame_FenYeWindow2:SetProperty("Visible" , "False" )
		else
			Agname_Frame_FenYeWindow1:SetProperty("Visible" , "False" )
			Agname_Frame_FenYeWindow2:SetProperty("Visible" , "True" )	
		end

		Agname_LeftLoad()
		if g_Agname_curEffIndex ~= -1 then
			g_nCurSelectAllTileListIndex = g_Agname_curEffIndex
		end
		Agname_Frame_SetLeftButtonSelected(g_nCurSelectAllTileListIndex)
		Agname_ShowIcon(g_nCurSelectAllTileListIndex)
	end	
	if ( event == "CLOSE_AGNAME" ) then
		this:Hide();
	end

		-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Agname_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Agname_Frame_On_ResetPos()
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88894403 then --准备阶段
		Agname_Yulanxianshi:SetText("显示")	
		Player:SetNullAgname();
		g_Agname_curIndex = -1	
		g_TitleButtonFlag = 1
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 998429010 then --准备阶段
		Agname_Yulanxianshi:SetText("显示")	
		Player:SetNullAgname();
		g_Agname_curIndex = -1	
		g_TitleButtonFlag = 1
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 331141010 then --准备阶段
		Agname_Yulanxianshi:SetText("显示")	
		Player:SetNullAgname();
		g_Agname_curIndex = -1	
		g_TitleButtonFlag = 1
	end
	
end

function Agname_UpdateFrame()
	--清空


	--Agname_SelectAgname:ClearListBox();

	Agname_PlayerTitle:SetText("")
	
	if g_nTableIndex == 0 or g_nTableIndex == 1 then
		Agname_Frame_FenYeWindow1:SetProperty("Visible" , "True" )
		Agname_Frame_FenYeWindow2:SetProperty("Visible" , "False" )
	else
		Agname_Frame_FenYeWindow1:SetProperty("Visible" , "False" )
		Agname_Frame_FenYeWindow2:SetProperty("Visible" , "True" )	
	end

	Agname_LeftLoad()
	Agname_Frame_SetLeftButtonSelected(g_nCurSelectAllTileListIndex)
	Agname_ShowIcon(g_nCurSelectAllTileListIndex)
end


function Agname_HideTitle_Clicked()

	Agname_Currently:SetText("");
	Player:SetNullAgname();
end




--================================================
-- 恢复界面的默认相对位置
--================================================
function Agname_Frame_On_ResetPos()
  Agname_Frame:SetProperty("UnifiedPosition", g_Agname_Frame_UnifiedPosition);
end


--左侧家具类型加载		
function Agname_LeftLoad()
	
		--拥有称号
		if g_nTableIndex == 2 then
		else
			local nCheck = Agname_Shuxingchenghaoxianshi:GetCheck()
			if nCheck == 1 then
				g_nTableIndex = 0 --属性称号
				Agname_ListContent:Hide()
				Agname_ListContent_Lace:Hide()
				Agname_ListContent1:Show()
				Agname_ListContent_Lace1:Show()
			else
				g_nTableIndex = 1 --所有称号
				Agname_ListContent:Show()
				Agname_ListContent_Lace:Show()
				Agname_ListContent1:Hide()
				Agname_ListContent_Lace1:Hide()
			end
		end
		if g_nTableIndex == 2 then
			g_AgnameAllCnt = Player:GetShowUITitleCnt("YueLi") 
		elseif g_nTableIndex == 1 then
			g_AgnameAllCnt = Player:GetShowUITitleCnt("AllTitle") 
		elseif g_nTableIndex == 0 then
			g_AgnameAllCnt = Player:GetShowUITitleCnt("shuxing") 
		end

		if g_nTableIndex == 2 and table.getn(g_nTitleLeftButton_Yueli) ~= g_AgnameAllCnt   then  
			Agname_YueliAgname:CleanAllElement("Agname")
		elseif  g_nTableIndex == 1 and table.getn(g_nTitleLeftButton) ~= g_AgnameAllCnt then  
			--Lua_TDU_Log("table.getn(g_nTitleLeftButton)="..table.getn(g_nTitleLeftButton).." Player:GetShowUITitleCnt="..Player:GetShowUITitleCnt("AllTitle") )
			Agname_ListContent:CleanAllElement("Agname")
		elseif g_nTableIndex == 0 and table.getn(g_nTitleLeftButton_shuxing) ~= g_AgnameAllCnt  then  --属性
			Agname_ListContent1:CleanAllElement("Agname")
		end
				
		------------------------装载称号属性------------------------
		g_Agname_curEffIndex = -1;  --所有称号的索引
		--当前使用的称号
		g_Agname_curIndex = -1;  --所有称号的索引

		--所有称号属性缓存
		g_Agname_EffTbl_Str = {};
		g_Agname_EffTbl_Str_Odd = {};
		g_Agname_EffTbl_Name = {};
		g_Agname_EffNum = 1;

		--拥有称号属性缓存
		
		g_Agname_Owner_EffTbl_Index = {};
		g_Agname_Owner_EffTbl_Name = {};
		g_Agname_Owner_EffNum = 1;

		--把拥有的称号保存一下
		g_Agname_HAVEGET_Index = {};
		g_Agname_HAVEGET_Name = {};
		g_Agname_HAVEGET_Name_EffNum = 1;
		-----------------------装载称号属性-------------------------
	
		if g_nTableIndex == 1 and table.getn(g_nTitleLeftButton) ~= g_AgnameAllCnt   then  
			g_nTitleLeftButton = {}
		end
		if g_nTableIndex == 0 and table.getn(g_nTitleLeftButton_shuxing) ~= g_AgnameAllCnt  then  	
			g_nTitleLeftButton_shuxing = {}
		end
		if g_nTableIndex == 2 and table.getn(g_nTitleLeftButton_Yueli) ~= g_AgnameAllCnt   then  
			g_nTitleLeftButton_Yueli = {}
		end

		
		local curAgname = Player:GetCurrentAgname()
		local curTitleType = Player:Player_GetTitleType()
		local curVirtualAgname = Player:GetCurrentVirtualAgname()					
		local curVirtualAgnameType = Player:GetCurrentVirtualAgnameType()

		if g_nTableIndex == 0 then --属性称号
			--加入所有称号名
			local effect
			local effect_Odd
			Lua_InitTitleTable(0)
			local nsize = Lua_GetTitleElementSize()
			
			for j = 1,nsize do
				local nTitleype,nGetHave,nID,nNum,nType,szString,effect,effect_Odd = Lua_GetTitleListElementByIndex(j)
				if nTitleype == 1 then
					g_Agname_curIndex = j
					Agname_ShuXingTitleAddText(szString,nGetHave,j,enum_Cur)  
				elseif nTitleype == 2 then
					g_Agname_curEffIndex = j
					Agname_ShuXingTitleAddText(szString,nGetHave,j,enum_Shuxing)  
				elseif nTitleype == 3 then
					g_Agname_curIndex = j
					g_Agname_curEffIndex = j
					Agname_ShuXingTitleAddText(szString,nGetHave,j,enum_Double) 
				else
					Agname_ShuXingTitleAddText(szString,nGetHave,j,-1)  
				end
				if effect ~= "" and effect ~= nil then
					g_Agname_EffTbl_Str[g_Agname_EffNum] = effect;
					g_Agname_EffTbl_Str_Odd[g_Agname_EffNum] = effect_Odd;
				else
					g_Agname_EffTbl_Str[g_Agname_EffNum] = "";
					g_Agname_EffTbl_Str_Odd[g_Agname_EffNum] = "";
				end
				g_Agname_EffTbl_Name[g_Agname_EffNum] = szString;
				g_Agname_EffNum = g_Agname_EffNum + 1		
			end	

		end

		if g_nTableIndex == 1 then   --所有称号
			local effect
			local effect_Odd
			Lua_InitTitleTable(1)
			local nsize = Lua_GetTitleElementSize()
			for j = 1,nsize do
				local nTitleype,nGetHave,nID,nNum,nType,szString,effect,effect_Odd = Lua_GetTitleListElementByIndex(j)
				if nTitleype == 1 then
					g_Agname_curIndex = j
					Agname_AllTitleAddText(szString,nGetHave,j,enum_Cur)  
				elseif nTitleype == 2 then
					g_Agname_curEffIndex = j
					Agname_AllTitleAddText(szString,nGetHave,j,enum_Shuxing)  
				elseif nTitleype == 3 then
					g_Agname_curIndex = j
					g_Agname_curEffIndex = j
					Agname_AllTitleAddText(szString,nGetHave,j,enum_Double) 
				else
					Agname_AllTitleAddText(szString,nGetHave,j,-1)  
				end
				if effect ~= "" and effect ~= nil then
					g_Agname_EffTbl_Str[g_Agname_EffNum] = effect;
					g_Agname_EffTbl_Str_Odd[g_Agname_EffNum] = effect_Odd;
				else
					g_Agname_EffTbl_Str[g_Agname_EffNum] = "";
					g_Agname_EffTbl_Str_Odd[g_Agname_EffNum] = "";
				end
				g_Agname_EffTbl_Name[g_Agname_EffNum] = szString;
				g_Agname_EffNum = g_Agname_EffNum + 1		
			end	
		end

		if g_nTableIndex == 2 then
			
			--加入所有称号名
			local effect
			local effect_Odd
			Lua_InitTitleTable(2)
			local nsize = Lua_GetTitleElementSize()
			
			for j = 1,nsize do
				local nTitleype,nGetHave,nID,nNum,nType,szString,effect,effect_Odd = Lua_GetTitleListElementByIndex(j)
				if nTitleype == 1 then
					g_Agname_curIndex = j
					Agname_YueLiAddText(szString,nGetHave,j,enum_Cur)  
				elseif nTitleype == 2 then
					g_Agname_curEffIndex = j
					Agname_YueLiAddText(szString,nGetHave,j,enum_Shuxing)  
				elseif nTitleype == 3 then
					g_Agname_curIndex = j
					g_Agname_curEffIndex = j
					Agname_YueLiAddText(szString,nGetHave,j,enum_Double) 
				else
					Agname_YueLiAddText(szString,nGetHave,j,-1)  
				end
				if effect ~= "" and effect ~= nil then
					g_Agname_EffTbl_Str[g_Agname_EffNum] = effect;
					g_Agname_EffTbl_Str_Odd[g_Agname_EffNum] = effect_Odd;
				else
					g_Agname_EffTbl_Str[g_Agname_EffNum] = "";
					g_Agname_EffTbl_Str_Odd[g_Agname_EffNum] = "";
				end
				g_Agname_EffTbl_Name[g_Agname_EffNum] = szString;
				g_Agname_EffNum = g_Agname_EffNum + 1		
			end		

		end

		--把拥称号已经对应属性都保存一下

		local nAgnameNum = Player:GetAgnameNum();
		for k=0, nAgnameNum-1 do
			local szAgnameName, nAgType = Player:EnumAgname(k, "name", 0);
			local effect = Player:EnumAgname(k, "effect", 0,0)
			if effect ~= "" and effect ~= nil then
				
				g_Agname_Owner_EffTbl_Index[g_Agname_Owner_EffNum] = k; --这个再更改称号属性的时候会用    里面的索引没啥用 因为用的时候还是遍历 这里用table的insert 更好点
				g_Agname_Owner_EffTbl_Name[g_Agname_Owner_EffNum] = szAgnameName;
				g_Agname_Owner_EffNum = g_Agname_Owner_EffNum + 1;
			end
			--保存一下拥有的称号
			g_Agname_HAVEGET_Name[g_Agname_HAVEGET_Name_EffNum] = szAgnameName;
			g_Agname_HAVEGET_Index[g_Agname_HAVEGET_Name_EffNum] = k; --这个再更改称号属性的时候会用     里面的索引没啥用 因为用的时候还是遍历 这里用table的insert 更好点
			g_Agname_HAVEGET_Name_EffNum = g_Agname_HAVEGET_Name_EffNum + 1;			
		end	
		

		if g_nTableIndex == 1 then
			Agname_ListContent:SetVertScrollbarPosition(g_AgnameListScrollbarPos)
			Agname_ListContent:Flash()				
		elseif g_nTableIndex == 0 then
			Agname_ListContent1:SetVertScrollbarPosition(g_AgnameListScrollbarPos)
			Agname_ListContent1:Flash()		
		else
			Agname_YueliAgname:SetVertScrollbarPosition(g_AgnameListScrollbarPos)
			Agname_YueliAgname:Flash()				
		end
	
end


--对子类型数据进行排序
function Agname_SortID(a,b)

	local aID = a.ID
	local bID = b.ID
	
	local atype = a.Type
	local btype = b.Type


	local curAgname = Player:GetCurrentAgname()
	local curTitleType = Player:Player_GetTitleType()
	local curVirtualAgname = Player:GetCurrentVirtualAgname()		
	local curVirtualAgnameType = Player:GetCurrentVirtualAgnameType()

	local anHave = Player:HaveTitle(aID);
	local bnHave = Player:HaveTitle(bID);

	if curAgname ~="" and curAgname == a.String and anHave ==1 and ( aID < 1000  or ( aID >= 1000 and atype == curTitleType )) then
		return true
	end						
	
	if curAgname ~="" and curAgname == b.String and bnHave == 1 and ( bID < 1000  or ( bID >= 1000 and btype == curTitleType ))  then
		return false
	end				
	
	if curVirtualAgname ~="" and curVirtualAgname == a.String and anHave == 1 and ( aID  < 1000 or ( aID >= 1000 and atype == curVirtualAgnameType  )) then
		return true
	end						
	
	if curVirtualAgname ~="" and curVirtualAgname == b.String and bnHave   == 1 and ( bID  < 1000 or ( bID >= 1000 and btype == curVirtualAgnameType  ))   then
		return false
	end				
	
	if anHave == 1 and bnHave == 0 then
		return true
	end
	
	if anHave == 0 and bnHave == 1 then
		return false
	end
	

	if aID <  bID then
		return true  
	end
	
	return false
	
end


--所有称号增加子类型控件
function Agname_AllTitleAddText(nText,bHaveTitle,i,CurStatus)
	local nAllNum = g_AgnameAllCnt;
	--如果已经有足够的element 就不需要再创建新的了 。
	local TitleText
	if  ( g_nTableIndex == 1 and table.getn(g_nTitleLeftButton) ~= nAllNum ) then  
		TitleText = Agname_ListContent:AddItemElement("AgnameText","LEFT","Agname","","")	
	else 
		TitleText = g_nTitleLeftButton[i]
	end

	TitleText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	if bHaveTitle == 0 then 
		TitleText:AddTextTextAndImage("#c959595"..nText,g_TitleListImage,g_TitleListImageSet)--g_TitleListImageSet显示空图片
	else --yongyou称号
		if CurStatus == enum_Cur then
			TitleText:AddTextTextAndImage(nText,g_TitleListTextImage,g_TitleListTextImageSet)
			TitleText:SetImageTips("#{CHYH_180523_18}")
		elseif  CurStatus == enum_Shuxing then
			TitleText:AddTextTextAndImage(nText,g_TitleListTextImage_shuxing,g_TitleListTextImageSet_shuxing)	
			TitleText:SetImageTips("#{CHYH_180523_5}")
		elseif CurStatus == enum_Double then
			TitleText:AddTextTextAndImage(nText,g_TitleListTextImage_shuangxian,g_TitleListTextImageSet_shuangxian)
			TitleText:SetImageTips("#{CHYH_180523_58}")
		else
			TitleText:AddTextTextAndImage(nText,g_TitleListImage,g_TitleListImageSet)		
		end	
	end
	if g_nTableIndex == 1 and table.getn(g_nTitleLeftButton) ~= nAllNum  then  
		table.insert(g_nTitleLeftButton,TitleText)
	end
end
--所有称号增加子类型控件
function Agname_ShuXingTitleAddText(nText,bHaveTitle,i,CurStatus)
	local nAllNum = g_AgnameAllCnt;


	local TitleText
	if  ( g_nTableIndex == 0 and table.getn(g_nTitleLeftButton_shuxing) ~= nAllNum ) then  
		TitleText = Agname_ListContent1:AddItemElement("AgnameText","LEFT","Agname","","")	
	else 
		TitleText = g_nTitleLeftButton_shuxing[i]
	end

	TitleText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	if bHaveTitle == 0 then 
		TitleText:AddTextTextAndImage("#c959595"..nText,g_TitleListImage,g_TitleListImageSet)--g_TitleListImageSet显示空图片
	else --yongyou称号
		if CurStatus == enum_Cur then
			TitleText:AddTextTextAndImage(nText,g_TitleListTextImage,g_TitleListTextImageSet)
			TitleText:SetImageTips("#{CHYH_180523_18}")
		elseif  CurStatus == enum_Shuxing then
			TitleText:AddTextTextAndImage(nText,g_TitleListTextImage_shuxing,g_TitleListTextImageSet_shuxing)	
			TitleText:SetImageTips("#{CHYH_180523_5}")
		elseif CurStatus == enum_Double then
			TitleText:AddTextTextAndImage(nText,g_TitleListTextImage_shuangxian,g_TitleListTextImageSet_shuangxian)
			TitleText:SetImageTips("#{CHYH_180523_58}")
		else
			TitleText:AddTextTextAndImage(nText,g_TitleListImage,g_TitleListImageSet)		
		end
	
	end
	if g_nTableIndex == 0 and table.getn(g_nTitleLeftButton_shuxing) ~= nAllNum  then  	
		table.insert(g_nTitleLeftButton_shuxing,TitleText)
		
	end
	
end
--阅历列表
--拥有称号增加子类型控件
function Agname_YueLiAddText(nText,bHaveTitle,i,CurStatus)
	local nAllNum = g_AgnameAllCnt;
	local TitleText
	if g_nTableIndex == 2 and table.getn(g_nTitleLeftButton_Yueli) ~= nAllNum   then  	
		TitleText = Agname_YueliAgname:AddItemElement("AgnameText","LEFT","Agname","","")
	else
		TitleText = g_nTitleLeftButton_Yueli[i]
	end
	TitleText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	if bHaveTitle == 0 then 
		TitleText:AddTextTextAndImage("#c959595"..nText,g_TitleListImage,g_TitleListImageSet)--g_TitleListImageSet显示空图片
	else --yongyou称号
		if CurStatus == enum_Cur then
			TitleText:AddTextTextAndImage(nText,g_TitleListImage,g_TitleListImageSet)
		elseif  CurStatus == enum_Shuxing then
			TitleText:AddTextTextAndImage(nText,g_TitleListImage,g_TitleListImageSet)	
		elseif CurStatus == enum_Double then
			TitleText:AddTextTextAndImage(nText,g_TitleListImage,g_TitleListImageSet)
		else
			TitleText:AddTextTextAndImage(nText,g_TitleListImage,g_TitleListImageSet)		
		end
	end

	if g_nTableIndex == 2 and table.getn(g_nTitleLeftButton_Yueli) ~= nAllNum   then  	
		table.insert(g_nTitleLeftButton_Yueli,TitleText)
		
	end
end


function AgnameFrame_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	
	if g_nTableIndex ~= 2 then
		g_nCurSelectAllTileListIndex = CurClickIndex + 1
		Agname_Frame_SetLeftButtonSelected(g_nCurSelectAllTileListIndex)		--设置选中的类型高亮			
		Agname_ShowIcon(g_nCurSelectAllTileListIndex)
	else
		g_nCurSelectListIndex = CurClickIndex + 1
		Agname_Frame_SetLeftButtonSelected(g_nCurSelectListIndex)		--设置选中的类型高亮			
		Agname_ShowIcon(g_nCurSelectListIndex)
	end

	return
	
end

--设置选中的类型高亮
function Agname_Frame_SetLeftButtonSelected(nIndex)
	if nIndex <= 0 then return end
	if g_nTableIndex == 1 then	--所有称号
		for BtnIndex = 1,table.getn(g_nTitleLeftButton) do
			if nil ~= g_nTitleLeftButton[BtnIndex] then
				local nTitleype,nGetHave,nID,nNum,nType,szString,effect,effect_Odd = Lua_GetTitleListElementByIndex(BtnIndex)
				if nID > -1 then	--如果是二级目录
					if nIndex == BtnIndex then
						g_nTitleLeftButton[BtnIndex]:SetTextCatalogSelected(true)
						g_nTitleLeftButton[BtnIndex]:Show()

					else
						g_nTitleLeftButton[BtnIndex]:SetTextCatalogSelected(false)
						g_nTitleLeftButton[BtnIndex]:Show()
		
					end
				end
			end
		end

		Agname_ListContent:Flash()
	elseif g_nTableIndex == 0 then --属性称号
		for BtnIndex = 1,table.getn(g_nTitleLeftButton_shuxing) do
			if  nil ~= g_nTitleLeftButton_shuxing[BtnIndex] then
				local nTitleype,nGetHave,nID,nNum,nType,szString,effect,effect_Odd = Lua_GetTitleListElementByIndex(BtnIndex)
				if nID > -1 then	--如果是二级目录
					if nIndex == BtnIndex then
						g_nTitleLeftButton_shuxing[BtnIndex]:SetTextCatalogSelected(true)
						g_nTitleLeftButton_shuxing[BtnIndex]:Show()

					else
						g_nTitleLeftButton_shuxing[BtnIndex]:SetTextCatalogSelected(false)
						g_nTitleLeftButton_shuxing[BtnIndex]:Show()
		
					end
				end
			end
		end


		Agname_ListContent1:Flash()
	elseif g_nTableIndex == 2 then --阅历称号
		for BtnIndex = 1,table.getn(g_nTitleLeftButton_Yueli) do
			if nil ~= g_nTitleLeftButton_Yueli[BtnIndex] then
				local nTitleype,nGetHave,nID,nNum,nType,szString,effect,effect_Odd = Lua_GetTitleListElementByIndex(BtnIndex)
				if nID > -1 then	--如果是二级目录
					if nIndex == BtnIndex then
						g_nTitleLeftButton_Yueli[BtnIndex]:SetTextCatalogSelected(true)
						g_nTitleLeftButton_Yueli[BtnIndex]:Show()

					else
						g_nTitleLeftButton_Yueli[BtnIndex]:SetTextCatalogSelected(false)
						g_nTitleLeftButton_Yueli[BtnIndex]:Show()

					end
				end
			end
		end

		Agname_ListContent:Flash()	
	end
end



--显示图标
function Agname_ShowIcon(nIndex )

	if nIndex <= 0 then 
		return 
	end	
	
	local nTitleype,nGetHave,nID,nNum,nType,szString,effect,effect_Odd = Lua_GetTitleListElementByIndex(nIndex)

	----------阅历------------
	if g_nTableIndex == 2 then
		
		local nOldPoint = 0
		local eOldffect = ""
		local nValue = Player:GetCurAgYueLi();
		local nScriptYueLi = ScriptGlobal_Format("#{CHYH_180523_29}",nValue)	
		Agname_Currently_Title7:SetText(nScriptYueLi)
		
		local nNum = Player:GetYueliNum();
		local nValue = Player:GetCurAgYueLi();
		local i;
		g_Agname_YueLi_Name_EffNum = 1
		for i=0, nNum-1 do
			local bNeedShow = Player:IsNeedShowYueLiAttr(i);
			if bNeedShow ~= 1 then
				continue
			end
			local nPoint, effect = Player:GetYueliItem(i);
			g_Agname_YueLi_Index[g_Agname_YueLi_Name_EffNum] = nPoint
			g_Agname_YueLi_Name[g_Agname_YueLi_Name_EffNum] = effect
			g_Agname_YueLi_Name_EffNum = g_Agname_YueLi_Name_EffNum + 1
		end
		for i=0, nNum-1 do
			local bNeedShow = Player:IsNeedShowYueLiAttr(i);
			if bNeedShow ~= 1 then
				continue ;
			end
			local nPoint, effect = Player:GetYueliItem(i);

			if nValue < nPoint then
				g_Agname_YueLi_curEffIndex = i + 1
				break
			end
			nOldPoint = nPoint
			eOldffect = effect
		end
		
		Agname_Yueli1_1:SetText(eOldffect)
		if g_Agname_YueLi_Name[g_Agname_YueLi_curEffIndex] then
			Agname_Yueli2_1:SetText(g_Agname_YueLi_Name[g_Agname_YueLi_curEffIndex] )
		end
		
		if g_Agname_YueLi_Index[g_Agname_YueLi_curEffIndex] then
			local str = ScriptGlobal_Format("#{CHYH_180523_46}",g_Agname_YueLi_Index[g_Agname_YueLi_curEffIndex])	
			Agname_Currently_Title9:SetText(str)
		end
		
		local nyueli
		local szterm
		if nGetHave == 1 then
			nyueli = Player:EnumAllTitles(nID, "yueli","Ignore");
			szterm = Player:EnumAllTitles(nID, "term","Ignore");
		else
			nyueli = Player:EnumAllTitles(nID, "yueli","");
			szterm = Player:EnumAllTitles(nID, "term","");
		end
		
		sz_yueli = ScriptGlobal_Format("#{CHYH_180523_26}",nyueli)	
		Agname_Info2_Title:SetText(sz_yueli)
		

		Agname_Info2_Title3:SetText(szterm)
		
	end
	----------阅历------------
	
	
	
	if g_nTableIndex == 2 then
		Agname_Xianshishuxingchenghao:SetProperty("Visible" , "False" )
		Agname_Shuxingchenghaoxianshi:SetProperty("Visible" , "False" )
		Agname_Shuxingchenghaoxianshi_Text:SetProperty("Visible" , "False" )
	else
		Agname_Xianshishuxingchenghao:SetProperty("Visible" , "True" )
		Agname_Shuxingchenghaoxianshi:SetProperty("Visible" , "True" )
		Agname_Shuxingchenghaoxianshi_Text:SetProperty("Visible" , "True" )
	end

	--称号显示
	local nTiTleShowType 
	local nTiTleName  = szString

	local nTiTleBoardType
	local nShowType  
	local nTitleype 
	local StrColorName
	
	local nAnimateID 
	local nDesc 
	local szterm 
	local nYueli 
	local nTime 

	local nDay 
	local nTimeDay

	if 1 == nGetHave then
		nTiTleShowType = Player:EnumAllTitles(nID, "Anim","Ignore");
		nTiTleBoardType = Player:EnumAllTitles(nID, "BoardType","Ignore");
		nShowType = Player:EnumAllTitles(nID, "nShowType","Ignore");
		nTitleype = Player:EnumAllTitles(nID, "nLogicTpye","Ignore");

		StrColorName = Player : GetSystemColorText(nShowType,nTitleype,nTiTleName);
		
		Agname_PlayerTitle:SetText(StrColorName)
		nAnimateID = Player:EnumAllTitles(nID, "IDAnim","Ignore");
		nDesc = Player:EnumAllTitles(nID, "desc","Ignore");
		szterm = Player:EnumAllTitles(nID, "term","Ignore");
		nYueli = Player:EnumAllTitles(nID, "yueli","Ignore");
		nTime = Player:EnumAllTitles(nID, "nTime","Ignore");		
	else
		nTiTleShowType = Player:EnumAllTitles(nID, "Anim","");
		nTiTleBoardType = Player:EnumAllTitles(nID, "BoardType","");
		nShowType = Player:EnumAllTitles(nID, "nShowType","");
		nTitleype = Player:EnumAllTitles(nID, "nLogicTpye","");

		StrColorName = Player : GetSystemColorText(nShowType,nTitleype,nTiTleName);
		Agname_PlayerTitle:SetText(StrColorName)
		nAnimateID = Player:EnumAllTitles(nID, "IDAnim","");
		nDesc = Player:EnumAllTitles(nID, "desc","");
		szterm = Player:EnumAllTitles(nID, "term","");
		nYueli = Player:EnumAllTitles(nID, "yueli","");
		nTime = Player:EnumAllTitles(nID, "nTime","");	
	end


	nDay = math.floor(nTime / 24)
	nTimeDay = ScriptGlobal_Format("#{CHYH_180523_20}",nDay)	
	Agname_Chenhaoshuxing_Text3:SetText("")

	
	local nPosY = tonumber(Agname_PlayerTitle:GetProperty("AbsoluteHeight"))
	local nPosX = tonumber(Agname_PlayerTitle:GetProperty("AbsoluteWidth"))
	
	local FramH = tonumber(Agname_Prize_Image:GetProperty("AbsoluteHeight"))
	local FramW = tonumber(Agname_Prize_Image:GetProperty("AbsoluteWidth"))	

	
	local fX = 0
	local fY = 0
	
	--MyselfTitle
	fX = math.floor(tonumber(FramW/2 - nPosX/2 ))	
	fY = math.floor(tonumber(fY  )	)


	Agname_PlayerTitle:SetProperty("AbsoluteXPosition", fX);	
	Agname_PlayerTitle:SetProperty("AbsoluteYPosition", fY+20);
	
	Agname_LeftTitleAnimate:Hide()
	Agname_RightTitleAnimate:Hide()
	Agname_TopTitleAnimate:Hide()
	Agname_PlayerTitle:Show()
	
	if nTiTleShowType == 0 then 	
		if nTiTleBoardType > 0 then 

			Agname_LeftTitleAnimate:Show()
			Agname_RightTitleAnimate:Show()

			local Leftname = Player:EnumBoardType(nTiTleBoardType, "strLeftName");
			local Rightname = Player:EnumBoardType(nTiTleBoardType, "strRightName");
			
			local LeftSizeX = Player:EnumBoardType(nTiTleBoardType, "LeftSizeX");
			local LeftSizeY = Player:EnumBoardType(nTiTleBoardType, "LeftSizeY");
			local RightSizeX = Player:EnumBoardType(nTiTleBoardType, "RightSizeX");
			local RightSizeY = Player:EnumBoardType(nTiTleBoardType, "RightSizeY");
			
			Agname_LeftTitleAnimate:SetProperty("AbsoluteSize", "w:"..LeftSizeX.." ".."h:"..LeftSizeY)
			Agname_RightTitleAnimate:SetProperty("AbsoluteSize", "w:"..RightSizeX.." ".."h:"..RightSizeY)
			Agname_LeftTitleAnimate:SetProperty("Animate", Leftname)
			Agname_RightTitleAnimate:SetProperty("Animate", Rightname)
	
			local LeftOffsetX = Player:EnumBoardType(nTiTleBoardType, "LeftOffsetX");
			local LeftOffsetY = Player:EnumBoardType(nTiTleBoardType, "LeftOffsetY");
			local RightOffsetX = Player:EnumBoardType(nTiTleBoardType, "RightOffsetX");
			local RightOffsetY = Player:EnumBoardType(nTiTleBoardType, "RightOffsetY");

			nPosX = tonumber(Agname_PlayerTitle:GetProperty("AbsoluteXPosition"))
			nPosY = tonumber(Agname_PlayerTitle:GetProperty("AbsoluteYPosition"))
			local nHeight = tonumber(Agname_PlayerTitle:GetProperty("AbsoluteHeight"))
			local nWidth = tonumber(Agname_PlayerTitle:GetProperty("AbsoluteWidth"))
			
			--Left
			fX = 0
			fY = 0
			fX = math.floor(tonumber(fX + nPosX - LeftOffsetX ))
			fY = math.floor(tonumber(fY + nPosY + nHeight - LeftOffsetY))
			Agname_LeftTitleAnimate:SetProperty("AbsoluteXPosition", fX);	
			Agname_LeftTitleAnimate:SetProperty("AbsoluteYPosition", fY);

			--Right
			fX = 0
			fY = 0
			fX = math.floor(tonumber(fX + nPosX + nWidth - RightOffsetX ))
			fY = math.floor(tonumber(fY + nPosY + nHeight - RightOffsetY))
			Agname_RightTitleAnimate:SetProperty("AbsoluteXPosition", fX);	
			Agname_RightTitleAnimate:SetProperty("AbsoluteYPosition", fY);
			
			Agname_LeftTitleAnimate:Show()
			Agname_RightTitleAnimate:Show()
		end
	end
	
	if nTiTleShowType == 1 then 
		--Animate
		Agname_TopTitleAnimate:Show()
		Agname_TopTitleAnimate:SetProperty( "Animate", szName );
		
		local SizeX = Player:EnumFlashType(nAnimateID, "SizeX");
		local SizeY = Player:EnumFlashType(nAnimateID, "SizeY");		
		local szName = Player:EnumFlashType(nAnimateID, "name");		
		
		Agname_TopTitleAnimate:SetProperty("AbsoluteSize", "w:"..SizeX.." ".."h:"..SizeY)

		fH = tonumber(Agname_TopTitleAnimate:GetProperty("AbsoluteHeight"))
		fW = tonumber(Agname_TopTitleAnimate:GetProperty("AbsoluteWidth"))	

	    FramW = tonumber(Agname_PlayerTitle:GetProperty("AbsoluteWidth"))
		nPosX = tonumber(Agname_PlayerTitle:GetProperty("AbsoluteXPosition"))
		nPosY = tonumber(Agname_PlayerTitle:GetProperty("AbsoluteYPosition"))

		fX = math.floor(tonumber( nPosX + (FramW  * 0.5) - (fW * 0.5)))	
		fY = math.floor(tonumber(nPosY - fH/4 )+10)

		Agname_TopTitleAnimate:SetProperty("AbsoluteXPosition", fX);	
		Agname_TopTitleAnimate:SetProperty("AbsoluteYPosition", fY);

		Agname_TopTitleAnimate:SetProperty( "Animate", szName );


		Agname_PlayerTitle:Hide()
				
	end
	

	if g_nTableIndex == 0 then

		local curEffect = g_Agname_EffTbl_Str[nIndex]
		local curEffect_Odd = g_Agname_EffTbl_Str_Odd[nIndex]
		

		--选择称号属性界面

		if curEffect ~= "" then
			local str  = ""

			
			if nGetHave == 0 then
				str = ScriptGlobal_Format("#{CHXTY_130825_8}", nTiTleName)
				Agname_Chenhaoshuxing_Text3:SetText(str)
			end
			Agname_Chenhaoshuxing_Text:SetText(curEffect)
			Agname_Chenhaoshuxing_Text1:SetText(curEffect_Odd)
			Agname_Chenhaoshuxing_Text2:SetText("")

		else
			
			Agname_Chenhaoshuxing_Text:SetText("")
			Agname_Chenhaoshuxing_Text1:SetText("")
			Agname_Chenhaoshuxing_Text2:SetText("#{CHYH_180523_57}")
		end
		
		local nYMDH = -1
		local nYMDH = -1
		if nTime == -1 then --如果是永久的 直接显示
			--Agname_Info1_Yueli:SetText("#{CHYH_180523_39}"..str)
			Agname_Info1_Youxiaoqi:SetText( "#{CHYH_180523_41}")
		elseif nTime > -1 then--如果不是永久的 需要算下时间再在Agname_Info1_Youxiaoqi控件上显示
			Agname_Info1_Youxiaoqi:SetText(nTimeDay)
		end
		if nTime == -1 and nGetHave ==  1 then --如果是永久的 直接显示
			Agname_Info1_Youxiaoqi1:SetText("")
		elseif nTime > -1 and nGetHave == 1  then--如果不是永久的 需要算下时间再在Agname_Info1_Youxiaoqi1控件上显示
				nYMDH = Player:AgnameChangeTime(nID)
				Agname_Info1_Youxiaoqi1:SetText(nYMDH)
		elseif nTime == -1 and nGetHave ==  0 then --如果是永久的 但是没有该称号 则显示
			Agname_Info1_Youxiaoqi1:SetText("#{CHYH_180523_43}")
		end

		local str = ScriptGlobal_Format("#{CHYH_180523_40}", nYueli)	
		Agname_Info1_Yueli:SetText("#{CHYH_180523_39}"..str)
		
		Agname_FinishCondition:SetText(nDesc)
		Agname_Dachengtiaojian:SetText(szterm)
		
		local str = ScriptGlobal_Format("#{CHYH_180523_40}", nYueli)	

		if nGetHave == 1 then --拥有该称号
			if curEffect ~= "" then --拥有属性
				if nIndex == g_Agname_curEffIndex then --当前选中的 就是已经点选的属性 那么将点选钩起来
						Agname_Shuxingshiyong:SetText("#{CHYH_180523_55}")
						Agname_Shuxingshiyong:Disable()
						Agname_Shuxingshiyong:SetToolTip("#{CHYH_180523_48}")
				else
						Agname_Shuxingshiyong:SetText("#{CHYH_180523_13}")			
						Agname_Shuxingshiyong:Enable()
						
				end		
			else --不让勾选
					Agname_Shuxingshiyong:SetText("#{CHYH_180523_57}")
					Agname_Shuxingshiyong:Disable()				
			end
			Agname_Yulanxianshi:Enable()
			
			if nIndex == g_Agname_curIndex then --当前选中的 就是已经使用的称号 那么将点选勾选起来
				Agname_Yulanxianshi:SetText("#{CHYH_180523_56}")
				g_TitleButtonFlag = 0
			else
				Agname_Yulanxianshi:SetText("#{CHYH_180523_8}")
				g_TitleButtonFlag = 1 
			end
			
		else --没有称号 不让勾选
		
			if curEffect ~= "" then --拥有属性
				Agname_Shuxingshiyong:SetText("#{CHYH_180523_13}")
			else
				Agname_Shuxingshiyong:SetText("#{CHYH_180523_57}")		
			end
			Agname_Shuxingshiyong:Disable()	
				
			Agname_Yulanxianshi:SetText("#{CHYH_180523_8}")
			Agname_Yulanxianshi:Disable()	

		end
		
	end

	if g_nTableIndex == 1 then
	
		--当前显示称号
		local curAgname = Player:GetCurrentAgname()
		--当前虚拟称号
		local curVirtualAgname = Player:GetCurrentVirtualAgname()

		local curEffect = g_Agname_EffTbl_Str[nIndex]
		local curEffect_Odd = g_Agname_EffTbl_Str_Odd[nIndex]
		
		--选择称号属性界面
		if curEffect ~= "" then
			local str  = ""

			Agname_Chenhaoshuxing_Text3:SetText("")
			if nGetHave == 0 then
				str = ScriptGlobal_Format("#{CHXTY_130825_8}", nTiTleName)
				
				curEffect =  curEffect
				Agname_Chenhaoshuxing_Text3:SetText(str)
			end
			
			Agname_Chenhaoshuxing_Text:SetText(curEffect)
			Agname_Chenhaoshuxing_Text1:SetText(curEffect_Odd)
			Agname_Chenhaoshuxing_Text2:SetText("")

		else
			
			Agname_Chenhaoshuxing_Text:SetText("")
			Agname_Chenhaoshuxing_Text1:SetText("")
			Agname_Chenhaoshuxing_Text2:SetText("#{CHYH_180523_57}")
		end

		local nYMDH = -1
	
		local nYMDH = -1
		if nTime == -1 then --如果是永久的 直接显示
			Agname_Info1_Youxiaoqi:SetText("#{CHYH_180523_41}")
		elseif nTime > -1 then--如果不是永久的 需要算下时间再在Agname_Info1_Youxiaoqi控件上显示			
			Agname_Info1_Youxiaoqi:SetText(nTimeDay)
		end
		if nTime == -1 and nGetHave ==  1 then --如果是永久的 直接显示
			Agname_Info1_Youxiaoqi1:SetText("")
		elseif nTime > -1 and nGetHave == 1  then--如果不是永久的 需要算下时间再在Agname_Info1_Youxiaoqi1控件上显示
			if nGetHave == 1 then
				nYMDH = Player:AgnameChangeTime(nID)
				Agname_Info1_Youxiaoqi1:SetText(nYMDH)
			end
		elseif nGetHave ==  0 then --如果是永久的 但是没有该称号 则显示
			Agname_Info1_Youxiaoqi1:SetText("#{CHYH_180523_43}")
		end

		Agname_FinishCondition:SetText(nDesc)
		Agname_Dachengtiaojian:SetText(szterm)
		local str = ScriptGlobal_Format("#{CHYH_180523_40}", nYueli)	
		Agname_Info1_Yueli:SetText("#{CHYH_180523_39}"..str)

		
		if nGetHave == 1 then --拥有该称号
			if curEffect ~= "" then --拥有属性
				if nIndex == g_Agname_curEffIndex then --当前选中的 就是已经点选的属性 那么将点选钩起来
					Agname_Shuxingshiyong:SetText("#{CHYH_180523_55}")
					Agname_Shuxingshiyong:SetToolTip("#{CHYH_180523_48}")
					Agname_Shuxingshiyong:Disable()
				else
					Agname_Shuxingshiyong:SetText("#{CHYH_180523_13}")			
					Agname_Shuxingshiyong:Enable()
				end		
			else --不让勾选
				Agname_Shuxingshiyong:SetText("#{CHYH_180523_57}")
				Agname_Shuxingshiyong:Disable()				
			end
			Agname_Yulanxianshi:Enable()

			if nIndex == g_Agname_curIndex then --当前选中的 就是已经使用的称号 那么将点选勾选起来
				Agname_Yulanxianshi:SetText("#{CHYH_180523_56}")
				g_TitleButtonFlag = 0
			else
				
				Agname_Yulanxianshi:SetText("#{CHYH_180523_8}")
				g_TitleButtonFlag = 1
			end
			
		else --没有称号 不让勾选
		
			if curEffect ~= "" then --拥有属性
				Agname_Shuxingshiyong:SetText("#{CHYH_180523_13}")
			else
				Agname_Shuxingshiyong:SetText("#{CHYH_180523_57}")		
			end

			Agname_Shuxingshiyong:Disable()	
			
			Agname_Yulanxianshi:SetText("#{CHYH_180523_8}")
			Agname_Yulanxianshi:Disable()	

		end
		
	end

end


function Agname_Effect_SetCheck(  )
	
	--当前属性id和要更改的id是否一样
	if g_nCurSelectAllTileListIndex  < 0 then
		return
	end
	local nTitleype,nGetHave,nID,nNum,nType,szString,effect,effect_Odd = Lua_GetTitleListElementByIndex(g_nCurSelectAllTileListIndex)
	local nName = szString
	local selectId = Agname_GetOwnerAgnameEffectIndex(nName)
	if selectId < 0 then 
		return 
	end

	if g_nCurSelectAllTileListIndex == g_Agname_curEffIndex then --这个已经更改过一次了
		return 
	end
	

	local nGetHave = Player:HaveTitle(nID);

	if 	nGetHave == 0 then
		return 
	end
	
	--取消当前处于生效状态属性 更替所选属性
	Player:AskChangeCurrentEffect(selectId); --待补充
	g_Agname_curEffIndex = g_nCurSelectAllTileListIndex
	Agname_Shuxingshiyong:SetText("已使用")
	Agname_Shuxingshiyong:Disable()
	Agname_Shuxingshiyong:SetToolTip("#{CHYH_180523_48}")
	PushDebugMessage("#{CHYH_180523_52}")

end
function Agname_GetOwnerAgnameEffectIndex(name)
	for i = 1,table.getn(g_Agname_Owner_EffTbl_Index) do
		
		if name == g_Agname_Owner_EffTbl_Name[i] then
			return g_Agname_Owner_EffTbl_Index[i]
		end
	end
	return -1
end	
function Agname_GetHaveGetAgnameIndex(name)
	for i = 1,table.getn(g_Agname_HAVEGET_Index) do
		if name == g_Agname_HAVEGET_Name[i] then
			return g_Agname_HAVEGET_Index[i]
		end
	end
	return -1
end	


function Agname_SetCheck( )
	
	local curSceneID = GetSceneID(); --
	
	if curSceneID == 868 then --zypvp
		return 
	end
	if curSceneID == 1008 then --
		return 
	end
	local nCheck = g_TitleButtonFlag

	if nCheck == 1 then
		--当前使用称号id和要更改的id是否一样
		if g_nCurSelectAllTileListIndex  <= 0 then
			--PushDebugMessage("111111")
			return
		end
		local nTitleype,nGetHave,nID,nNum,nType,szString,effect,effect_Odd = Lua_GetTitleListElementByIndex(g_nCurSelectAllTileListIndex)
		local nName = szString
		local selectId = Agname_GetHaveGetAgnameIndex(nName)
		if selectId < 0 then 
			return 
		end
		
	
		if 	nGetHave == 0 then
			return 
		end
		
		--取消当前处于生效状态属性 更替所选属性
		Player:AskChangeCurrentAgname(selectId); --待补充
		g_Agname_curIndex = g_nCurSelectAllTileListIndex

		PushDebugMessage("#{CHYH_180523_51}")
		Agname_Yulanxianshi:SetText("隐藏")	
	
		g_TitleButtonFlag = 0
	else
		Agname_Yulanxianshi:SetText("显示")	
		Player:SetNullAgname();
		g_Agname_curIndex = -1	
		g_TitleButtonFlag = 1
	end
	
end


function Agname_OnlyShowEffect_SetCheck(  )
	
	local nCheck = Agname_Shuxingchenghaoxianshi:GetCheck()
	g_nCurSelectAllTileListIndex  = 1
	if nCheck == 1 then
		Agname_ListContent:Hide()
		Agname_ListContent_Lace:Hide()
		Agname_ListContent1:Show()
		Agname_ListContent_Lace1:Show()
		g_nTableIndex = 0
		
		Agname_Shuxingchenghaoxianshi:SetCheck(1)	
	else
		Agname_ListContent:Show()
		Agname_ListContent_Lace:Show()
		Agname_ListContent1:Hide()
		Agname_ListContent_Lace1:Hide()
		Agname_Shuxingchenghaoxianshi:SetCheck(0)	
		g_nTableIndex = 1
	end
	
	Agname_LeftLoad()
	Agname_Frame_SetLeftButtonSelected(g_nCurSelectAllTileListIndex)
	Agname_ShowIcon(g_nCurSelectAllTileListIndex)
end

function Agname_OnChoice(index)


	if g_nTableIndex == index then
		return 
	end

	if g_nTableIndex == 1 and table.getn(g_nTitleLeftButton) ~= g_AgnameAllCnt   then  
		g_nTitleLeftButton = {}
	end
	if g_nTableIndex == 0 and table.getn(g_nTitleLeftButton_shuxing) ~= g_AgnameAllCnt   then  	
		g_nTitleLeftButton_shuxing = {}
	end

	if g_nTableIndex == 2 and table.getn(g_nTitleLeftButton_Yueli) ~= g_AgnameAllCnt   then  	
		g_nTitleLeftButton_Yueli = {}
	end
	



	g_nTableIndex = index
	if g_nTableIndex == 1 then
		nCheck = Agname_Shuxingchenghaoxianshi:GetCheck()
		g_nTableIndex = nCheck
	end
	
	if g_nTableIndex == 0 or g_nTableIndex == 1  then
		Agname_Chenghao:SetCheck(1)
		Agname_Yueli:SetCheck(0)
	else 
		Agname_Chenghao:SetCheck(0)
		Agname_Yueli:SetCheck(1)
	end
	
	if g_nTableIndex == 0 or g_nTableIndex == 1 then
		Agname_Frame_FenYeWindow1:SetProperty("Visible" , "True" )
		Agname_Frame_FenYeWindow2:SetProperty("Visible" , "False" )
	else
		Agname_Frame_FenYeWindow1:SetProperty("Visible" , "False" )
		Agname_Frame_FenYeWindow2:SetProperty("Visible" , "True" )	
	end

	
	Agname_LeftLoad()

	if g_nTableIndex == 2 then
		Agname_Frame_SetLeftButtonSelected(g_nCurSelectListIndex)		--设置选中的类型高亮
		Agname_ShowIcon(g_nCurSelectListIndex)

		
	else
    	Agname_Frame_SetLeftButtonSelected(g_nCurSelectAllTileListIndex)		--设置选中的类型高亮
		Agname_ShowIcon(g_nCurSelectAllTileListIndex)
	end


	
	this:Show()	

end

function Agname_PageDown()

	if g_Agname_YueLi_curEffIndex > 1 then
		g_Agname_YueLi_curEffIndex = g_Agname_YueLi_curEffIndex - 1
	else
		return 
	end
	
	if g_Agname_YueLi_Name[g_Agname_YueLi_curEffIndex] then
		Agname_Yueli2_1:SetText(g_Agname_YueLi_Name[g_Agname_YueLi_curEffIndex] )
	end
		
	if g_Agname_YueLi_Index[g_Agname_YueLi_curEffIndex] then
		local str = ScriptGlobal_Format("#{CHYH_180523_46}",g_Agname_YueLi_Index[g_Agname_YueLi_curEffIndex])	
		Agname_Currently_Title9:SetText(str)
	end


end

function Agname_PageUp()

		
	if g_Agname_YueLi_curEffIndex < g_Agname_YueLi_Name_EffNum -1 then
		g_Agname_YueLi_curEffIndex = g_Agname_YueLi_curEffIndex + 1
	else
		return 
	end
	
	if g_Agname_YueLi_Name[g_Agname_YueLi_curEffIndex] then
		Agname_Yueli2_1:SetText(g_Agname_YueLi_Name[g_Agname_YueLi_curEffIndex] )
	end
		
	if g_Agname_YueLi_Index[g_Agname_YueLi_curEffIndex] then
		local str = ScriptGlobal_Format("#{CHYH_180523_46}",g_Agname_YueLi_Index[g_Agname_YueLi_curEffIndex])	
		Agname_Currently_Title9:SetText(str)
	end

end


function Agname_Button_WaiGuanEffect(Index)
	
	if Index == 1 and g_nTableIndex == 1  then   --所有称号
		if g_Agname_curIndex == -1 then
			PushDebugMessage("#{CHYH_180523_37}")
			return 0
		end
		
		Agname_Frame_SetLeftButtonSelected(g_Agname_curIndex)
		Agname_ShowIcon(g_Agname_curIndex)
	elseif Index == 1 and g_nTableIndex == 2  then   --所有称号

	elseif Index == 0 then --有属性的称号
		if g_Agname_curEffIndex == -1 then
			PushDebugMessage("#{CHYH_180523_38}")
			return 0
		end
		Agname_Frame_SetLeftButtonSelected(g_Agname_curEffIndex)
		Agname_ShowIcon(g_Agname_curEffIndex)
	elseif Index == 2 then --阅历称号
	
	end

end
