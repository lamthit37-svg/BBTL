--对应的脚本号和函数名
local scriptId = 300133
local functionName = "OnSudokuCheck"
local newtooltip=
{
	[0] = {Tooltip = "TJRW_100511_74"}
}

--各数字及对应的图片 1-5为玩家5个数字对应的图片，6-10为玩家不可改变的位置的图片，11为空
local JiugongImage = {
	{1, "set:Tianji image:Tianji_1"},
	{2, "set:Tianji image:Tianji_2"},
	{3, "set:Tianji image:Tianji_3"},
	{4, "set:Tianji image:Tianji_4"},
	{5, "set:Tianji image:Tianji_5"},
--
	{1, "set:Tianji image:Tianji_1_lock"},
	{2, "set:Tianji image:Tianji_2_lock"},
	{3, "set:Tianji image:Tianji_3_lock"},
	{4, "set:Tianji image:Tianji_4_lock"},
	{5, "set:Tianji image:Tianji_5_lock"},
--
	{0, "set:Tianji image:Tianji_0"}, --代表空白
}

--二十五个控件格
local JiugongSet = {}

--从服务器得到的二十五个格里的初始数字
local JiugongNumber = {}

--当前二十五个格里的数字
local JiugongCurr = {}

--客户端产生数独盘用到的数据
local sudoku = {}
local times = {}
local num = {}
local result = {}

function Jiugong_PreLoad()
	this:RegisterEvent("UI_COMMAND");
end

function Jiugong_OnLoad()
	this:Hide()
	Jiugong_Clear()
end

function Jiugong_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 20100516) then
		--解答正确，关闭界面
		Jiugong_Close()
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 20100515) then
		--打开界面，根据传入的参数填写各格图片及状态
		GetSudoku()
		--在此处添加C++接口调用，把25个格子的数从四个参数中解出来,放置于两个数组中
		local i = 1
		while i <= 25 do
--			JiugongNumber[i] = UnPack_Sudoku(i, s1, s2, s3, s4)
			JiugongCurr[i] = JiugongNumber[i]
			i = i + 1
		end
		--
		--根据数字设置图片(更新界面)
		Jiugong_Draw(0, 0, 0)

		this:Show()
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 20100518) then
		--玩家点击了小界面的数字，根据数字设置图片
		local index = tonumber(arg2)
		local value = tonumber(arg1)

		if value > 5 or value < 1 or index < 1 or index > 25 then
			return 0
		end
		
		--如果发现是不能修改的，就提示玩家
		if JiugongNumber[index] ~= 0 then
			PushDebugMessage("#{TJRW_100511_74}")
			return
		end

		--根据数字设置图片(更新界面)
		Jiugong_Draw(1, index, value)

	end

end

--=========================================================
--重置界面
--=========================================================
function Jiugong_Clear() 
	Jiugong_DragTitle:SetText("")
	Jiugong_Text:SetText("#{TJRW_100511_29}")

	--初始化25个格子
	JiugongSet[1] = Jiugong_Image01
	JiugongSet[2] = Jiugong_Image02
	JiugongSet[3] = Jiugong_Image03
	JiugongSet[4] = Jiugong_Image04
	JiugongSet[5] = Jiugong_Image05	
	JiugongSet[6] = Jiugong_Image06
	JiugongSet[7] = Jiugong_Image07
	JiugongSet[8] = Jiugong_Image08
	JiugongSet[9] = Jiugong_Image09
	JiugongSet[10] = Jiugong_Image10
	JiugongSet[11] = Jiugong_Image11
	JiugongSet[12] = Jiugong_Image12
	JiugongSet[13] = Jiugong_Image13
	JiugongSet[14] = Jiugong_Image14
	JiugongSet[15] = Jiugong_Image15
	JiugongSet[16] = Jiugong_Image16
	JiugongSet[17] = Jiugong_Image17
	JiugongSet[18] = Jiugong_Image18
	JiugongSet[19] = Jiugong_Image19
	JiugongSet[20] = Jiugong_Image20
	JiugongSet[21] = Jiugong_Image21
	JiugongSet[22] = Jiugong_Image22
	JiugongSet[23] = Jiugong_Image23
	JiugongSet[24] = Jiugong_Image24
	JiugongSet[25] = Jiugong_Image25
	
	local i = 1
	while i <= 25 do
		JiugongSet[i]:SetProperty("Image", JiugongImage[11][2]);	--设置为空白图片
		JiugongCurr[i] = 0
		JiugongNumber[i] = 0
		i = i + 1
	end
