
--拼图名称及对应图片
local JiugongImage = {
	{1, "set:Choujiang image:Choujiang_14"},
	{2, "set:Choujiang image:Choujiang_15"},
	{3, "set:Choujiang image:Choujiang_12"},
	{4, "set:Choujiang image:Choujiang_16"},
	{5, "set:Choujiang image:Choujiang_13"},
}

--记录点击的是大界面上哪个位置
local pos = 0

function Jiugong_num_PreLoad()
	this:RegisterEvent("UI_COMMAND");
end

function Jiugong_num_OnLoad()
	this:Hide()
--	Jiugong_num_Image01:SetProperty("Image", JiugongImage[1][2])
--	Jiugong_num_Image02:SetProperty("Image", JiugongImage[2][2])
--	Jiugong_num_Image03:SetProperty("Image", JiugongImage[3][2])
--	Jiugong_num_Image04:SetProperty("Image", JiugongImage[4][2])
--	Jiugong_num_Image05:SetProperty("Image", JiugongImage[5][2])
end

function Jiugong_num_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 20100519) then
			pos = tonumber(arg1)
			this:Show()
	end
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20100520) then
			this:Hide()
	end

end

--=========================================================
--重置界面
--=========================================================
function Jiugong_num_Clear() 

end

--=========================================================
--更新界面
--=========================================================
function Jiugong_num_Update( pos_ui, pos_packet )

end

--=========================================================
--关闭
--=========================================================
function Jiugong_num_Close()
	this:Hide()
end

--=========================================================
--界面隐藏
--=========================================================
function Jiugong_num_OnHide()
	this:Hide()
end

--=========================================================
--选择数字
--=========================================================
function Jiugong_num_Add(index) 
	PushEvent("UI_COMMAND", 20100518, index, pos);
	Jiugong_num_Close()
end
function Jiugong_Close()
	this:Hide()
end