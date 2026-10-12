# Check free/busy of people and/or rooms for a time slot on one or more dates.
# Usage:
#   check-availability.ps1 -Dates "2026-10-13,2026-10-14" -Start 10:00 -End 10:30 `
#       -People "a@corp.com,b@corp.com" -Rooms "909,901,812"
# Rooms are short tokens matched against the room list, e.g. "909" -> "...(909)".
# Output: one row per (Date, Kind, Target) with Status free|tentative|busy|oof|elsewhere|unknown|unresolved.
param(
    [Parameter(Mandatory)][string[]]$Dates,
    [Parameter(Mandatory)][string]$Start,
    [Parameter(Mandatory)][string]$End,
    [string[]]$People = @(),
    [string[]]$Rooms = @(),
    [string]$Mailbox
)
. "$PSScriptRoot\_common.ps1"
$ctx = Get-OutlookContext $Mailbox

$targets = @()
foreach ($p in (Split-List $People)) { $targets += [pscustomobject]@{ Kind = 'person'; Label = $p; Address = $p } }
if ($Rooms) {
    $roomEntries = Get-RoomEntries $ctx
    foreach ($t in (Split-List $Rooms)) {
        $hit = @(Find-Room $ctx $t $roomEntries)
        if ($hit.Count -ne 1) {
            $targets += [pscustomobject]@{ Kind = 'room'; Label = $t; Address = $null; Note = "matched $($hit.Count) rooms: $(($hit | ForEach-Object Name) -join '; ')" }
        } else {
            $targets += [pscustomobject]@{ Kind = 'room'; Label = $hit[0].Name; Address = (Get-Smtp $hit[0]) }
        }
    }
}

foreach ($d in (Split-List $Dates)) {
    $day = [datetime]$d
    foreach ($t in $targets) {
        $status = if ($t.Address) { Get-SlotStatus $ctx $t.Address $day $Start $End } else { 'unresolved' }
        [pscustomobject]@{
            Date    = $day.ToString('yyyy-MM-dd ddd')
            Slot    = "$Start-$End"
            Kind    = $t.Kind
            Target  = $t.Label
            Address = $t.Address
            Status  = $status
            Note    = $t.Note
        }
    }
}
