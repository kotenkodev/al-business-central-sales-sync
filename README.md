# Outbound Sales Sync Queue

A planned zero-UI (headless) AL extension for Microsoft Dynamics 365 Business Central, developed in a local Docker environment with CRONUS sample data. The project connects AL fundamentals to sales posting, inventory costing, general ledger entries, and background processing.

The intended flow is: validate a sync-enabled customer's sales document, post it through standard Business Central, enqueue the posted invoice or credit memo, and process queue entries independently in a background batch. The processor will initially validate and mark entries as processed; an external HTTP integration is outside the four milestones.

## Project status

Planning and local environment setup. The milestones below describe intended functionality, not completed features. Milestone 1 is the current learning task.

The current manifest names the app `WBC Business Central Sync`, targets application version `29.1.57326.58076` and runtime `18.0`, and reserves object IDs `50200`–`50249`.

## Learning workflow

- Write the AL implementation yourself; mentoring provides requirements, acceptance criteria, exploration hints, and code reviews rather than complete solutions.
- Complete and review each milestone before starting the next.
- Explore the installed Base App symbols with `Ctrl+T` and `F12`; verify event signatures against the local version before subscribing.
- Explain the ERP behavior behind the code: posted documents and ledgers, cost relationships, and transaction rollback.
- Review applicable use of `SetLoadFields`, secondary keys, `DataClassification`, `GuiAllowed()`, indirect permissions, CodeCop, and AppSourceCop.
- Keep the extension headless: no custom pages or page extensions are required.

## Roadmap

### Milestone 1 — Data layer and triggers

- [x] Create enum `Sync Queue Status`: Pending, Processed, Failed.
- [x] Create table `Sync Queue Entry` with an auto-incrementing entry number, document type/number, customer number, amount, cost amount, status, created/processed timestamps, and error message.
- [x] Add secondary keys for status-based processing and customer/status filtering.
- [x] Default Status to Pending with `InitValue`; in `OnInsert`, populate the creation timestamp only when blank. Preserve explicitly supplied status, timestamps, and error details.
- [x] Extend `Customer` with `External Sync Enabled` and `External Sync Code` (`Code[20]`).
- [x] Validate that a nonblank sync code requires sync to be enabled; prevent disabling sync until the code is cleared. Enabling with a blank code is allowed at this stage.
- [x] Add a non-editable `Pending Sync Count` FlowField counting this customer's Pending queue entries.
- [x] Add captions, data classifications, and the customer table relation.

Acceptance: objects compile; insertion with triggers enabled initializes the entry correctly; cross-field validation works in both directions; calculating the FlowField excludes other customers and non-Pending entries and reflects status changes. No UI calls are introduced.

Milestone 1 checks are in `tests/WBCSyncQueueDataTests.Codeunit.al` (codeunit 50203). Run through a Business Central test runner with test isolation enabled so database changes are rolled back. These tests use generated customers, require the declared test-library dependencies, and do not require custom pages. Building compiles the tests but does not execute them.

### Milestone 2 — Standard posting and G/L event hooks

- [ ] Subscribe to codeunit 80 `Sales-Post` to require `External Document No.` for sync-enabled customers before posting, skipping this custom check in preview mode.
- [ ] Enqueue posted sales invoices and credit memos after posting, using the posted document identifiers.
- [ ] Calculate actual cost from the relevant `Value Entry` records.
- [ ] Extend the required posting records and propagate `External Sync Code` to `G/L Entry` through the journal posting pipeline.
- [ ] Inspect `OnBeforePostSalesDoc`, `OnAfterPostSalesDoc`, and the available journal/G/L initialization publishers, including `OnAfterInitGenJnlLine` and `OnAfterInitGLEntry`; confirm their owning objects, signatures, and execution paths in the installed symbols.

Acceptance: qualifying invoices and credit memos produce correct queue records; the missing-reference rule blocks actual posting; preview creates no persistent queue records; the sync code reaches the relevant G/L entries.

Learning focus: how source documents become posted documents, how Value Entries relate to Item Ledger Entries and G/L Entries, and why posting and queue insertion must respect the same transaction boundary.

### Milestone 3 — Headless batch processing and transaction isolation

- [ ] Create a single-entry processor codeunit with `TableNo = "Sync Queue Entry"`; validate data, raise an error for invalid entries, and mark successful entries Processed.
- [ ] Create a batch runner with `TableNo = "Job Queue Entry"` using `SetLoadFields` and `FindSet`.
- [ ] Use the Boolean result of `Processor.Run(Rec)` to isolate each entry's failure; establish the required transaction boundaries before invoking it.
- [ ] Capture `GetLastErrorText()` after failure and persist Failed status and error details without aborting the remaining batch.
- [ ] Guard any optional UI calls with `GuiAllowed()` and publish a custom integration event after batch completion.

Acceptance: a batch containing valid and invalid entries processes the valid entries, rolls back failed processing work, and retains failure details. Background execution requires no user interaction.

### Milestone 4 — Permissions and headless automated tests

- [ ] Create a permission set and apply appropriate indirect `TableData` permissions to subscriber and processor codeunits.
- [ ] Use `Library - Sales`, `Library - Inventory`, and `Assert` to create test data without hardcoded master data IDs.
- [ ] Test invoice and credit memo queueing and the customer Pending count.
- [ ] Test validation blocking with `asserterror`.
- [ ] Test per-record batch failure isolation and persisted error details.
- [ ] Test G/L sync-code propagation.
- [ ] Add a `MessageHandler` test for an optional GUI-allowed message path while retaining headless batch behavior.

Acceptance: automated tests cover the posting and batch flows, required permissions are documented and verified, and applicable analyzer findings are reviewed.

## Local development environment

The setup below uses Docker for a local Business Central server and VS Code for building and debugging the extension.

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
Default Publisher_WBC Business Central Sync_1.0.0.0.app
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

The development launch configuration does not open a startup page; the planned extension does not require a startup page.

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
