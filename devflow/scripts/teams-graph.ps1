<#
  devflow helper for the Teams notifier in mode `graph` (Microsoft Graph, delegated, as the signed-in user).
  Needs the module Microsoft.Graph.Authentication and a prior `Connect-MgGraph -Scopes <devflow scopes>`.
  Works in Windows PowerShell 5.1 and pwsh 7+. Output is JSON on stdout; errors go to stderr with exit code 1.

  -Action check                       signed in, scopes present, GET /me works
  -Action resolve  -Email <email>     Entra user id / display name for an email (UPN, then mail)
  -Action teams                       teams the user joined
  -Action channels -TeamId <id>       channels of a team
  -Action send     -PayloadFile <f>   send the card described in a JSON file:
      { "target": "dm" | "channel",
        "userId": "<recipient id>", "userName": "<display name>",   # dm: recipient; channel: person to @mention
        "teamId": "...", "channelId": "...",                        # channel only
        "card": { ...Adaptive Card... }, "summary": "<notification preview text>" }
#>
param(
  [Parameter(Mandatory)] [ValidateSet('check', 'resolve', 'teams', 'channels', 'send')] [string] $Action,
  [string] $Email,
  [string] $TeamId,
  [string] $PayloadFile
)

$ErrorActionPreference = 'Stop'
$Scopes = @('Chat.Create', 'ChatMessage.Send', 'User.ReadBasic.All', 'ChannelMessage.Send', 'Team.ReadBasic.All', 'Channel.ReadBasic.All')
$Graph = 'https://graph.microsoft.com/v1.0'

function Out-Json($Object) { $Object | ConvertTo-Json -Depth 20 -Compress }
function Fail($Message) { [Console]::Error.WriteLine($Message); exit 1 }

if (-not (Get-Module -ListAvailable Microsoft.Graph.Authentication)) { Fail 'module Microsoft.Graph.Authentication is not installed' }
Import-Module Microsoft.Graph.Authentication

$context = Get-MgContext
if (-not $context) { Fail 'not signed in: run Connect-MgGraph -Scopes ' + ($Scopes -join ',') }
$missing = @($Scopes | Where-Object { $context.Scopes -notcontains $_ })
if ($missing.Count -gt 0) { Fail ('signed in without scopes: ' + ($missing -join ', ') + ' - run Connect-MgGraph again with all devflow scopes') }

function Invoke-Graph($Method, $Path, $Body) {
  try {
    if ($Body) { Invoke-MgGraphRequest -Method $Method -Uri "$Graph$Path" -Body (Out-Json $Body) -ContentType 'application/json; charset=utf-8' -OutputType PSObject }
    else { Invoke-MgGraphRequest -Method $Method -Uri "$Graph$Path" -OutputType PSObject }
  } catch { Fail ("Graph $Method $Path failed: " + $_.Exception.Message) }
}

switch ($Action) {
  'check' {
    $me = Invoke-Graph GET '/me?$select=id,displayName,userPrincipalName'
    Out-Json @{ ok = $true; account = $context.Account; id = $me.id; displayName = $me.displayName; scopes = $Scopes }
  }
  'resolve' {
    if (-not $Email) { Fail '-Email is required' }
    $user = $null
    try { $user = Invoke-MgGraphRequest -Method GET -Uri "$Graph/users/$([uri]::EscapeDataString($Email))?`$select=id,displayName,userPrincipalName,mail" -OutputType PSObject } catch { }
    if (-not $user) {
      $found = Invoke-Graph GET ("/users?`$filter=mail eq '" + $Email.Replace("'", "''") + "'&`$select=id,displayName,userPrincipalName,mail")
      $user = @($found.value)[0]
    }
    if (-not $user) { Fail "no Entra user found for $Email" }
    Out-Json @{ id = $user.id; displayName = $user.displayName; userPrincipalName = $user.userPrincipalName }
  }
  'teams' {
    Out-Json @((Invoke-Graph GET '/me/joinedTeams?$select=id,displayName').value | ForEach-Object { @{ id = $_.id; displayName = $_.displayName } })
  }
  'channels' {
    if (-not $TeamId) { Fail '-TeamId is required' }
    Out-Json @((Invoke-Graph GET "/teams/$TeamId/channels?`$select=id,displayName").value | ForEach-Object { @{ id = $_.id; displayName = $_.displayName } })
  }
  'send' {
    if (-not $PayloadFile -or -not (Test-Path $PayloadFile)) { Fail '-PayloadFile is required' }
    $p = Get-Content -Raw -Encoding UTF8 $PayloadFile | ConvertFrom-Json
    $attachmentId = [guid]::NewGuid().ToString()
    $attachment = @{ id = $attachmentId; contentType = 'application/vnd.microsoft.card.adaptive'; content = (Out-Json $p.card) }
    $safeName = [System.Net.WebUtility]::HtmlEncode($p.userName)

    if ($p.target -eq 'dm') {
      $me = Invoke-Graph GET '/me?$select=id'
      $member = { param($id) @{ '@odata.type' = '#microsoft.graph.aadUserConversationMember'; roles = @('owner'); 'user@odata.bind' = "$Graph/users('$id')" } }
      # oneOnOne chats are unique per pair: this returns the existing chat when there is one
      $chat = Invoke-Graph POST '/chats' @{ chatType = 'oneOnOne'; members = @((& $member $me.id), (& $member $p.userId)) }
      $message = @{ body = @{ contentType = 'html'; content = "<attachment id=`"$attachmentId`"></attachment>" }; attachments = @($attachment); summary = $p.summary }
      $sent = Invoke-Graph POST "/chats/$($chat.id)/messages" $message
      Out-Json @{ ok = $true; target = 'dm'; chatId = $chat.id; messageId = $sent.id; webUrl = $sent.webUrl }
    }
    elseif ($p.target -eq 'channel') {
      $message = @{
        body        = @{ contentType = 'html'; content = "<at id=`"0`">$safeName</at> <attachment id=`"$attachmentId`"></attachment>" }
        mentions    = @(@{ id = 0; mentionText = $p.userName; mentioned = @{ user = @{ id = $p.userId; displayName = $p.userName; userIdentityType = 'aadUser' } } })
        attachments = @($attachment)
        summary     = $p.summary
      }
      $sent = Invoke-Graph POST "/teams/$($p.teamId)/channels/$($p.channelId)/messages" $message
      Out-Json @{ ok = $true; target = 'channel'; messageId = $sent.id; webUrl = $sent.webUrl }
    }
    else { Fail "target must be dm or channel, got '$($p.target)'" }
  }
}
