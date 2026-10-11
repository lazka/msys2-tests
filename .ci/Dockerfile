FROM mcr.microsoft.com/windows/servercore:ltsc2022

COPY msys2-base-x86_64-latest.sfx.exe C:/msys2.exe

SHELL ["powershell", "-NoProfile", "-Command"]

RUN $ErrorActionPreference = 'Stop'; \
  & C:\msys2.exe -y -oC:\; \
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; \
  Remove-Item C:\msys2.exe; \
  New-Item -ItemType Directory C:\ci, C:\msys2-tests | Out-Null

ENV MSYSTEM=MSYS CHERE_INVOKING=1
