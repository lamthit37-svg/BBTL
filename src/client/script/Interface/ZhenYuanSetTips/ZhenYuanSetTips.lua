--*********************
--真元盘Tips
--*********************

local ZhenYuanSetTips_Text_Type=
{
	"#{ZYYH_120824_17}",	--体力
	"#{ZYYH_120824_18}",	--血上限
	"#{ZYYH_120824_19}",	--命中
	"#{ZYYH_120824_20}",	--闪避
	"#{ZYYH_120824_21}",	--所有属性攻
	"#{ZYYH_120824_22}",	--所有属性
}

local ZhenYuanSetTips_Text_Qua=
{
	"#{ZYYH_120824_01}",	--#cfff263已放入6枚真元且最低品质为白色。
	"#{ZYYH_120824_02}",	--#cfff263已放入6枚真元且最低品质为绿色。
	"#{ZYYH_120824_03}",	--#cfff263已放入6枚真元且最低品质为蓝色。
	"#{ZYYH_120824_04}",	--#cfff263已放入6枚真元且最低品质为紫色。
	"#{ZYYH_120824_05}",	--#cfff263已放入6枚真元且最低品质为橙色。
}

local ZhenYuanSetTips_Text_Satisfy=
{
	"#{ZYYH_120824_06}",	--#G（满足）
	"#{ZYYH_120824_07}",	--#cff0000（未满足）
}

local ZhenYuanSetTips_Text_Color=
{
	"#G",								--已激活
	"#ccccccc",						--未激活
}

local ZhenYuanSetTips_TxtTop={}
local ZhenYuanSetTips_TxtBottom={}

function ZhenYuanSetTips_PreLoad()
	this:RegisterEvent("ZHENYUAN_SET_MOUSEENTER");
	this:RegisterEvent("ZHENYUAN_SET_MOUSELEAVE");
end

function ZhenYuanSetTips_OnLoad()
	ZhenYuanSetTips_TxtTop=
	{
		{ZhenYuanSetTips_Up_TXT11,ZhenYuanSetTips_Up_TXT12,ZhenYuanSetTips_Up_TXT13},
		{ZhenYuanSetTips_Up_TXT21,ZhenYuanSetTips_Up_TXT22,ZhenYuanSetTips_Up_TXT23},
		{ZhenYuanSetTips_Up_TXT31,ZhenYuanSetTips_Up_TXT32,ZhenYuanSetTips_Up_TXT33},
		{ZhenYuanSetTips_Up_TXT41,ZhenYuanSetTips_Up_TXT42,ZhenYuanSetTips_Up_TXT43},
		{ZhenYuanSetTips_Up_TXT51,ZhenYuanSetTips_Up_TXT52,ZhenYuanSetTips_Up_TXT53},
	}
	
	ZhenYuanSetTips_TxtBottom=
	{
		{ZhenYuanSetTips_Down_TXT11, ZhenYuanSetTips_Down_TXT12, ZhenYuanSetTips_Down_TXT13},
		{ZhenYuanSetTips_Down_TXT21, ZhenYuanSetTips_Down_TXT22, ZhenYuanSetTips_Down_TXT23},
		{ZhenYuanSetTips_Down_TXT31, ZhenYuanSetTips_Down_TXT32, ZhenYuanSetTips_Down_TXT33},
		{ZhenYuanSetTips_Down_TXT41, ZhenYuanSetTips_Down_TXT42, ZhenYuanSetTips_Down_TXT43},
		{ZhenYuanSetTips_Down_TXT51, ZhenYuanSetTips_Down_TXT52, ZhenYuanSetTips_Down_TXT53},
	}
end