end

--=========================================================
--更新界面
--=========================================================
function Jiugong_Update( pos_ui, pos_packet )

end

--=========================================================
--关闭
--=========================================================
function Jiugong_Close()
	this:Hide()
	PushEvent("UI_COMMAND", 20100520);
	Jiugong_Clear()
end

--=========================================================
--界面隐藏
--=========================================================
function Jiugong_OnHide()
	this:Hide()
	PushEvent("UI_COMMAND", 20100520);
	Jiugong_Clear()
end

--=========================================================
--重画界面
--=========================================================
function Jiugong_Draw( flag, index, value )
	--flag为0是第一次显示，flag为1是填了某个数字
	if flag == 0 then
		local i = 1
		while i <= 25 do
			JiugongCurr[i] = 0
			i = i + 1
		end
		i = 1
		while i <= 25 do
			JiugongSet[i]:SetProperty("Image", JiugongImage[11][2]);	--设置为空白图片
			JiugongSet[i]:SetToolTip(GetDictionaryString("TJRW_100511_73"))--先全设为“点击即可填入数字”
			if JiugongNumber[i] ~= 0 then
				JiugongSet[i]:SetToolTip(GetDictionaryString(newtooltip[0].Tooltip))--将初始的几个改成“你不能修改...”
				JiugongCurr[i] = JiugongNumber[i]
				for j, v in JiugongImage do
					if j > 5 and v[1] == JiugongNumber[i] then
						JiugongSet[i]:SetProperty("Image", v[2])
						break
					end
				end
			end
			i = i + 1
		end
	elseif flag == 1 then
		--设置数字和图片
		JiugongCurr[index] = value		
		for j, v in JiugongImage do
			if j <= 5 and v[1] == value then
				JiugongSet[index]:SetProperty("Image", v[2])
				break
			end
		end
	end
end

--=========================================================
--填写数字
--=========================================================
function Jiugong_Add(index)
	if JiugongNumber[index] ~= 0 then
--		PushDebugMessage("您不能改变这个数字")
		return
	end
--添加处理函数
--	PushDebugMessage(index)
	PushEvent("UI_COMMAND", 20100519, index);
end

--=========================================================
--提交题目
--=========================================================
function Jiugong_Confirm()
	--提交前需要检测
	
	--检测是否填完
	local i = 1
	while i <= 25 do
		if JiugongCurr[i] == 0 then
			PushDebugMessage("#{TJRW_100511_30}")
			return
		end
		i = i + 1
	end
	
	--检测填写是否正确
	i = 1
	while i <= 25 do
		if Jiugong_Check(i) ~= 1 then
			PushDebugMessage("#{TJRW_100511_30}")
			return
		end
		i = i + 1
	end
	

	--提交
	Clear_XSCRIPT();--服务器端提示消息
	Set_XSCRIPT_Function_Name(functionName);
	Set_XSCRIPT_ScriptID(scriptId);
--	Set_XSCRIPT_Parameter(0,1);
	Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

--=========================================================
--重置题目
--=========================================================
function Jiugong_Reset()
	Jiugong_Draw(0, 0, 0)
end

