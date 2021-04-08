<#
.SYNOPSIS
Collect all visible field names from a Sharepoint List

.DESCRIPTION
Collect all visible field names from a Sharepoint List which are also shown in a library. So no BaseType- or Hidden Names. ID and Title will always be included.

.PARAMETER List
The list to collect the items from. Use output of Get-PnPList for this parameter.

MANDATORY
[Microsoft.SharePoint.Client.SecurableObject]

.EXAMPLE
Connect-PnPOnline -Url $PnPUrl -UseWebLogin
$PnPList = Get-PnPList -Identity $PnPListName
$PnPFields = Get-PnPVisibleFieldNames -List $PnPList

All user relevant field names of the Sharepoint list are now stored in $PnPFields

.NOTES
2021.04.08 ... initial version by Maximilian Otter
#>
function Get-PnPVisibleFieldNames {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Microsoft.SharePoint.Client.SecurableObject]
        $List
    )

    foreach ($pnpfield in ( Get-PnPField -List $List )) {
        if (-not $pnpfield.Hidden -and ( -not $pnpfield.FromBaseType -or $pnpfield.InternalName -eq 'Title' -or $pnpfield.InternalName -eq 'Id')) {
            $pnpfield.InternalName
        }
    }

}

<#
.SYNOPSIS
Collect items of a Sharepoint list and return them as PSCustomObject

.DESCRIPTION
Collect all items of a given Sharepoint list and returns them beautified as regular PSCustomObject instead of the strange hash provided by Sharepoint directly.

.PARAMETER List
The list to collect the items from. Use output of Get-PnPList for this parameter.

MANDATORY
[Microsoft.SharePoint.Client.SecurableObject]

.PARAMETER Fields
The list of fields to process from the list.
Overrules switch -IncludeSystemFields.

[string[]]

.PARAMETER IncludeSystemFields
Will return ALL fields of a Sharepoint list, event those not relevant to the user.
Is overruled by the -Fields parameter.

[switch]

.EXAMPLE
Connect-PnPOnline -Url $PnPUrl -UseWebLogin
$PnPList = Get-PnPList -Identity $PnPListName
Get-PnPListItemAsObject -List $PnPList

Returns the user relevant fields of a Sharepoint list formated as PSCustomObject

.NOTES
2021.04.08 ... initial version by Maximilian Otter
#>
function Get-PnPListItemAsObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [Microsoft.SharePoint.Client.SecurableObject]
        $List,
        [string[]]
        $Fields,
        [switch]
        $IncludeSystemFields
    )

    # Collect all user-relevant fields from list if no specific fields have been specified. Include system fields if requested.
    if ($Fields.count -eq 0) {
        if ($IncludeSystemFields) {
            $Fields = ( Get-PnPField -List $List ).InternalName
        } else {
            $Fields = Get-PnPVisibleFieldNames -List $List
        }
    } else {
        if ($IncludeSystemFields) {
            Write-Warning 'System-Fields will only be included if no specific fields are specified to return!'
        }
        # add the ID field if not specified. always good to have it
        if ($Fields -notcontains 'ID') {
            $Fields = ,'ID' + $Fields
        }
    }

    # loop through the list items and build a return-object from the requested fields
    foreach ($item in ( Get-PnPListItem -List $List )) {
        $hash = [ordered]@{}
        foreach ($field in $Fields) {
            $hash.add($field,$item.fieldvalues.$field)
        }
        [PSCustomObject]$hash
    }

}