function ZhenYuanSetTips_OnEvent(event)
	local minlvl = tonumber(arg0)				--最低等级
	local minqua = tonumber(arg1)			--最低品质
	local TabIndex = tonumber(arg2)		--标签页ID
	local SetX = tonumber(arg3)				--真圆盘坐标
	local SetY = tonumber(arg4)
	local SetWidth = tonumber(arg5)		--真圆盘大小
	local SetHeight = tonumber(arg6)
	
	if( event == "ZHENYUAN_SET_MOUSEENTER" ) then
		local nType={}
		local nValue={}
		
		if(minqua == 0) then
			nType[1], nValue[1],nType[2], nValue[2],nType[3], nValue[3],nType[4], nValue[4],nType[5], nValue[5],nType[6], nValue[6],nType[7], nValue[7],nType[8], nValue[8],nType[9], nValue[9] = Pneuma:GetPneumaSet( TabIndex,3)
			ZhenYuanSetTips_TXT_Up:SetText(ZhenYuanSetTips_Text_Qua[3]..ZhenYuanSetTips_Text_Satisfy[2])
			
			local curIndex=1
			for i=1,9 do
				if(nType[i] ~= nil and nValue[i]~= nil and nType[i]>0 and nType[i]<7 and nValue[i]>0)  then
					ZhenYuanSetTips_TxtTop[curIndex][1]:SetText(ZhenYuanSetTips_Text_Color[2]..ZhenYuanSetTips_Text_Type[nType[i]])
					ZhenYuanSetTips_TxtTop[curIndex][2]:SetText(ZhenYuanSetTips_Text_Color[2].."+"..nValue[i])
					ZhenYuanSetTips_TxtTop[curIndex][3]:SetText(ZhenYuanSetTips_Text_Color[2]..ScriptGlobal_Format( "#{ZYYH_120824_24}", i))
					curIndex = curIndex +1
					if(curIndex>=6) then
						break
					end
				end
			end
			ZhenYuanSetTips_Frame:SetProperty("AbsoluteHeight" , "140")
			if SystemSetup:IsClassic() == 0 then
				ZhenYuanSetTips_TXT_Down:Hide()
				ZhenYuanSetTips_Frame:SetProperty("AbsoluteHeight" , "146")
			end
			ZhenYuanSetTips_AutoLocate(SetX,SetY,SetWidth,SetHeight)
			this:Show()
				
		elseif (minqua==5) then
			nType[1], nValue[1],nType[2], nValue[2],nType[3], nValue[3],nType[4], nValue[4],nType[5], nValue[5],nType[6], nValue[6],nType[7], nValue[7],nType[8], nValue[8],nType[9], nValue[9] = Pneuma:GetPneumaSet( TabIndex,5)
			ZhenYuanSetTips_TXT_Up:SetText(ZhenYuanSetTips_Text_Qua[5]..ZhenYuanSetTips_Text_Satisfy[1])
			
			local curIndex=1
			for i=1,9 do
				if(nType[i] ~= nil and nValue[i]~= nil and nType[i]>0 and nType[i]<7 and nValue[i]>0) then
					if(minlvl >= i) then
						ZhenYuanSetTips_TxtTop[curIndex][1]:SetText(ZhenYuanSetTips_Text_Color[1]..ZhenYuanSetTips_Text_Type[nType[i]])
						ZhenYuanSetTips_TxtTop[curIndex][2]:SetText(ZhenYuanSetTips_Text_Color[1].."+"..nValue[i])
						ZhenYuanSetTips_TxtTop[curIndex][3]:SetText(ZhenYuanSetTips_Text_Color[1]..ScriptGlobal_Format( "#{ZYYH_120824_24}", i))
					else
						ZhenYuanSetTips_TxtTop[curIndex][1]:SetText(ZhenYuanSetTips_Text_Color[2]..ZhenYuanSetTips_Text_Type[nType[i]])
						ZhenYuanSetTips_TxtTop[curIndex][2]:SetText(ZhenYuanSetTips_Text_Color[2].."+"..nValue[i])
						ZhenYuanSetTips_TxtTop[curIndex][3]:SetText(ZhenYuanSetTips_Text_Color[2]..ScriptGlobal_Format( "#{ZYYH_120824_24}", i))
					end
					curIndex = curIndex +1
					if(curIndex>=6) then
						break
					end
				end
			end
			ZhenYuanSetTips_Frame:SetProperty("AbsoluteHeight" , "140")
			if SystemSetup:IsClassic() == 0 then
				ZhenYuanSetTips_TXT_Down:Hide()
				ZhenYuanSetTips_Frame:SetProperty("AbsoluteHeight" , "146")
			end
			ZhenYuanSetTips_AutoLocate(SetX,SetY,SetWidth,SetHeight)
			this:Show()
				
		elseif(minqua==3 or minqua==4) then
			nType[1], nValue[1],nType[2], nValue[2],nType[3], nValue[3],nType[4], nValue[4],nType[5], nValue[5],nType[6], nValue[6],nType[7], nValue[7],nType[8], nValue[8],nType[9], nValue[9] = Pneuma:GetPneumaSet( TabIndex,minqua)
			if minqua==3 then
				ZhenYuanSetTips_TXT_Up:SetText(ZhenYuanSetTips_Text_Qua[3]..ZhenYuanSetTips_Text_Satisfy[1])
				ZhenYuanSetTips_TXT_Down:SetText(ZhenYuanSetTips_Text_Qua[4]..ZhenYuanSetTips_Text_Satisfy[2])
			else
				ZhenYuanSetTips_TXT_Up:SetText(ZhenYuanSetTips_Text_Qua[4]..ZhenYuanSetTips_Text_Satisfy[1])
				ZhenYuanSetTips_TXT_Down:SetText(ZhenYuanSetTips_Text_Qua[5]..ZhenYuanSetTips_Text_Satisfy[2])
			end
			local curIndex=1
			for i=1,9 do
				if(nType[i] ~= nil and nValue[i]~= nil and nType[i]>0 and nType[i]<7 and nValue[i]>0) then
					if(minlvl >= i) then
						ZhenYuanSetTips_TxtTop[curIndex][1]:SetText(ZhenYuanSetTips_Text_Color[1]..ZhenYuanSetTips_Text_Type[nType[i]])
						ZhenYuanSetTips_TxtTop[curIndex][2]:SetText(ZhenYuanSetTips_Text_Color[1].."+"..nValue[i])
						ZhenYuanSetTips_TxtTop[curIndex][3]:SetText(ZhenYuanSetTips_Text_Color[1]..ScriptGlobal_Format( "#{ZYYH_120824_24}", i))
					else
						ZhenYuanSetTips_TxtTop[curIndex][1]:SetText(ZhenYuanSetTips_Text_Color[2]..ZhenYuanSetTips_Text_Type[nType[i]])
						ZhenYuanSetTips_TxtTop[curIndex][2]:SetText(ZhenYuanSetTips_Text_Color[2].."+"..nValue[i])
						ZhenYuanSetTips_TxtTop[curIndex][3]:SetText(ZhenYuanSetTips_Text_Color[2]..ScriptGlobal_Format( "#{ZYYH_120824_24}", i))
					end
					curIndex = curIndex +1
					if(curIndex>=6) then
						break
					end
				end
			end	
			 nType[1], nValue[1],nType[2], nValue[2],nType[3], nValue[3],nType[4], nValue[4],nType[5], nValue[5],nType[6], nValue[6],nType[7], nValue[7],nType[8], nValue[8],nType[9], nValue[9] = Pneuma:GetPneumaSet( TabIndex,minqua+1)
			 curIndex=1
			for i=1,9 do
				if(nType[i] ~= nil and nValue[i]~= nil and nType[i]>0 and nType[i]<7 and nValue[i]>0) then
					ZhenYuanSetTips_TxtBottom[curIndex][1]:SetText(ZhenYuanSetTips_Text_Color[2]..ZhenYuanSetTips_Text_Type[nType[i]])
					ZhenYuanSetTips_TxtBottom[curIndex][2]:SetText(ZhenYuanSetTips_Text_Color[2].."+"..nValue[i])
					ZhenYuanSetTips_TxtBottom[curIndex][3]:SetText(ZhenYuanSetTips_Text_Color[2]..ScriptGlobal_Format( "#{ZYYH_120824_24}", i))
					curIndex = curIndex +1
					if(curIndex>=6) then
						break
					end
				end
			end
			ZhenYuanSetTips_Frame:SetProperty("AbsoluteHeight" , "270")
			if SystemSetup:IsClassic() == 0 then
				ZhenYuanSetTips_Frame:SetProperty("AbsoluteHeight" , "289")
			end
			ZhenYuanSetTips_AutoLocate(SetX,SetY,SetWidth,SetHeight)
			this:Show()
		else
			return
		end
		
	end
	if( event == "ZHENYUAN_SET_MOUSELEAVE" ) then
		--清空列表
		for i=1,5 do
			for j=1,3 do
				ZhenYuanSetTips_TxtTop[i][j]:SetText(" ")
			end
		end
		for i=1,5 do
			for j=1,3 do
				ZhenYuanSetTips_TxtBottom[i][j]:SetText(" ")
			end
		end
		this:Hide()
	end
end

--自动设置Tips位置
function ZhenYuanSetTips_AutoLocate(SetX,SetY,SetWidth,SetHeight)
	local TipsWidth = ZhenYuanSetTips_Frame:GetProperty("AbsoluteWidth")
	local TipsHeight = ZhenYuanSetTips_Frame:GetProperty("AbsoluteHeight")
	local ScreenWidth ,ScreenHeight = GetCurClientSize()
	if(SetX + SetWidth + TipsWidth > ScreenWidth) then
		ZhenYuanSetTips_Frame:SetProperty("AbsoluteXPosition",SetX - TipsWidth)
	else
		ZhenYuanSetTips_Frame:SetProperty("AbsoluteXPosition",SetX + SetWidth)
	end
	if(SetY + SetHeight + TipsHeight > ScreenHeight) then
		ZhenYuanSetTips_Frame:SetProperty("AbsoluteYPosition",SetY - TipsHeight)
	else
		ZhenYuanSetTips_Frame:SetProperty("AbsoluteYPosition",SetY + SetHeight)
	end
end