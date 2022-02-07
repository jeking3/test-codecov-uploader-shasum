$ErrorActionPreference = "Stop"

$scriptPath = split-path $MyInvocation.MyCommand.Path

# Install uploader
Invoke-WebRequest -Headers @{"Cache-Control"="no-cache"} -Uri https://uploader.codecov.io/latest/windows/codecov.exe -Outfile codecov.exe

# Verify integrity
if (Get-Command "gpg.exe" -ErrorAction SilentlyContinue){
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Headers @{"Cache-Control"="no-cache"} -Uri https://keybase.io/codecovsecurity/pgp_keys.asc -OutFile codecov.asc
    Invoke-WebRequest -Headers @{"Cache-Control"="no-cache"} -Uri https://uploader.codecov.io/latest/windows/codecov.exe.SHA256SUM -Outfile codecov.exe.SHA256SUM
    Invoke-WebRequest -Headers @{"Cache-Control"="no-cache"} -Uri https://uploader.codecov.io/latest/windows/codecov.exe.SHA256SUM.sig -Outfile codecov.exe.SHA256SUM.sig

    $ErrorActionPreference = "Continue"
    gpg.exe --import codecov.asc
    if ($LASTEXITCODE -ne 0) { Throw "Importing the key failed." }
    gpg.exe --verify codecov.exe.SHA256SUM.sig codecov.exe.SHA256SUM
    if ($LASTEXITCODE -ne 0) { Throw "Signature validation of the SHASUM failed." }
    $Reference = $(($(certUtil -hashfile .\codecov.exe SHA256)[1], "codecov.exe") -join "  ")
    $Difference = $(Get-Content codecov.exe.SHA256SUM)
    DIR
    echo "Reference:"
    echo "$Reference"
    echo "Difference:"
    echo "$Difference"
    If ($(Compare-Object -ReferenceObject $Reference -DifferenceObject $Difference).length -eq 0) {
        echo "SHASUM verified"
    } Else {
        Throw "SHASUM validation of the codecov binary failed."
    }
}
