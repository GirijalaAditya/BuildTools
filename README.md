# Build Tools

Holds a set of build related tools/script to assist the Azure DevOps build pipelines. These scripts can be included as submodules
into other git repos to re-use.

## How to use

You can include this git repo as a submodule in any other git repo. You can place it pretty much wherever you want.
For instance, if you wanted the build tools in a directory called `bld` right at the root of your repo, you can add it
by running (at the root of the repo)

```git submodule add "Git URL" bld```

For your build pipelines, you'll need to make sure that submodules are checked out too. Please also verify that your
project's pipelines settings allow access to other projects if you're using the build tools from a different project,
i.e. that the _Limit job authorization scope to current project for non-release pipelines_ setting is off. You can then
call the _Prep-env_ scripts in a corresponding *script* build step.

| OS | Prep-env Script Path | Script Host |
| --- | --- | --- |
| Linux | `bld/linux/prep-env.sh` | Bash |
| Windows | `bld/windows/prep-env.ps1` | PowerShell |

In your source repository, create annotated tag(s) for major/minor releases and name them `vX.Y` or just `X.Y`, and the build scripts
will create the environment variables listed below for you automatically, so you can use them e.g. to version NuGet
package releases or container images. The _Prep-env_ scripts will produce a new file called `build.env`. If you want to
use this file later, you should include it in your artifacts or pass it through other means to subsequent stages / jobs
/ pipelines.

The _Prep-release_ scripts can then be used to load all these environment variables, e.g. to select the proper container
image that you built. In case you want to use the script in a release pipeline, you might want to include it in the build's
artifacts such that you don't need to check-out the sources again, and such that you have the version of the scripts
used at build time.

| OS | Prep-release Script Path | Script Host |
| --- | --- | --- |
| Linux | `bld/linux/prep-release.sh` | Bash |
| Windows | `bld/windows/prep-release.ps1` | PowerShell |

## _Prep-Env_ Scripts (`prep-env.sh` | `prep-env.ps1`)

Prepares the build environment by setting useful environment variables for consumption by build pipeline steps.
Environment variables are as follows:

|Env Var            |Description|Example|
|-------------------|-----------|-------|
|bld.last_tag       |The last git tag that's in the current history. If no tags are present, defaults to `0`.|`1.2`|
|bld.last_commit    |The (short) hash of the last commit that's built.|`f5a6335`|
|bld.branch         |The branch that's being built.|`dev`|
|bld.base_version   |The base version (major and minor) as derived from the last tag.|`1.2`|
|bld.version        |The full version (major and minor, build and revision). It's made up from the `bld.base_version` and the build's `BUILDNUMBER`.|`1.2.20210706.15`|
|bld.asm_version    |The version string to use for .Net assemblies. To make different minor/revision versions compatible amongst each other, this is just the major version followed by all zeroes.|`1.0.0.0`|
|bld.repo_url       |The URL of the repository that's being built.|`Git URL`|
|bld.nuget_version  |The version to use for NuGet packages, based on the last tag and the branch. All branches other than 'master' result in a suffix of the branch name, thus marking them pre-release in NuGet.|`1.2.15-dev`|

These environment variables are stored into a newly generated file called `build.env`.

In addition, if the build is for the `master` branch, the `bld.flavor` environment variable is set to `Release`. You can
use this e.g. to assure that builds that will be release to production are always of the `Release` flavor.

## _Prep-Release_ Scripts (`prep-release.sh` | `prep-release.ps`)

Prepares the release environment by loading environment variables from a file with `<key>=<value>` pairs per line, as
generated e.g. by the _Prep-env_ scripts. Requires the path to the file to load environment variables from as the only
parameter to the script. For example, to load environment variables on Linux from `./build.env` in the artifact `BuildMeta`
which also has the script at `./bld/linux/prep-release.sh`:

```bash
$SYSTEM_DEFAULTWORKINGDIRECTORY/_MyService/BuildMeta/bld/linux/prep-release.sh $SYSTEM_DEFAULTWORKINGDIRECTORY/_MyService/BuildMeta/build.env
```

For more information on how to _use_ the variables, see the [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#environment-variables).

## Directory `linux`

Holds tools/scripts related to building on Linux agents.

## Directory `windows`

Holds tools/scripts related to building on Windows agents.
