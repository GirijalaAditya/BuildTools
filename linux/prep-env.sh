#!/bin/bash

git_describe=$(git describe 2> /dev/null || echo '0')
bld_last_tag=$(git describe --abbrev=0 2> /dev/null || echo '0')
bld_last_commit=$(git rev-parse --verify --short HEAD)

# base version is <major>.<minor> taken from latest tag.
bld_base_version=$(echo $git_describe | \
    sed -r 's/^v?([0-9]+)(-[0-9]+-.+)?$/\1.0/' | \
    sed -r 's/^v?([0-9]+)\.([0-9]+)(-[0-9]+-.+)?$/\1.\2/')

# assembly version is done only with <major>.0.0.0 to make assembly compatible between minor versions.
bld_asm_version=$(echo $bld_base_version | \
    sed -r 's/^([0-9]+)(\.[0-9]+)+$/\1.0.0.0/')

bld_commits_since_tag=$(echo $git_describe | sed -r 's/^v?([0-9]+(\.[0-9]+)*)(-([0-9]+)-.+)?$/\4/')
if [ "$bld_commits_since_tag" = "" ]; then
    # get the number of commits by calculating it from the shortlog summary.
    bld_commits_since_tag=$(git shortlog -s | awk '{ print $1 }' | awk '{ SUM += $1 } END { print SUM }')
fi

bld_version=$bld_base_version.$BUILD_BUILDNUMBER
bld_nuget_base_version=$bld_base_version.$bld_commits_since_tag
bld_branch=$BUILD_SOURCEBRANCHNAME
bld_repo_url=$(git remote get-url --all origin)

# Make some more variables available on the agent.
# See https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-in-script
echo "##vso[task.setvariable variable=bld.last_tag]$bld_last_tag"
echo "##vso[task.setvariable variable=bld.last_commit]$bld_last_commit"
echo "##vso[task.setvariable variable=bld.branch]$bld_branch"
echo "##vso[task.setvariable variable=bld.base_version]$bld_base_version"
echo "##vso[task.setvariable variable=bld.version]$bld_version"
echo "##vso[task.setvariable variable=bld.asm_version]$bld_asm_version"
echo "##vso[task.setvariable variable=bld.repo_url]$bld_repo_url"

echo bld.last_tag.......: $bld_last_tag
echo bld.last_commit....: $bld_last_commit
echo bld.branch.........: $bld_branch
echo bld.base_version...: $bld_base_version
echo bld.version........: $bld_version
echo bld.asm_version....: $bld_asm_version
echo bld.repo_url.......: $bld_repo_url

# Set the bld.nuget_version variable to indicate the version of the nuget packages we're going to build. Only the master/main
# branches create non-prerelease builds. All other branches should have the branch name appended to the version, which
# automatically marks the package as pre-release in NuGet.
if [ "$bld_branch" = "master" ] || [ "$bld_branch" = "main" ]; then
    bld_nuget_version=$bld_nuget_base_version

    # For builds of master or main, also set the flavor to release
    echo "##vso[task.setvariable variable=bld.flavor]Release"
    echo bld.flavor.........: Release
else
    bld_nuget_version=$bld_nuget_base_version-$bld_branch
fi

echo "##vso[task.setvariable variable=bld.nuget_version]$bld_nuget_version"
echo bld.nuget_version..: $bld_nuget_version

# Create the build.env file that can later be kept as artifact for releases. Store key/value pairs, but use the key
# as should be propagated in the build system (i.e. with periods at the proper places) rather than normalized for
# a specific shell (e.g. with periods replaced with underscores).
echo "bld.last_tag=$bld_last_tag" > build.env
echo "bld.last_commit=$bld_last_commit" >> build.env
echo "bld.branch=$bld_branch" >> build.env
echo "bld.base_version=$bld_base_version" >> build.env
echo "bld.version=$bld_version" >> build.env
echo "bld.asm_version=$bld_asm_version" >> build.env
echo "bld.repo_url=$bld_repo_url" >> build.env
echo "bld.nuget_version=$bld_nuget_version" >> build.env
