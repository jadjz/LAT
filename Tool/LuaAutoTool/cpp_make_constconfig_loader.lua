local ConfigLoader = {}

function ConfigLoader.LoadConfig()
	local file = io.open("..\\..\\configload\\configconstconfig.gmt", "rb")
	local filterList = {}
	io.input(file)
	while true do
		local arg = io.read()
		if arg then
			string.gsub(arg, "StructName:(.*)%W%p", function (p)
				while p do
					local endPos = string.find(p, ",")
					if not endPos then
						filterList[p] = true
						break
					end
					local param = string.sub(p, 1, endPos - 1)
					filterList[param] = true
					p = string.sub(p, endPos + 1, string.len(p))
				end
			end)
		else
			break
		end
	end
	io.close()

	local StructNames = {} --结构体列表
	local StructIncludeString = {} --含有string结构体

	local file = io.open("..\\..\\config\\constconfig.gmt", "rb")
	io.input(file)
	local curStructName = nil
	while true do
		local arg = io.read()
		if arg then
			local ret = false
			string.gsub(arg, "struct (%w+):", function (p)
				if filterList[p] then
					table.insert(StructNames, p)
					curStructName = p
				else
					curStructName = nil
				end
				ret = true
			end)

			if not ret then
				string.gsub(arg, "string (.*)%s=", function (p)
					if curStructName then
						if not StructIncludeString[curStructName] then
							StructIncludeString[curStructName] = {}
						end
						local param = {}
						param.val = p
						if string.find(p, "reward") then
							param.type = "reward"
						elseif string.find(p, "item") then
							param.type = "item"
						elseif string.find(p, "list") then
							param.type = "list"
						elseif string.find(p, "tuple") then
							param.type = "tuple"
						elseif string.find(p, "triad") then
							param.type = "triad"
						end

						if next(param) then
							table.insert(StructIncludeString[curStructName], param)
						end
					end
					ret = true
				end)
			end
		else
			break
		end
	end
	io.close()
	return StructNames, StructIncludeString
end

function ConfigLoader.WriteHead(SavePath, FileName, StructNames, StructIncludeString)
	local full_file_name = SavePath .. "\\\\" .. FileName .. ".h"
	local file = io.open(full_file_name, "w+")
	io.output(file)
	--start to write
	ConfigLoader.StartToHead(file, FileName, StructNames, StructIncludeString)
	io.close(file)
end

