require("luasql.mysql")

DBToTsConfig = {}

function DBToTsConfig:__init()
	self.sql_name = "g6_h5_config" --数据库名，需修改
	self.ip = "192.168.0.215"      --项目数据表ip，需修改

	self.user_name = "root"
	self.pass_word = "121212"
	self.port = 4580
	self:CreateConnect()
	return self
end

function DBToTsConfig:CreateConnect()
	self.my_sql = luasql.mysql()
	self.sql_conn = self.my_sql:connect(self.sql_name, self.user_name, self.pass_word, self.ip, self.port)

	--设置数据库的编码格式
	self.sql_conn:execute"SET NAMES UTF8"

	self.file = io.open("C:\\Users\\Administrator\\Desktop\\gameconfig.json","w+")
end

function DBToTsConfig:PrintMysqlTable(lua_table, data_map, data_key, last_section)
	local indent = 0
	local is_section = false
	local last_index = #data_map
	for index, item in ipairs(data_map) do
		local k = item.key
		local v = lua_table[k]
		if data_key[k] and not is_section then
			self.file:write(string.format("		%s:{\n",'"' .. v .. '"'))
			is_section = true
		end

		if type(k) == "string" then
			k = string.format("%q", k) --给字符串加双引号
		end
		local szPrefix = string.rep("    ", indent) --重复indent次
		formatting = szPrefix..k ..": "

		local szValue = ""
		if item.value == "string" then
			if string.find(v, "%[") then
				szValue = v
			else
				szValue = string.format("%q", v)
			end
		else
			szValue = v
		end
		if not szValue then
			print("error:", item.key, v, item.value)
			assert(false)
			return
		end

		if string.find(szValue, "\n") then
			print("It has line break error:", item.key, v, item.value)
			assert(false)
			return
		end

		if string.find(szValue, "<u>") then
			szValue = string.gsub(szValue, "<u>(.+)</u>", function (arg)
				return string.format("<u><on click='onClick'>%s</u>", arg)
			end)
		elseif string.find(szValue, "\\\\%n") then
			szValue = string.gsub(szValue, "\\\\%n", "\\%n")
		else
			szValue = string.gsub(szValue, "'", '"')
		end
		if index == last_index then
			self.file:write(string.format("			%s", formatting..szValue))
		else
			self.file:write(string.format("			%s", formatting..szValue..","))
		end
		self.file:write("\n")
	end

	if is_section then
		if last_section then
			self.file:write("			}\n")
		else
			self.file:write("			},\n\n")
		end
	end
end

function DBToTsConfig:SelectFromSql(table_name, field_fliter, last_index)
	--执行数据库操作
	local cur = self.sql_conn:execute(string.format("select * from %s", table_name))
	if not cur then
		return
	end

	local count = self.sql_conn:execute(string.format("select COUNT(*) from %s", table_name))
	local all_count = tonumber(count:fetch())

	local row = cur:fetch({},"a")

	local field_names = self.sql_conn:execute(string.format("select COLUMN_NAME from information_schema.columns where table_name='%s' and TABLE_SCHEMA='%s'", table_name, self.sql_name))
	local field_types = self.sql_conn:execute(string.format("select COLUMN_TYPE from information_schema.columns where table_name='%s' and TABLE_SCHEMA='%s'", table_name, self.sql_name))
	local field_keys = self.sql_conn:execute(string.format("select COLUMN_KEY from information_schema.columns where table_name='%s' and TABLE_SCHEMA='%s'", table_name, self.sql_name))
	--返回值为游标
	local name_cursor = field_names:fetch() 
	local type_cursor = field_types:fetch()
	local key_cursor = field_keys:fetch()
	local data_map = {}
	local cache_key = {}
	local data_key = {}
	local has_key = false
	local first_field = nil
	while name_cursor do
		if not first_field then
			first_field = name_cursor
		end

		if cache_key[name_cursor] then
			break
		end
		if key_cursor == "PRI" and not data_key[name_cursor] then
			data_key[name_cursor] = true
			has_key = true
		end
		if name_cursor and not field_fliter[name_cursor] then
			string.gsub(type_cursor, "(%a+)", function (arg)
				if not cache_key[name_cursor] then
					if arg == "varchar" or arg == "datetime" then
						table.insert(data_map, {key = name_cursor, value = "string"})
					else
						table.insert(data_map, {key = name_cursor, value = arg})
					end
					cache_key[name_cursor] = true
				end
			end)
		else
			cache_key[name_cursor] = true
		end
		name_cursor = field_names:fetch()
		type_cursor = field_types:fetch()
		key_cursor = field_keys:fetch()
	end

	if not has_key and first_field then
		data_key[first_field] = true
	end

	-- 文件对象的创建
	self.file:write(string.format("	%s:{\n", '"' .. table_name .. '"'))
	-- print(table_name)
	local cur_index = 1
	while row do
	   	self:PrintMysqlTable(row, data_map, data_key, cur_index == all_count)
	    row = cur:fetch(row,"a")
	    cur_index = cur_index + 1
	end

	if last_index then
		self.file:write("	}\n")
	else
		self.file:write("	},\n")
	end
