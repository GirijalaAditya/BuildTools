param(
    [Parameter(Mandatory = $true)]
    [string] $EnvPath
)

Write-Output "Reading build environment variables from $EnvPath into release environment ..."

Get-Content $EnvPath |
    ForEach-Object {
        $parts = $_.Split('=', 2)
        $name = $parts[0]
        $val = $parts[1]
        Write-Output "##vso[task.setvariable variable=$name]$val"
        Write-Output "$name = $val"
    }
