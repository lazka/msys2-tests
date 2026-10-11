$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Invoke-Docker {
    & docker @args
    if ($LASTEXITCODE -ne 0) {
        throw "docker failed with exit code ${LASTEXITCODE}: $args"
    }
}

$buildPath = Join-Path $env:RUNNER_TEMP 'msys2-docker'
New-Item -ItemType Directory -Force $buildPath | Out-Null
Copy-Item "$PSScriptRoot/Dockerfile" $buildPath
Invoke-WebRequest `
    -Uri 'https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe' `
    -OutFile "$buildPath/msys2-base-x86_64-latest.sfx.exe"
Invoke-Docker build --tag msys2-tests $buildPath

$container = $env:MSYS2_TEST_CONTAINER
# Keep the container running for the subsequent docker exec calls.
Invoke-Docker run --detach --name $container `
    --env CC --env CXX --env FC `
    msys2-tests powershell -NoProfile -Command 'Start-Sleep -Seconds 2147483'

Invoke-Docker cp "$env:GITHUB_WORKSPACE/." "${container}:C:/msys2-tests"

$bash = 'C:\msys64\usr\bin\bash.exe'
Invoke-Docker exec $container $bash -lc 'true'

& docker exec $container $bash -lc 'pacman --noconfirm -Syuu'
Invoke-Docker exec $container $bash -lc 'pacman --noconfirm -Syuu'
Invoke-Docker exec $container $bash -lc 'sed -i ''1s|^|[staging]\nServer = https://repo.msys2.org/staging/\nSigLevel = Never\n|'' /etc/pacman.conf'
& docker exec $container $bash -lc 'pacman --noconfirm -Syuu'
Invoke-Docker exec $container $bash -lc 'pacman --noconfirm -Syuu'
Invoke-Docker exec --env "MSYS2_TEST_PACKAGES=$env:MSYS2_TEST_PACKAGES" `
    $container $bash -lc 'pacman --noconfirm -S --needed $MSYS2_TEST_PACKAGES'
