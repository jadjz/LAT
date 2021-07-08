local ScriptHelper = {}

--参数配置
ScriptHelper.Script_Type = 
{
	['ctrl'] = {type = 1, class = "%sCtrl = %sCtrl or BaseClass()", func = {[1] = "__init", [2] = "Instance", [3] = "GetView", [4] = "GetData", [5] = "ResetData"}},
	['view'] = {type = 2, class = "%sView = %sView or BaseClass(BaseUIPanel)", func = {[1] = "__init", [2] = "loadLayoutCallback", [3] = "AddToStage", [4] = "RemoveFromStage", [5] = "CreateSV"}},
	['data'] = {type = 3, class = "%sData = %sData or BaseClass()", func = {[1] = "__init", [2] = "ResetData", [3] = "InitConfig", [4] = "GetConfig"}},
}

function ScriptHelper.New()
	local obj = {}
	setmetatable(obj, {__index = ScriptHelper})
	ScriptHelper.__init(obj)
	return obj
end

function ScriptHelper:__init()

end
--函数方法格式化
function ScriptHelper:GetLuaFunctionFormat()
	return "function %s:%s()"
end

function ScriptHelper:GetInstanceFormat(class_name)
	return "	if not %s._inst then\n" ..
			"		%s._inst = %s.New()\n" ..
			"	end\n" ..
			"	return %s._inst"
end

function ScriptHelper:GetViewFormat()
	return "	if not self.view then\n" ..
			"		require(%s)\n" ..
			"		self.view = %s.New()\n" ..
			"	end\n" ..
			"	return self.view"
end

function ScriptHelper:GetDataFormat()
	return "	if not self.data then\n" ..
			"		require(%s)\n" ..
			"		self.data = %s.New()\n" ..
			"	end\n" ..
			"	return self.data"
end

function ScriptHelper:CreateSV()
	return  "function %s:InitSV()\n" ..
			"	if self.sv_handle then\n" ..
			"		return\n" ..
			"	end\n" ..
			"	self.cell_num = self:GetCellNum()\n" ..

			"	local createSVHandle = UITool:Instance():GetSVCreateTable()\n" ..
			"	createSVHandle.viewSize = UVector2(560, 600) --scroolview 可视区域大小\n" ..
			"	createSVHandle.parent = self.sv_wid          --sv挂在父节点\n" ..
			"	local template_config = createSVHandle.Configs[1]\n" ..
			"	template_config.sVInfoTemplateTyps = SVInfoTemplateTyps.NomalTemplate\n" ..
			"	template_config.template = self.sv_cell.go      --cell预制件\n" ..
			"	template_config.itemRootSize = UVector2(90, 90) --cell父节点大小\n" ..         
			"	template_config.childCellSize = UVector2(90, 90)--cell大小\n" ..
			"	template_config.itemPandding = 0				--上下cell间距\n" ..
			"	template_config.itemXYPandding = UVector2(0, 0) --左右cell间距\n" ..
			    
			"	createSVHandle.moveAxis = MoveAxisDirection.TopToBottom --sv滑动方向\n" ..
			"	createSVHandle.viewType = ScrollViewType.Nomal\n" ..
			"	createSVHandle.totalMaxCount = self.cell_num            --cell数量\n" ..
			"	createSVHandle.pageCount = 1                            --sv页数\n" ..
			"	createSVHandle.itemCountPerRow = 1                      --每一行多少个cell预制件\n" ..

			"	createSVHandle.OnUpdateFunctionShow = function(...)\n" ..
			"		local cell_handle = UITool:Instance():InitSVItemHandle(...)\n" ..
			"		self:UpdateItemCell(cell_handle)\n" ..
			"	end\n" ..

			"	self.sv_handle = UITool:Instance():CreateScrollView(createSVHandle)\n" ..
			"	self.sv_handle:Show()\n" ..
			"end\n\n" ..

			"function %s:UpdateItemCell(cell_handle)\n" ..
			"	local cell_index =  cell_handle.row_index --从0开始\n" ..
			"	local cell_content = cell_handle:SVGetControl('xxxxx') --获取预制件根节点\n" ..
			"end\n\n" ..

			"function %s:GetCellNum()\n" ..
			"	--计算cell数量\n" ..
			"	return 1\n" ..
			"end\n\n" ..

			"function %s:RefreshSV()\n" ..
			"	if not self.sv_handle then\n" ..
			"		return\n" ..
			"	end\n" ..
			"	local cur_cell_num = self:GetCellNum()\n" ..
			"	if self.cell_num ~= cur_cell_num then\n" ..
			"		self.sv_handle:AddItemCount(cur_cell_num, true)\n" ..
			"		self.cell_num = cur_cell_num\n" ..
			"	else\n" ..
			"		self.sv_handle:RefreshAllShow()\n" ..
			"	end\n" ..
			"end\n\n"
end

