@ echo  off
echo "ȷ��Ҫ���ɽű����ļ����ݻᱻ����~~"
set /p flag="ȷ����y����"
if "%flag%"=="y" (
   echo "��ʼ~~"
   lua lua_make_script.lua
   echo "���~~"
) else (
    echo "�˳�~~"
)
pause