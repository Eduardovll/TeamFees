@echo off
if not exist "%USERPROFILE%\.ssh\id_rsa" (
    ssh-keygen -t rsa -b 2048 -f "%USERPROFILE%\.ssh\id_rsa" -N ""
)
type "%USERPROFILE%\.ssh\id_rsa.pub" | ssh administrator@204.12.218.78 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh"
echo Configuracao concluida!
pause