--=========================================================
--检查结果
--=========================================================
function Jiugong_Check(index)
	--先判断该行或者该列是否已经填写了这个数
	value = JiugongCurr[index]
	local arr = math.floor((index - 1) / 5) + 1
	local row = math.mod(index, 5)
	if row == 0 then
		row = 5
	end
	local start = 5 * (arr - 1) + 1
	local stop = start + 4
	local i = start
	while i <= stop do
		local curr = JiugongCurr[i]
		if curr == value and i ~= index then
--			PushDebugMessage("这个数字不能放在这里！")
--			PushEvent("UI_COMMAND", 20100519, index)
			return 0
		end
		i = i + 1
	end
	i = 0
	while i <= 4 do
		local curr = JiugongCurr[5 * i + row]
		if curr == value and (5 * i + row) ~= index then
--			PushDebugMessage("这个数字不能放在这里！")
--			PushEvent("UI_COMMAND", 20100519, index)
			return 0
		end
		i = i + 1
	end
	return 1
end

--=========================================================
--以下是客户端用到的数独算法函数
--=========================================================
function GetSudoku()
	Sudoku_Init()
	Sudoku_Sudoku()
	Sudoku_Generate()
	Sudoku_Output()
end

function Sudoku_Init()
	local i = 1
	while i <= 25 do
		sudoku[i] = 0
		times[i] = 0
		local j = 1;
		while j <= 5 do
			num[i][j] = j
			j = j + 1
		end
		i = i + 1
	end
	return
end

function Sudoku_Sudoku()
	local i = 1
	while i <= 25 do
		sudoku[i] = Sudoku_GetNum(i)
		if sudoku[i] == 0 then
			times[i] = 0
			i = i - 2
		elseif Sudoku_Check(i) == 0 then
			i = i - 1
		end
		i = i + 1
	end
	return
end

function Sudoku_GetNum(i)
	if times[i] == 5 then
		return 0
	end
	local pos = 5-times[i]
	local index = math.random(1, pos)
	local tmp = num[i][5 - times[i]]
	num[i][5 - times[i]] = num[i][index]
	num[i][index] = tmp
	tmp = num[i][5 - times[i]]
	times[i] = times[i] + 1
	return tmp
end

function Sudoku_Check(pos)
	local value = sudoku[pos]
	local row = math.floor((pos - 1)/5)
	local col = math.mod((pos -1), 5)
	local start = 5 * row + 1
	local endl = start + 4
	local i = start
	while i <= endl do
		if pos ~= i and value == sudoku[i] then
			return 0
		end
		i = i + 1
	end
	i = 0
	while i <=4 do
		if pos ~= i*5 + col + 1 and value == sudoku[i*5+col+1] then
			return 0
		end
		i = i + 1
	end
	return 1
end

function Sudoku_Output()
	local i = 1
	while i <= 25 do
		JiugongNumber[i] = result[i]
--		JiugongNumber[i] = sudoku[i]
		i = i + 1
	end
end

function Sudoku_Exchange()
	--产生的数独可以进行矩阵变换，具体可以参考服务器端的数独代码，客户端暂时不用
end

function Sudoku_Generate()
	local i = 1
	while i <= 25 do
		result[i] = 0
		i = i + 1
	end
	i = 1
	while i <= 10 do
		local index = math.random(1, 25)
		while result[index] ~= 0 or Sudoku_CheckResult(index) == 0 do
			index = math.random(1, 25)
		end
		result[index] = sudoku[index]
		i = i + 1
	end
end

function Sudoku_CheckResult(pos)
	local row = math.floor((pos - 1)/5)
	local col = math.mod((pos -1), 5)
	local start = 5 * row + 1
	local endl = start + 4
	local totalrow = 0
	local totalcol = 0
	local i = start
	while i <= endl do
		if result[i] ~= 0 then
			totalrow = totalrow + 1
		end
		i = i + 1
	end
	i = 0
	while i <=4 do
		if result[i*5+col+1] ~= 0 then
			totalcol = totalcol + 1
		end
		i = i + 1
	end
	if totalrow >= 3 or totalcol >= 3 then
		return 0
	end
	return 1
end