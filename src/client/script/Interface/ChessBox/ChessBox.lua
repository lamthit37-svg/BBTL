--棋盒界面脚本

local needArray = {5,2,2,2,2,2,1}

function ChessBox_PreLoad()
	this:RegisterEvent("UI_COMMAND");
end

function ChessBox_OnLoad()

end

function ChessBox_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 502018) then	
		local paramSong = Get_XParam_INT(0)
		local paramLiao = Get_XParam_INT(1)
		local songQi={}--宋 兵马炮车相士帅
		local liaoQi={}--辽 卒马炮车象士将
		local displayStr = {}
		local denominator = 1
		--PushDebugMessage(paramLiao)
		for i = 1, 7 do
		--	PushDebugMessage()
			songQi[i] = math.mod(math.floor(paramSong/denominator),10)
			liaoQi[i] = math.mod(math.floor(paramLiao/denominator),10)
			denominator = denominator * 10
		end
		--PushDebugMessage("2")
		--设置界面显示
		for j = 1, 7 do
			if songQi[j] < needArray[j] then
				displayStr[j]="#Y"..songQi[j].."/"..needArray[j]
			else
				displayStr[j]="#G"..songQi[j].."/"..needArray[j]
			end
			
			if liaoQi[j] < needArray[j] then
				displayStr[j+7]="#Y"..liaoQi[j].."/"..needArray[j]
			else
				displayStr[j+7]="#G"..liaoQi[j].."/"..needArray[j]
			end
		end
		--PushDebugMessage("3")
		Chessbox_text_01:SetText(displayStr[1])
		Chessbox_text_02:SetText(displayStr[2])
		Chessbox_text_03:SetText(displayStr[3])
		Chessbox_text_04:SetText(displayStr[4])
		Chessbox_text_05:SetText(displayStr[5])
		Chessbox_text_06:SetText(displayStr[6])
		Chessbox_text_07:SetText(displayStr[7])
		Chessbox_text_08:SetText(displayStr[8])
		Chessbox_text_09:SetText(displayStr[9])
		Chessbox_text_10:SetText(displayStr[10])
		Chessbox_text_11:SetText(displayStr[11])
		Chessbox_text_12:SetText(displayStr[12])
		Chessbox_text_13:SetText(displayStr[13])
		Chessbox_text_14:SetText(displayStr[14])		
		this:Show()
	end
end

function ChessBox_OnHide()
	this:Hide()
end

function ChessBox_Close()
	this:Hide()
end
