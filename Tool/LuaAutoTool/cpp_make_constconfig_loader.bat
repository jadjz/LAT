@ echo  off
echo "ȷ��Ҫ���ɽű����ļ����ݻᱻ����~~"
set /p flag="ȷ����y����"
if "%flag%"=="y" (
   echo "��ʼ~~"
   lua cpp_make_constconfig_loader.lua
   echo "���~~"
) else (
    echo "�˳�~~"
)
pause
