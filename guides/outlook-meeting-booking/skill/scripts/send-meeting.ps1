# Send a meeting request (or update) by EntryId. Only run after the user explicitly says to send.
# Usage: send-meeting.ps1 -EntryId "<id1>,<id2>"
param(
    [Parameter(Mandatory)][string[]]$EntryId,
    [string]$Mailbox
)
. "$PSScriptRoot\_common.ps1"
$ctx = Get-OutlookContext $Mailbox

foreach ($id in (Split-List $EntryId)) {
    $m = Get-ItemById $ctx $id
    if (-not $m.Recipients.ResolveAll()) {
        [pscustomobject]@{ Start = $m.Start.ToString('yyyy-MM-dd ddd HH:mm'); Location = $m.Location; Result = 'NOT SENT: unresolved recipients' }
        continue
    }
    $m.Send()
    [pscustomobject]@{ Start = $m.Start.ToString('yyyy-MM-dd ddd HH:mm'); Location = $m.Location; Result = 'sent' }
}
