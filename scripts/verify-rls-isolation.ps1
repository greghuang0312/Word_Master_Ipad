param(
    [string]$UserAEmail = "",
    [string]$UserAPassword = "",
    [string]$UserBEmail = "",
    [string]$UserBPassword = "",
    [string]$EnvFile = ".env",
    [switch]$Cleanup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-EnvFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Env file not found: $Path"
    }

    $map = @{}
    foreach ($line in Get-Content -Path $Path) {
        $text = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($text) -or $text.StartsWith("#")) {
            continue
        }

        $idx = $text.IndexOf("=")
        if ($idx -lt 1) {
            continue
        }

        $key = $text.Substring(0, $idx).Trim()
        $value = $text.Substring($idx + 1).Trim()

        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        if (-not [string]::IsNullOrWhiteSpace($key)) {
            $map[$key] = $value
        }
    }

    return $map
}

function Read-RequiredText {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [string]$Initial = ""
    )

    if (-not [string]::IsNullOrWhiteSpace($Initial)) {
        return $Initial
    }

    while ($true) {
        $value = Read-Host -Prompt $Prompt
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }
}

function Read-RequiredPassword {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [string]$Initial = ""
    )

    if (-not [string]::IsNullOrWhiteSpace($Initial)) {
        return $Initial
    }

    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Login-Supabase {
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $true)][string]$Email,
        [Parameter(Mandatory = $true)][string]$Password
    )

    $body = @{ email = $Email; password = $Password } | ConvertTo-Json -Compress
    $headers = @{
        apikey         = $ApiKey
        "Content-Type" = "application/json"
    }

    $resp = Invoke-RestMethod -Method Post -Uri "$BaseUrl/auth/v1/token?grant_type=password" -Headers $headers -Body $body
    return [PSCustomObject]@{
        Email = $Email
        Token = $resp.access_token
        UserId = $resp.user.id
    }
}

function Insert-TestWord {
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $true)][object]$Session,
        [Parameter(Mandatory = $true)][string]$ZhText,
        [Parameter(Mandatory = $true)][string]$EnWord
    )

    $payload = @(
        @{
            user_id = $Session.UserId
            zh_text = $ZhText
            en_word = $EnWord
            stage = 1
            next_review_date = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
            is_mastered = $false
        }
    ) | ConvertTo-Json -Compress

    $headers = @{
        apikey         = $ApiKey
        Authorization  = "Bearer $($Session.Token)"
        Prefer         = "return=representation"
        "Content-Type" = "application/json"
    }

    $resp = Invoke-RestMethod -Method Post -Uri "$BaseUrl/rest/v1/words" -Headers $headers -Body $payload
    $items = @($resp)
    if ($items.Count -eq 0) {
        throw "Insert words failed for user: $($Session.Email)"
    }

    return $items[0]
}

function Query-OtherUserWordCount {
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $true)][object]$Session,
        [Parameter(Mandatory = $true)][string]$TargetUserId
    )

    $headers = @{
        apikey        = $ApiKey
        Authorization = "Bearer $($Session.Token)"
    }

    $uri = "$BaseUrl/rest/v1/words?select=id,user_id,en_word&user_id=eq.$TargetUserId"
    $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    return @($resp).Count
}

function Remove-WordById {
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $true)][object]$Session,
        [Parameter(Mandatory = $true)][string]$WordId
    )

    $headers = @{
        apikey        = $ApiKey
        Authorization = "Bearer $($Session.Token)"
    }

    Invoke-RestMethod -Method Delete -Uri "$BaseUrl/rest/v1/words?id=eq.$WordId" -Headers $headers | Out-Null
}

$config = Read-EnvFile -Path $EnvFile
$supabaseUrl = $config["SUPABASE_URL"]
$anonKey = $config["SUPABASE_ANON_KEY"]
if ([string]::IsNullOrWhiteSpace($anonKey)) {
    $anonKey = $config["SUPABASE_PUBLISHABLE_KEY"]
}

if ([string]::IsNullOrWhiteSpace($supabaseUrl)) {
    throw "SUPABASE_URL is missing in $EnvFile"
}

if ([string]::IsNullOrWhiteSpace($anonKey)) {
    throw "SUPABASE_ANON_KEY (or SUPABASE_PUBLISHABLE_KEY) is missing in $EnvFile"
}

$UserAEmail = Read-RequiredText -Prompt "User A email" -Initial $UserAEmail
$UserAPassword = Read-RequiredPassword -Prompt "User A password" -Initial $UserAPassword
$UserBEmail = Read-RequiredText -Prompt "User B email" -Initial $UserBEmail
$UserBPassword = Read-RequiredPassword -Prompt "User B password" -Initial $UserBPassword

Write-Host "Logging in test users..."
$sessionA = Login-Supabase -BaseUrl $supabaseUrl -ApiKey $anonKey -Email $UserAEmail -Password $UserAPassword
$sessionB = Login-Supabase -BaseUrl $supabaseUrl -ApiKey $anonKey -Email $UserBEmail -Password $UserBPassword

$suffix = [Guid]::NewGuid().ToString("N").Substring(0, 8)
$aWord = "iso_a_$suffix"
$bWord = "iso_b_$suffix"

Write-Host "Inserting test words..."
$insertedA = Insert-TestWord -BaseUrl $supabaseUrl -ApiKey $anonKey -Session $sessionA -ZhText "隔离测试A" -EnWord $aWord
$insertedB = Insert-TestWord -BaseUrl $supabaseUrl -ApiKey $anonKey -Session $sessionB -ZhText "隔离测试B" -EnWord $bWord

Write-Host "Querying cross-user visibility..."
$aReadBCount = Query-OtherUserWordCount -BaseUrl $supabaseUrl -ApiKey $anonKey -Session $sessionA -TargetUserId $sessionB.UserId
$bReadACount = Query-OtherUserWordCount -BaseUrl $supabaseUrl -ApiKey $anonKey -Session $sessionB -TargetUserId $sessionA.UserId

Write-Host "A reads B count: $aReadBCount"
Write-Host "B reads A count: $bReadACount"

if ($Cleanup.IsPresent) {
    Write-Host "Cleaning up inserted test rows..."
    Remove-WordById -BaseUrl $supabaseUrl -ApiKey $anonKey -Session $sessionA -WordId $insertedA.id
    Remove-WordById -BaseUrl $supabaseUrl -ApiKey $anonKey -Session $sessionB -WordId $insertedB.id
}

if ($aReadBCount -eq 0 -and $bReadACount -eq 0) {
    Write-Host "PASS: RLS isolation is working."
    exit 0
}

Write-Error "FAIL: Cross-user data was visible. Check RLS policies."
exit 1
