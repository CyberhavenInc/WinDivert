function FindSignTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string] $WdkRoot,
        [Parameter(Mandatory=$true)] [string] $PlatformName
    )

    # Find signtool.exe.
    $items = Get-ChildItem -Path "${WdkRoot}" -Filter "signtool.exe" -Recurse

    foreach ($item in $items) {
        # Skip any unsupported architectures that may be there (arm).
        if ($item.FullName -like "*${PlatformName}*") {
            $SignTool = $item.FullName
            Write-Host "Found sign tool $SignTool"
            break
        }
    }

    return $SignTool
}

function FindMage {
    $SdkRoot = "C:\Program Files (x86)\Microsoft SDKs\Windows"
    $items = Get-ChildItem -Path "${SdkRoot}" -Filter "mage.exe" -Recurse

    return $items[$items.Length - 1].FullName
}

function IsSigned {
    [CmdletBinding()]
    param($filename)

    return $(get-AuthenticodeSignature $filename).Status -eq "Valid"
}

function IsSignedByCyberhaven {
    [CmdletBinding()]
    param($filename)

    if (-not(IsSigned $filename)) {
        return $false
    }

    return $(get-AuthenticodeSignature $filename).SignerCertificate.Subject.Contains("Cyberhaven, Inc.")
}

function IsCrossSignedByMicrosoft {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $filename,
        [Parameter(Mandatory=$true)] [string] $SignTool
    )


    # We cannot use Get-AuthenticodeSignature here because it only returns the first signature, so we fall back to signtool.exe
    #
    # TODO: Remove the hardcoded path
    # The SDK directory can be retrieved at runtime from VS: $env:WindowsSdkDir is set after dot sourcing "$env:VS140COMNTOOLS\VsDevCmd.bat"
    # However, PowerShell can't dotsource batch files natively.
    # A possible solution is to use Invoke-BatchFile from PowerShell community extensions (http://pscx.codeplex.com/)

    # The /pa argument is necessary when checking non-driver signatures
    $signature = & $SignTool verify /v /ds 1 /pa $filename
    if ($LASTEXITCODE) {
        return $false
    }

    return $signature -Match "Issued to: Microsoft Windows (Hardware|Software) Compatibility Publisher"
}

function IsTestCert() {
    [CmdletBinding()]
    param($cert)

    return ($Env:CYBERHAVENTESTCERTIFICATE -ne $null -and $cert.Subject.Contains($Env:CYBERHAVENTESTCERTIFICATE))
}

function GetTimestampServer {
    return "http://timestamp.digicert.com"
}

function findTestSigningCert {
    if ($Env:CYBERHAVENTESTCERTIFICATE -ne $null) {
        $cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert | Where-Object {$_.Subject.Contains($Env:CYBERHAVENTESTCERTIFICATE)}
    }
    return $cert
}

function findSigningCert {
    $cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert | Where-Object {$_.Subject.Contains("Cyberhaven, Inc.") -and $_.Verify()}
    if ($cert -eq $null) {
        $cert = findTestSigningCert
    }
    return $cert
}

function findTestSigningCertHash {
    $cert = findTestSigningCert
    if ($cert -ne $null) {
        return $cert[0].Thumbprint
    }
    return ""
}

function findSigningCertHash {
    $cert = findSigningCert
    if ($cert -ne $null) {
        return $cert[0].Thumbprint
    }
    return ""
}

# Sign the given file using the Cyberhaven certificate
# Aimed to replicate the following call to signtool:
# "%WindowsSdkDir%\bin\x64\signtool.exe" sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a /n "Cyberhaven, Inc." $filename >nul 2>&1
function Sign {
    [CmdletBinding()]
    param($filename)

    # First we need to locate the certificate
    $cert = findSigningCert

    if (($cert | Measure-Object).Count -ne 1) {
        throw "Exactly one signing certificate is expected, but none or multiple were found"
    }

    # Now use the certificate to sign the binary
    $signature = Set-AuthenticodeSignature -Filepath $filename -Cert $cert -IncludeChain "All" -TimeStampServer (GetTimestampServer) -HashAlgorithm SHA256
    Write-Output $signature

    if (IsTestCert $cert) {
        # Test certificates are not valid, so we don't check the signature status
        return
    }

    if ($signature.Status -ne "Valid") {
        throw "Could not sign $filename"
    }
}

function SignUnsigned {
    [CmdletBinding()]
    param($filename)

    $signed = IsSigned $filename
    $signedByCH = IsSignedByCyberhaven $filename
    if (-not($signed)) {
        Write-Output "Signing $filename"
        Sign $filename
    } elseif ($signedByCH) {
        Write-Output "Not signing $filename (already signed by Cyberhaven)"
    } else {
        Write-Output "Not signing $filename (already signed by another provider)"
    }
}
