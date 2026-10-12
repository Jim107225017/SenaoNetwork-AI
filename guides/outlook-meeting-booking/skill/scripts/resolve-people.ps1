# Resolve attendee names / emails to Exchange addresses.
# Usage: resolve-people.ps1 -Names "Name1,Name2,someone@corp.com"
param(
    [Parameter(Mandatory)][string[]]$Names,
    [string]$Mailbox
)
. "$PSScriptRoot\_common.ps1"
$ctx = Get-OutlookContext $Mailbox
$gal = $null

foreach ($q in (Split-List $Names)) {
    $r = $ctx.NS.CreateRecipient($q)
    if ($r.Resolve()) {
        [pscustomobject]@{ Query = $q; Status = 'ok'; Name = $r.AddressEntry.Name; Smtp = (Get-Smtp $r.AddressEntry) }
        continue
    }
    # Direct resolve fails for Chinese names or ambiguous matches; scan the largest address list.
    if (-not $gal) { $gal = @($ctx.NS.AddressLists) | Sort-Object { $_.AddressEntries.Count } -Descending | Select-Object -First 1 }
    $pattern = [regex]::Escape($q)
    $hits = @(foreach ($e in $gal.AddressEntries) { if ($e.Name -match $pattern) { $e } })
    if ($hits.Count -eq 1) {
        [pscustomobject]@{ Query = $q; Status = 'ok'; Name = $hits[0].Name; Smtp = (Get-Smtp $hits[0]) }
    } elseif ($hits.Count -gt 1) {
        foreach ($h in $hits) { [pscustomobject]@{ Query = $q; Status = 'ambiguous'; Name = $h.Name; Smtp = (Get-Smtp $h) } }
    } else {
        [pscustomobject]@{ Query = $q; Status = 'not-found'; Name = ''; Smtp = '' }
    }
}