end

function DBToTsConfig:Insert(table_name, value)
	--?
	local cur = self.sql_conn:execute(string.format([[SELECT * from %s where idrole_name_map='%d']], table_name, value))--先判断是否已经插入过改名字的数据
	if cur == 1 then
		print("the data is exist!!")
	else
		cur = self.sql_conn:execute(string.format([[INSERT INTO %s values('%d','%d','%s','%s','%d')]], table_name, 20, 20, "zzb20", "zzb20", 20))
		if cur ~= 1 then
			print("insert fail reason:", cur)
		end
	end
end
--?
function DBToTsConfig:Update(table_name)
	local cur = self.sql_conn:execute(string.format([[UPDATE %s SET role_name ='%s' where idrole_name_map ='%d')]], table_name, "zbb5", 17))
	print(cur)
end

function DBToTsConfig:Delete(table_name, key)
	local cur = self.sql_conn:execute(string.format([[DELETE from %s where idrole_name_map ='%d']], table_name, key))
	print(cur)
end
--定义一张所有表列表
function DBToTsConfig:GetAllTable(table_name)
	local cur = self.sql_conn:execute(string.format("SELECT * from %s", table_name))

	local row = cur:fetch({},"a")

	-- 文件对象的创建
	local tables = {}
	local field_fliter = {}
	while row do
	    table.insert(tables, row.name)
	    if string.len(row.excludes) > 0 then
		    local exclude_list = self:Split(row.excludes, ",")
		    for i,v in ipairs(exclude_list) do
		    	if not field_fliter[row.name] then
		    		field_fliter[row.name] = {}
		    	end
		    	field_fliter[row.name][v] = true
		    end
		end
	    row = cur:fetch(row,"a")
	end
	return tables, field_fliter
end

function DBToTsConfig:Split(str, splite_char)  
	local start_index = 1
	local str_list = {}
	while true do
		local index = string.find(str, splite_char, start_index)
		if not index then
			table.insert(str_list, string.sub(str, start_index, string.len(str)))
			break
		end
		table.insert(str_list, string.sub(str, start_index, index - 1))
		start_index = index + string.len(splite_char)
	end

	return str_list
end

function DBToTsConfig:CloseConnect()
	self.file:close()  --关闭文件对象
	self.sql_conn:close()  --关闭数据库连接
	self.my_sql:close()   --关闭数据库环境
	self.file = nil
	self.sql_conn = nil
	self.my_sql = nil
end

function DBToTsConfig:__delete()
	self:CloseConnect()
	self.sql_name = nil
	self.user_name = nil
	self.pass_word = nil
	self.ip = nil
	self.port = nil
end

print("Please wait for a moment, don't close~~")
local sqlTest = DBToTsConfig:__init()
local tb_list, field_fliter = sqlTest:GetAllTable("__lua_config")
sqlTest.file:write("{\n")
local last_index = #tb_list
for i,v in ipairs(tb_list) do
	sqlTest:SelectFromSql(v, field_fliter[v] or {}, i == last_index)
	if i ~= last_index then
		sqlTest.file:write("\n")
	end
end
sqlTest.file:write("}\n")
print("Configs are finished~~")
sqlTest:__delete()
-- sqlTest:Delete("role_name_map", 20)
-- sqlTest:Update("role_name_map")

