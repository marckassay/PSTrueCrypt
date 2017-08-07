# these 'Out' functions are here so that we can 'overwrite' it in testing, so that Pester doesn't throw on its script classes.
# assertations are made by examining the parameters being passed into it.
function Out-Error{}

function Out-Information{}

function Out-Verbose{}

function Out-Warning{}


Export-ModuleMember -Function Out-Error, Out-Information, Out-Verbose, Out-Warning