function ConfigLoader.StartToHead(file, FileName, StructNames, StructIncludeString)
	file:write("/*\n")
	file:write("* @filename constconfig.h\n")
	file:write("*\n")
	file:write("* @brief This files is Auto-Generated. Please DON'T modify it EVEN if\n")
	file:write("*        you know what you are doing.\n")
	file:write("*/\n")
	file:write("\n")

	file:write(string.format("#ifndef __global_gmt_%s_h__", FileName))
	file:write("\n")
	file:write(string.format("#define __global_gmt_%s_h__", FileName))
	file:write("\n")
	file:write("\n")
	file:write(string.format("#include %s\n", '"' .. "servercommon/gmtrmi/config/configmanager.h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "servercommon/gmtrmi/config/constconfig.h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "servercommon/gmtrmi/msg/msgcommon.h" .. '"'))
	file:write(string.format("#include %s\n", "<map>"))
	file:write("\n")
	file:write("\n")

	file:write("namespace globalserver\n")
	file:write("{\n")
	file:write("	namespace configgmt\n")
	file:write("	{\n")
	file:write("		class CConstConfigManagerEx: public servercommon::gmtrmi::config::CConfigManagerBase\n")
	file:write("		{\n")
	file:write("		public:\n")

	for i,v in ipairs(StructNames) do
		file:write(string.format("			typedef servercommon::gmtrmi::config::constconfig::%s %s_type;\n", v, string.lower(string.sub(v, 2, string.len(v)))))
	end
	
	file:write("\n\n")

	file:write("		public:\n")
    file:write("			static CConstConfigManagerEx * instance();\n")

	file:write("			virtual bool loadConfig();\n")
	file:write("			virtual const std::string getConfigFileName();\n")
	file:write("			bool CheckConfigs();\n")

	file:write("\n")
	file:write("		private:\n")
	file:write("			CConstConfigManagerEx() {}\n")
	file:write("			~CConstConfigManagerEx() {}\n")
	file:write("\n")


	file:write("\n")
	for i,v in ipairs(StructNames) do
		local structName = string.sub(v, 2, string.len(v))
		file:write(string.format("			bool Check%s();\n", structName))
	end

	file:write("\n")
	file:write("			//If need to check the other config,please override this function!!\n")
	for i,v in ipairs(StructNames) do
		local structName = string.sub(v, 2, string.len(v))
		file:write(string.format("			bool CustomCheck(const %s_type &config);\n", string.lower(structName)))
	end

	file:write("\n")
	file:write("		private:\n")
	file:write("			static CConstConfigManagerEx * _inst;\n")
	file:write("\n")

	--定义变量
	for i,v in ipairs(StructNames) do
		local typeName = string.lower(string.sub(v, 2, string.len(v)))
		file:write(string.format("			%s_type _%s;\n", typeName, typeName))
	end
	file:write("\n")

	for key, params in pairs(StructIncludeString) do
		local structName = string.sub(key, 2, string.len(key))
		for _, v in ipairs (params) do
			if v.type == "reward" or v.type == "item" then
				file:write(string.format("			servercommon::gmtrmi::msg::msgcommon::SeqReward _%s_%s;\n", string.lower(structName), v.val))
			elseif v.type == "list" then
				file:write(string.format("			servercommon::gmtrmi::msg::msgcommon::SeqInt _%s_%s;\n", string.lower(structName), v.val))
			elseif v.type == "tuple" then
				file:write(string.format("			servercommon::gmtrmi::msg::msgcommon::SeqAttrInfo _%s_%s;\n", string.lower(structName), v.val))
			elseif v.type == "triad" then
				file:write(string.format("			servercommon::gmtrmi::msg::msgcommon::SeqReward _%s_%s;\n", string.lower(structName), v.val))
			end
		end
	end
	file:write("\n")

	file:write("		public:\n")
	for i,v in ipairs(StructNames) do
		local structName = string.sub(v, 2, string.len(v))
		local typeName = string.lower(structName)
		file:write(string.format("			const %s_type& Get%s() const { return _%s; }\n", typeName, structName, typeName))
	end
	file:write("\n")
	file:write("\n")
	for key, params in pairs(StructIncludeString) do
		local structName = string.sub(key, 2, string.len(key))
		for _, v in ipairs (params) do
			local paramName = v.val:gsub("^%l",string.upper)
			paramName = ConfigLoader.Filter(paramName, "_")
			if v.type == "reward" then
				file:write(string.format("			const servercommon::gmtrmi::msg::msgcommon::SeqReward& Get%s%s() const { return _%s_%s; }\n", structName, paramName, string.lower(structName), v.val))
			elseif v.type == "item" then
				file:write(string.format("			const servercommon::gmtrmi::msg::msgcommon::SeqReward& Get%s%s() const { return _%s_%s; }\n", structName, paramName, string.lower(structName), v.val))
			elseif v.type == "list" then
				file:write(string.format("			const servercommon::gmtrmi::msg::msgcommon::SeqInt& Get%s%s() const { return _%s_%s; }\n", structName, paramName, string.lower(structName), v.val))
			elseif v.type == "tuple" then
				file:write(string.format("			const servercommon::gmtrmi::msg::msgcommon::SeqAttrInfo& Get%s%s() const { return _%s_%s; }\n", structName, paramName, string.lower(structName), v.val))
			elseif v.type == "triad" then
				file:write(string.format("			const servercommon::gmtrmi::msg::msgcommon::SeqReward& Get%s%s() const { return _%s_%s; }\n", structName, paramName, string.lower(structName), v.val))
			end
		end
	end

	file:write("		};\n")
	file:write("	}\n")

	file:write("}\n")
	file:write("\n")
	file:write("#endif\n")

	print("The head file done~~")
end

function ConfigLoader.Filter(str, char)
	return string.gsub(str, "_(%a)", function (c)
		if type(c) == "string" then
			return string.upper(c)
		end
	end)
end

function ConfigLoader.WriteCpp(SavePath, FileName, StructNames, StructIncludeString)
	local full_file_name = SavePath .. "\\\\" .. FileName .. ".cpp"
	local file = io.open(full_file_name, "w+")
	io.output(file)
	--start to write
	ConfigLoader.StartToCpp(file, FileName, StructNames, StructIncludeString)
	io.close(file)
	print("The ccp file done~~")
end

