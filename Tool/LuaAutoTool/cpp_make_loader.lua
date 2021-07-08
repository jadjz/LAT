local ConfigLoader = {}

function ConfigLoader.LoadConfig()
	local file = io.open("..\\..\\configload\\configload.gmt", "rb")
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

function ConfigLoader.Split()
	local FileName = ""
	local SavePath = ""
	local ClassLoaderName = ""
	local ClassParams = {}
	local args = ConfigLoader.LoadConfig()
	for i,v in ipairs(args) do
		local ret = false
		string.gsub(v, "ClassLoader:(%w+)", function (p)
			ClassLoaderName = p
			ret = true
		end)

		if	not ret then
			string.gsub(v, "FileName:(%w+)", function (p)
				FileName = p
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
			string.gsub(v, "ClassParams:(.*)%W%p", function (p)
				while p do
					local endPos = string.find(p, ",")
					if not endPos then
						table.insert(ClassParams, p)
						break
					end
					local param = string.sub(p, 1, endPos - 1)
					table.insert(ClassParams, param)
					p = string.sub(p, endPos + 1, string.len(p))
				end
			end)
		end
	end
	return SavePath, FileName, ClassLoaderName, ClassParams
end

function ConfigLoader.WriteHead(SavePath, FileName, ClassLoaderName, ClassParams)
	local full_file_name = SavePath .. "\\\\" .. FileName .. ".h"
	local file = io.open(full_file_name, "w+")
	io.output(file)
	--start to write
	ConfigLoader.StartToHead(file, FileName, ClassLoaderName, ClassParams)
	io.close(file)
end

function ConfigLoader.StartToHead(file, FileName, ClassLoaderName, ClassParams)
	file:write(string.format("#ifndef __global_gmt_%s_h__", FileName))
	file:write("\n")
	file:write(string.format("#define __global_gmt_%s_h__", FileName))
	file:write("\n")
	file:write("\n")
	file:write(string.format("#include %s\n", '"' .. "servercommon/gmtrmi/config/configmanager.h" .. '"'))
	for i,v in ipairs(ClassParams) do
		local otherHead = string.format("servercommon/gmtrmi/config/%s.h", v)
		file:write(string.format("#include %s\n", '"' .. otherHead .. '"'))
	end
	file:write("\n")
	file:write("\n")



	file:write("namespace globalserver\n")
	file:write("{\n")
	file:write("	namespace configgmt\n")
	file:write("	{\n")
	file:write(string.format("		class %s: public servercommon::gmtrmi::config::CConfigManagerBase\n", ClassLoaderName))
	file:write("		{\n")
	file:write("		private:\n")
	if #ClassParams == 1 then
		for i,v in ipairs(ClassParams) do
			file:write(string.format("			typedef servercommon::gmtrmi::config::%s::%s config_type;\n", v, v))
			file:write(string.format("			typedef servercommon::gmtrmi::config::%s::Seq%s config_list_type;\n", v, v))
		end
	else
		for i,v in ipairs(ClassParams) do
			file:write(string.format("			typedef servercommon::gmtrmi::config::%s::%s %s_type;\n", v, v, string.lower(v)))
			file:write(string.format("			typedef servercommon::gmtrmi::config::%s::Seq%s %s_list_type;\n", v, v, string.lower(v)))
		end
	end
	file:write("\n\n")


	file:write(string.format("			%s() {}\n", ClassLoaderName))
	file:write(string.format("			~%s() {}\n", ClassLoaderName))
	file:write("\n")

	file:write("		public:\n")
    file:write(string.format("			static %s * instance();\n", ClassLoaderName))

	file:write("			virtual bool loadConfig();\n")
	file:write(string.format("			virtual const std::string getConfigFileName() {return %s;}\n", '"' .. '"'))

	file:write("\n")
	file:write("		private:\n")
	for i,v in ipairs(ClassParams) do
		file:write(string.format("			bool load%s();\n", v))
	end

	file:write("		};\n")
	file:write("	}\n")
	file:write("}\n")
	file:write("\n")
	file:write("#endif\n")

	print("The head file done~~")
end

function ConfigLoader.WriteCpp(SavePath, FileName, ClassLoaderName, ClassParams)
	local full_file_name = SavePath .. "\\\\" .. FileName .. ".cpp"
	local file = io.open(full_file_name, "w+")
	io.output(file)
	--start to write
	ConfigLoader.StartToCpp(file, FileName, ClassLoaderName, ClassParams)
	io.close(file)
	print("The ccp file done~~")
end

function ConfigLoader.StartToCpp(file, FileName, ClassLoaderName, ClassParams)
	file:write(string.format("#include %s\n", '"' .. FileName .. ".h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "gmtconfighelper.h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "servercommon/gmtrmi/msg/constdef.h" .. '"'))
	file:write(string.format("#include %s\n", '"' .. "servercommon/gmtrmi/config/parserhelper.h" .. '"'))
	--file:write(string.format("#include %s\n", '"' .. "servercommon/gmtrmi/operutil.h" .. '"'))
	file:write("\n\n")

	file:write("using namespace servercommon::gmtrmi::msg::constdef;\n")
	file:write("using namespace globalserver::configgmt;\n")
	file:write("\n")

	file:write(string.format("%s * %s::instance()\n", ClassLoaderName, ClassLoaderName))
	file:write("{\n")
	file:write(string.format("	static %s _inst;\n", ClassLoaderName))
	file:write("	return &_inst;\n")
	file:write("}\n\n")

	file:write(string.format("bool %s::loadConfig()\n", ClassLoaderName))
	file:write("{\n")
	if #ClassParams == 1 then
		file:write(string.format("	return load%s();\n", ClassParams[1]))
	else
		local buff = ""
		for i,v in ipairs(ClassParams) do
			if i ~= 1 then
				buff = buff .. " &&\n" .. "		" .. string.format("load%s()", v)
			else
				buff = string.format("load%s()", v)
			end
		end
		file:write(string.format("	return %s;\n", buff))
	end
	file:write("}\n")
	file:write("\n")

	if #ClassParams == 1 then
		file:write(string.format("bool %s::load%s()\n", ClassLoaderName, ClassParams[1]))
		file:write("{\n")
		file:write("	std::string fileName = getAbsDir(config_type::getDefaultFileName());\n")
		file:write("	config_list_type configList;\n")
		file:write(string.format("	if (!servercommon::gmtrmi::config::%s::load(fileName, configList))\n", ClassParams[1]))
		file:write("	{\n")
		local logStr = string.format("[%s::loadRoleConfig] Failed loading config file %s", ClassLoaderName, "%s" .. "\\" .. 'n')
		file:write(string.format("		printf(%s, fileName.c_str());\n", '"' .. logStr .. '"'))
		file:write("		return false;\n")
		file:write("	}\n")
		ConfigLoader.PrintExample(file, ClassParams[1])
		file:write("	return true;\n")
		file:write("}\n")
		file:write("\n")
	else
		for i,v in ipairs(ClassParams) do
			file:write(string.format("bool %s::load%s()\n", ClassLoaderName, v))
			file:write("{\n")
			file:write(string.format("	std::string fileName = getAbsDir(%s_type::getDefaultFileName());\n", string.lower(v)))
			file:write(string.format("	%s_list_type configList;\n", string.lower(v)))
			file:write(string.format("	if (!servercommon::gmtrmi::config::%s::load(fileName, configList))\n", v))
			file:write("	{\n")
			local logStr = string.format("[%s::loadRoleConfig] Failed loading config file %s", ClassLoaderName, "%s".. "\\" .. 'n')
			file:write(string.format("		printf(%s, fileName.c_str());\n", '"' .. logStr .. '"'))
			file:write("		return false;\n")
			file:write("	}\n")
			ConfigLoader.PrintExample(file, v)
			file:write("	return true;\n")
			file:write("}\n")
			file:write("\n")
		end
	end
end

function ConfigLoader.PrintExample(file, param)
	file:write(string.format("	for (servercommon::gmtrmi::config::%s::Seq%s::const_iterator it = configList.begin(); it != configList.end(); ++it)", param, param))
	file:write("\n")
	file:write("	{\n")
	file:write("		//Parse the data by your define,if you done it please delete these code\n")
	file:write("		//Example for parse int list:\n")
	file:write("		//if(!servercommon::CParserHelper::ParseIntList(it->rate,item.rate))\n")
	file:write("		//{\n")
	file:write("			//printf your error log\n")
	file:write("		//}\n")
	file:write("		//Example for parse reward list:\n")
	file:write("		//if (!globalserver::configgmt::CGmtConfigHelper::ParseAndCheckRewards(it->rewards,item.rewards))\n")
	file:write("		//{\n")
	file:write("			//printf your error log\n")
	file:write("		//}\n")
	file:write("	}\n")
end

function ConfigLoader.Run()
	local SavePath, FileName, ClassLoaderName, ClassParams = ConfigLoader.Split()
	ConfigLoader.WriteHead(SavePath, FileName, ClassLoaderName, ClassParams)
	ConfigLoader.WriteCpp(SavePath, FileName, ClassLoaderName, ClassParams)
end

ConfigLoader.Run()