function ScriptHelper:Run(param, class_name, postFix, require_file, show_sv)
	io.write(string.format(param.class, class_name, class_name))
	io.write("\n\n")

	for i,v in ipairs(param.func) do
		if v == "CreateSV" then
			if show_sv == "true" then
				local tmp_class_name = class_name .. postFix
				io.write(string.format(self:CreateSV(), tmp_class_name, tmp_class_name, tmp_class_name, tmp_class_name))
				io.write("\n")
			end
		else
			io.write(string.format(self:GetLuaFunctionFormat(), class_name .. postFix, v))
			io.write("\n")
			if v == "Instance" then
				local tmp_class_name = class_name .. postFix
				io.write(string.format(self:GetInstanceFormat(), tmp_class_name, tmp_class_name, tmp_class_name, tmp_class_name))
			elseif v == "GetView" then
				local v_require_file = '"' .. require_file .. "_view" .. '"'
				io.write(string.format(self:GetViewFormat(), v_require_file, class_name .. "View"))
			elseif v == "GetData" then
				local d_require_file = '"' .. require_file .. "_data" .. '"'
				io.write(string.format(self:GetDataFormat(), d_require_file, class_name .. "Data"))
			else
				if param.type == 2 then
					if v == "__init" then
						io.write("	self.layout_name = xxx")
					elseif v == "loadLayoutCallback" then
						io.write("	self.xx = self:getControl(xx)")
						io.write("\n")
						io.write("	self.xxx = self.xx:GetControl(xxx)")
					else
						io.write("	--todo ...")
					end
				else
					io.write("	--todo ...")
				end
			end
			io.write("\n")
			io.write("end")
			io.write("\n\n")
		end
	end
end

function ScriptHelper:CreateCtrl(FolderName, FileName, class_name)
	local require_file = "gamebase." .. FolderName .. "." .. FileName
	self:Run(ScriptHelper.Script_Type.ctrl, class_name, "Ctrl", require_file)
	print("Script Ctrl Finish!")
end

function ScriptHelper:CreateView(class_name, show_sv)
	self:Run(ScriptHelper.Script_Type.view, class_name, "View", nil, show_sv)
	print("Script View Finish!")
end

function ScriptHelper:CreateData(class_name)
	self:Run(ScriptHelper.Script_Type.data, class_name, "Data")
	print("Script Data Finish!")
end

function ScriptHelper:GetClassName(file_name)
	local class_name = ""
	-- for v,_ in string.gmatch(file_name, "%w+") do
	-- 	class_name = class_name .. string.gsub(v, "(%w)", function (arg)
	-- 		return string.upper(arg)
	-- 	end)
	-- end
	class_name = string.gsub(file_name, "_(%w)", function (arg)
		return string.upper(arg)
	end)

	return string.upper(string.sub(class_name, 1, 1)) .. string.sub(class_name, 2, string.len(class_name))
end

function ScriptHelper:CreateFile(file_path, file_name, fix_name, func)
	local full_file_name = file_path .. "\\" .. file_name .. fix_name

	-- 以只读方式打开文件
	local file = io.open(full_file_name, "w+")
	-- 设置默认输出文件为 test.lua
	io.output(file)

	func(self:GetClassName(file_name)) 

	-- 关闭打开的文件
	io.close(file)
end

function ScriptHelper.Split()
	local FileName = ""
	local FolderName = ""
	local SavePath = ""
	local InstanceName = ""
	local CreateScrollView = "false"
	local args = ScriptHelper.LoadConfig()
	for i,v in ipairs(args) do
		local ret = false
		string.gsub(v, "FolderName:(%w+)", function (p)
			FolderName = p
			ret = true
		end)

		if	not ret then
			string.gsub(v, "FileName:%[(.*)%]", function (p)
				FileName = p
				ret = true
			end)
		end

		if	not ret then
			string.gsub(v, "InstanceName:(%w+)", function (p)
				InstanceName = p
				ret = true
			end)
		end

		if	not ret then
			string.gsub(v, "SavePath:(.*)%W%p", function (p)
				SavePath = p
				ret = true
			end)
		end

		if	not ret then
			string.gsub(v, "CreateScrollView:(%w+)", function (p)
				CreateScrollView = p
				ret = true
			end)
		end
	end
	return SavePath, FolderName, FileName, InstanceName, CreateScrollView
end

function ScriptHelper.LoadConfig()
	local file = io.open("..\\..\\configload\\configluascript.gmt", "rb")
	io.input(file)
	local args = {}
	while true do
		local arg = io.read()
		if arg then
			table.insert(args, arg)
		else
			break
		end
	end
	io.close()
	return args
end

function ScriptHelper.FileExist(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

function Run()
	--执行cmd命令
	local SavePath, FolderName, FileName, InstanceName, CreateScrollView = ScriptHelper.Split()
	local full_file_name = SavePath .. "\\\\" .. FolderName
	local ret = os.execute(string.format("mkdir %s", full_file_name)) --创建文件目录
	local helper = ScriptHelper.New()
	helper:CreateFile(full_file_name, FileName .. "_ctrl", ".lua", function ()
		helper:CreateCtrl(FolderName, FileName, InstanceName)
	end)

	helper:CreateFile(full_file_name, FileName .. "_data", ".lua", function ()
		helper:CreateData(InstanceName)
	end)

	helper:CreateFile(full_file_name, FileName .. "_view", ".lua",function ()
		helper:CreateView(InstanceName, CreateScrollView)
	end)
end

Run()

