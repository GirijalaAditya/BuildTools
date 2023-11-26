function Invoke-WithAlt($Command, [string[]]$CommandArgs, $Alt) {
    &$Command $CommandArgs 2> Out-Null
    if (-not $?) {
        return $Alt
    }
}

$git_describe = Invoke-WithAlt -Command 'git' -CommandArgs 'describe' -Alt '0'
$bld_last_tag = Invoke-WithAlt -Command 'git' -CommandArgs 'describe','--abbrev=0' -Alt '0'
$bld_last_commit = (git rev-parse --verify --short HEAD 2> Out-Null)

# base version is <major>.<minor> taken from latest tag.
$bld_base_version = [Regex]::Replace(
    [Regex]::Replace($git_describe, '^v?([0-9]+)(-[0-9]+-.+)?$', '$1.0'),
    '^v?([0-9]+)\.([0-9]+)(-[0-9]+-.+)?$',
    '$1.$2')

# assembly version is done only with <major>.0.0.0 to make assembly compatible between minor versions.
$bld_asm_version = [Regex]::Replace($bld_base_version, '^([0-9]+)(\.[0-9]+)+$', '$1.0.0.0')

$bld_commits_since_tag = [Regex]::Replace($git_describe, '^v?([0-9]+(\.[0-9]+)*)(-([0-9]+)-.+)?$', '$4')
if ([String]::IsNullOrWhiteSpace($bld_commits_since_tag)) {
    # get the number of commits by calculating it from the shortlog summary.
    $bld_commits_since_tag = (git shortlog -s |
        ForEach-Object {
            $_.Split("`t", [System.StringSplitOptions]::RemoveEmptyEntries -bor [System.StringSplitOptions]::TrimEntries)[0]
        } |
        Measure-Object -Sum |
        Select-Object -ExpandProperty Sum)
}

$bld_version = "$bld_base_version.$BUILD_BUILDNUMBER"
$bld_nuget_base_version = "$bld_base_version.$bld_commits_since_tag"
$bld_branch = $BUILD_SOURCEBRANCHNAME
$bld_repo_url = (git remote get-url --all origin)

# Make some more variables available on the agent.
# See https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-in-script
Write-Output "##vso[task.setvariable variable=bld.last_tag]$bld_last_tag"
Write-Output "##vso[task.setvariable variable=bld.last_commit]$bld_last_commit"
Write-Output "##vso[task.setvariable variable=bld.branch]$bld_branch"
Write-Output "##vso[task.setvariable variable=bld.base_version]$bld_base_version"
Write-Output "##vso[task.setvariable variable=bld.version]$bld_version"
Write-Output "##vso[task.setvariable variable=bld.asm_version]$bld_asm_version"
Write-Output "##vso[task.setvariable variable=bld.repo_url]$bld_repo_url"

Write-Output "bld.last_tag.......: $bld_last_tag"
Write-Output "bld.last_commit....: $bld_last_commit"
Write-Output "bld.branch.........: $bld_branch"
Write-Output "bld.base_version...: $bld_base_version"
Write-Output "bld.version........: $bld_version"
Write-Output "bld.asm_version....: $bld_asm_version"
Write-Output "bld.repo_url.......: $bld_repo_url"

# Set the bld.nuget_version variable to indicate the version of the nuget packages we're going to build. Only the master/main
# branches create non-prerelease builds. All other branches should have the branch name appended to the version, which
# automatically marks the package as pre-release in NuGet.
if ($bld_branch -eq "master" -Or $bld_branch -eq "main") {
    $bld_nuget_version = $bld_nuget_base_version

    # For builds of master or main, also set the flavor to release
    Write-Output "##vso[task.setvariable variable=bld.flavor]Release"
    Write-Output "bld.flavor.........: Release"
}
else {
    $bld_nuget_version = "$bld_nuget_base_version-$bld_branch"
}

Write-Output "##vso[task.setvariable variable=bld.nuget_version]$bld_nuget_version"
Write-Output "bld.nuget_version..: $bld_nuget_version"

# Create the build.env file that can later be kept as artifact for releases. Store key/value pairs, but use the key
# as should be propagated in the build system (i.e. with periods at the proper places) rather than normalized for
# a specific shell (e.g. with periods replaced with underscores).
Write-Output "bld.last_tag=$bld_last_tag" > build.env
Write-Output "bld.last_commit=$bld_last_commit" >> build.env
Write-Output "bld.branch=$bld_branch" >> build.env
Write-Output "bld.base_version=$bld_base_version" >> build.env
Write-Output "bld.version=$bld_version" >> build.env
Write-Output "bld.asm_version=$bld_asm_version" >> build.env
Write-Output "bld.repo_url=$bld_repo_url" >> build.env
Write-Output "bld.nuget_version=$bld_nuget_version" >> build.env