function ConfigLoader.StartToCpp(file, FileName, StructNames, StructIncludeString)
	file:write(string.format("#include %s\n", '"' .. FileName .. ".h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "globalserver/globalserver/item/itempool.h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "servercommon/websocket/wsdef.h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "servercommon/gmtrmi/config/parserhelper.h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "servercommon/gmtrmi/msg/constdef.h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "servercommon/struct/structsizedef.h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "globalserver/configgmt/gmtconfighelper.h" .. '"'))

	file:write("#include <stdio.h>\n")
	file:write("#include <math.h>\n")

	file:write("\n\n")
	file:write("using namespace globalserver::configgmt;\n")
	file:write("using namespace servercommon::gmtrmi;\n")
	file:write("using namespace servercommon::gmtrmi::msg::constdef;\n")
	file:write("\n")

	file:write("CConstConfigManagerEx * CConstConfigManagerEx::_inst = NULL;\n\n")
	file:write("CConstConfigManagerEx * CConstConfigManagerEx::instance()\n")
	file:write("{\n")
	file:write("	if (NULL == _inst)\n")
	file:write("	{\n")
	file:write("		_inst = new CConstConfigManagerEx();\n")

	file:write("	}\n")
	file:write("	return _inst;\n")
	file:write("}\n\n")

	file:write("const std::string CConstConfigManagerEx::getConfigFileName()\n")
	file:write("{\n")
	file:write(string.format("	return %s;\n", '"' .. "constconfig.json" .. '"'))
	file:write("}\n")
	file:write("\n")

	file:write("bool CConstConfigManagerEx::loadConfig()\n")
	file:write("{\n")
	file:write("	std::string filePath = getAbsDir();\n")
	file:write("	JsonParser __js;\n")
	file:write("	if (__js.InitFromFile(filePath.c_str()))\n")
	file:write("	{\n")
	for i,v in ipairs(StructNames) do
		local typeName = string.lower(string.sub(v, 2, string.len(v)))
		file:write(string.format("		if(__js.Down(_%s.__name().c_str()))\n", typeName))
		file:write("		{\n")
		file:write(string.format("			_%s.fromJs(__js);\n", typeName))
		file:write("			__js.Up();\n")
		file:write("		}\n")
		file:write("\n")
	end
	file:write("	}\n")
	
	file:write("	else\n")
	file:write("	{\n")
	local errorLog = "printf(" .. '"' .. "CConstConfigManagerEx::loadConfig. %s is not found. default values will be applied.\\n" ..'"' .. "," .. "filePath.c_str());"
	file:write(string.format("		%s\n", errorLog))
	file:write("	}\n")
	file:write("	return true;\n")
	file:write("}\n")
	file:write("\n")


	file:write("bool CConstConfigManagerEx::CheckConfigs()\n")
	file:write("{\n")
	for i,v in ipairs(StructNames) do
		local structName = string.sub(v, 2, string.len(v))
		file:write(string.format("	if(!Check%s())\n", structName))
		file:write("	{\n")
		file:write("		return false;\n")
		file:write("	}\n")
	end
	file:write("	return true;\n")
	file:write("}\n")
	file:write("\n")

	for _,key in ipairs(StructNames) do
		local structName = string.sub(key, 2, string.len(key))
		local typeName = string.lower(structName)
		file:write(string.format("bool CConstConfigManagerEx::Check%s()\n", structName))
		file:write("{\n")
		local params = StructIncludeString[key]
		if params then
			for _, v in ipairs (params) do
				if v.type == "reward" or v.type == "item" then
					file:write(string.format("	if (!globalserver::configgmt::CGmtConfigHelper::ParseAndCheckRewards(_%s.%s, _%s_%s))\n", typeName, v.val, typeName, v.val))
					ConfigLoader.ParseConfigString(file, structName, typeName, v.val)
				elseif v.type == "list" then
					file:write(string.format("	if (!servercommon::CParserHelper::ParseIntList(_%s.%s, _%s_%s))\n", typeName, v.val, typeName, v.val))
					ConfigLoader.ParseConfigString(file, structName, typeName, v.val)
				elseif v.type == "tuple" then
					file:write(string.format("	if (!servercommon::CParserHelper::ParseAttrInfo(_%s.%s, _%s_%s))\n", typeName, v.val, typeName, v.val))
					ConfigLoader.ParseConfigString(file, structName, typeName, v.val)
				elseif v.type == "triad" then
					file:write(string.format("	if (!servercommon::CParserHelper::ParseRewards(_%s.%s, _%s_%s))\n", typeName, v.val, typeName, v.val))
					ConfigLoader.ParseConfigString(file, structName, typeName, v.val)
				end
			end
		end

		file:write(string.format("	if(!CustomCheck(_%s))\n", typeName))
		file:write("	{\n")
		file:write("		return false;\n")
		file:write("	}\n")
		file:write("\n")

		file:write("	return true;\n")
		file:write("}\n")
		file:write("\n")
	end
	file:write("\n")
end

function ConfigLoader.ParseConfigString(file, structName, typeName, val)
	file:write("	{\n")
	local errorLog = "printf(" .. '"' .. "[CConstConfigManagerEx::"
	local errorLog2 = string.format("Check%s] %s", structName, val)
	local errorLog3 = "%s error.\\n" .. '",'
	file:write(string.format("		%s%s %s %s);\n", errorLog, errorLog2, errorLog3, string.format("_%s.%s.c_str()", typeName, val)))
	file:write("		return false;\n")
	file:write("	}\n")
	file:write("\n")
end

function ConfigLoader.Run()
	local SavePath = "..\\..\\..\\server\\server\\globalserver\\configgmt"
	local FileName = "constconfigmanagerex"
	local StructNames, StructIncludeString = ConfigLoader.LoadConfig()
	ConfigLoader.WriteHead(SavePath, FileName, StructNames, StructIncludeString)
	ConfigLoader.WriteCpp(SavePath, FileName, StructNames, StructIncludeString)
end

ConfigLoader.Run()
