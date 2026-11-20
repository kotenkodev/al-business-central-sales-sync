# Business Central AL Development

This workspace contains an AL extension for Microsoft Dynamics 365 Business Central. It uses Docker for a local Business Central server and VS Code for building and debugging the extension.

## Prerequisites

Install:

- Docker Desktop
- Visual Studio Code
- PowerShell 7 or Windows PowerShell
- [BcContainerHelper](https://www.powershellgallery.com/packages/bccontainerhelper)

Install BcContainerHelper:

```powershell
Install-Module BcContainerHelper -Force
```

## Set up the local Business Central container

On Windows, Docker Desktop must be running.

Select the latest US sandbox artifact and create a credential:

```powershell
$artifactUrl = Get-BcArtifactUrl -type sandbox -country us -select latest
$credential = Get-Credential -UserName admin -Message "Enter the Business Central administrator password"
```

Create the container:

```powershell
New-BcContainer `
  -accept_eula `
  -containerName test `
  -artifactUrl $artifactUrl `
  -auth UserPassword `
  -credential $credential
```

The container is expected to be named `test`. The included VS Code launch configuration uses `http://test/` and server instance `BC`.

Check that the container is running:

```powershell
docker ps --format '{{.Names}}'
```

Open [http://test/BC/?tenant=default](http://test/BC/?tenant=default) and sign in with the username and password used when creating the container.

## Set up the AL extension

Open this repository in VS Code:

```powershell
code .
```

Install the AL Language extension from the included VSIX:

```powershell
code --install-extension .\ALLanguage.vsix --force
```

Restart VS Code if it asks you to do so. Confirm installation:

```powershell
code --list-extensions --show-versions
```

The output should include:

```text
ms-dynamics-smb.al@18.1.2930791
```

The VSIX is local tooling and is ignored by Git.

## Download symbols and build

Open the Command Palette with `Ctrl+Shift+P` and run:

```text
AL: Download Symbols
```

Symbol packages are downloaded into `.alpackages/`, which is ignored by Git.

Build the extension with `Ctrl+Shift+B` or from the Command Palette:

```text
AL: Build
```

A successful build creates:

```text
Default Publisher_win-business-central_1.0.0.0.app
```

That package file is generated output and is ignored by Git.

## Publish and launch the extension

First ensure the `test` container is running:

```powershell
docker start test
```

Then open [`.vscode/launch.json`](.vscode/launch.json) and verify:

- server: `http://test`
- server instance: `BC`
- tenant: `default`
- authentication: `UserPassword`

In VS Code:

1. Press `Ctrl+Shift+P`.
2. Run `AL: Publish` to publish the extension, or press `F5` to publish and launch the debugger.
3. Select the launch configuration named `Your own server` if prompted.
4. Sign in with the container username and password if VS Code requests credentials.

The launch configuration starts page 22, **Customer List**. Opening the page runs [HelloWorld.al](HelloWorld.al), which displays:

```text
App published: Hello world
```

## Stop or remove the environment

Stop and keep the container:

```powershell
docker stop test
```

Start it again:

```powershell
docker start test
```

Remove the container completely:

```powershell
Remove-BcContainer -containerName test
```

Do not commit passwords or credentials. Use `Get-Credential` or VS Code's credential prompt instead.
