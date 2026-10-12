# Replace the room on an existing meeting. Saves the change UNSENT; run send-meeting.ps1 after the user confirms.
# Usage: change-room.ps1 -EntryId <id> -NewRoomAddress room901@corp.com
param(
    [Parameter(Mandatory)][string]$EntryId,
    [Parameter(Mandatory)][string]$NewRoomAddress,
    [string]$Mailbox
)
. "$PSScriptRoot\_common.ps1"
$ctx = Get-OutlookContext $Mailbox
$m = Get-ItemById $ctx $EntryId

$removed = @()
for ($i = $m.Recipients.Count; $i -ge 1; $i--) {
    $r = $m.Recipients.Item($i)
    if ($r.Type -eq 3) { $removed += $r.Name; $m.Recipients.Remove($i) }
}
$room = $m.Recipients.Add($NewRoomAddress); $room.Type = 3
if (-not $room.Resolve()) { throw "Room did not resolve: $NewRoomAddress" }
$m.Location = $room.Name
$m.Save()

[pscustomobject]@{
    Start       = $m.Start.ToString('yyyy-MM-dd ddd HH:mm')
    RemovedRoom = $removed -join ', '
    NewRoom     = $room.Name
    Recipients  = (@($m.Recipients) | ForEach-Object Name) -join ', '
    Sent        = 'no - run send-meeting.ps1 to send the update'
    EntryId     = $m.EntryID
}
