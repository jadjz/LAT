@ echo  off
echo "确定要生成脚本，文件内容会被覆盖~~"
set /p flag="确定（y）："
if "%flag%"=="y" (
   echo "开始~~"
   lua cpp_make_constconfig_loader.lua
   echo "完成~~"
) else (
    echo "退出~~"
)
pause
