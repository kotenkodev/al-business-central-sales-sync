# Outbound Sales Sync Queue

A headless AL extension for Microsoft Dynamics 365 Business Central, developed in a local Docker environment. The project connects AL fundamentals to sales posting, inventory costing, general ledger entries, and background processing. A small development-only page seeds manual test data in `My Company`; the posting and queue-processing logic requires no custom UI.

The flow is: validate a sync-enabled customer's sales document, post it through standard Business Central, enqueue the posted invoice or credit memo, and process queue entries independently in a batch. The processor validates and marks entries as processed. **No data is sent to an external service yet**; an HTTP integration is outside the four milestones.

## Project status

The data layer, posting subscribers, G/L code propagation, and batch processor are implemented. All six data-layer tests have been reported passing. A manual G/L-account invoice in `My Company` produced a queue entry and was processed successfully; the revenue and VAT entries carried the external sync code. Credit memo behavior, inventory cost/COGS coverage, background execution, and broader permission coverage still need verification. The additional integration tests are included but are not claimed as passing here.

The current manifest names the app `WBC Business Central Sync`, targets application version `29.1.57326.58076` and runtime `18.0`, and reserves object IDs `50200`–`50249`.

## How the extension works

1. Enable `WBC External Sync Enabled` on a customer and provide `WBC External Sync Code`. The code identifies the customer externally; it is different from a document's `External Document No.`. These customer fields have no custom maintenance page. Set them through AL validation, an appropriate import, or a future API. The seed helper configures customer `C0001` when it creates that customer.
2. On actual sales posting, enabled customers require a nonblank external document number and blank Currency Code (local currency). The custom check is skipped during preview; standard BC validation still applies.
3. After an invoice or credit memo is posted, a Pending queue entry captures its posted number, sell-to customer, amount including VAT, and actual cost available at that time. Invoice totals retain their sign; credit memo totals are negated. Cost is the negated sum of matching Value Entries, filtered by document type and number. Later inventory cost adjustments are not automatically resynchronized.
4. The customer code travels through the journal line into G/L entries on the subscribed posting paths. Inventory COGS paths require separate verification.
5. Batch codeunit `50209` processes all Pending entries in the current company. Processor `50208` requires a nonzero amount, an enabled customer with a code, and a G/L entry matching the document number and customer code. Success sets Processed and a timestamp; failure sets Failed and error text. Failed entries are not automatically retried. Processed means validated locally, not delivered externally.

## Manual verification guide

### Prepare My Company

1. Build and publish the current extension, then choose **My Company** in **Settings > My Settings**.
2. Search with `Alt+Q` for **WBC Debug Data** (page `50212`) and choose **Seed Test Data** once. Wait for the success message. The page rejects other company names.
3. The helper creates missing number series `CUST`, `S-INV`, and `S-PINV`; accounts `1200`, `4100`, and `2310`; posting groups/setups; an accounting period if none exists; and sync-enabled customer `C0001` with code `EXT-SYNC-01`.
4. It always changes Sales & Receivables Setup to use those number series. Existing accounts, customers, and posting-group records are preserved rather than repaired. Repeated execution is not prevented. Use this only for your development company.
5. Filter Chart of Accounts by No. `4100`. On its account card, configure Gen. Posting Type = Sale, Gen. Prod. Posting Group = `RETAIL`, and VAT Prod. Posting Group = `VAT20` where supported by your localization. These defaults are not assigned by the seed. Ensure Direct Posting is enabled for this G/L-account exercise.
6. Inspect customer `C0001` with `Ctrl+Alt+F1`: sync should be enabled, the external code populated, and the business posting groups set to `DOMESTIC`. If the customer existed before seeding, verify its configuration explicitly.

VAT controls vary by localization. Tax Area Code and Tax Group Code are not replacements for VAT posting groups. The seed is a minimal exercise setup, not a complete company initialization.

### Post one invoice

1. Open **Sales Invoices > New**, select `C0001`, and leave Currency Code blank.
2. Add a fresh line: Type = G/L Account, No. = `4100`, Quantity = `1`, Unit Price = `100`. Use prices excluding VAT for the example. Selecting the account copies defaults; existing invoice lines do not automatically refresh after account-card changes.
3. Leave External Document No. blank and try posting. Expect the custom required-field error. Resolve unrelated standard setup errors before drawing conclusions about the extension.
4. Enter `MANUAL-001`, run **Preview Posting**, and confirm it creates no persistent queue record.
5. Post and record the actual posted invoice number. Do not assume it is `PSI0000`; numbering depends on existing setup and previous activity.

### Inspect the result

Open these read-only views in the local client and filter by the posted document number:

- [Sync Queue Entry, table 50201](http://test/BC/?tenant=default&company=My%20Company&table=50201)
- [G/L Entry, table 17](http://test/BC/?tenant=default&company=My%20Company&table=17)

Expect exactly one Pending Invoice queue record for `C0001`, a populated creation timestamp, blank processed timestamp/error, and an amount equal to the posted invoice total including VAT. With 20% VAT and a net amount of 100, that total is 120.

Cost Amount is zero for this exercise because a G/L-account line creates no inventory Value Entries. This does not test inventory costing.

Inspect revenue, VAT, and receivables G/L entries individually for `EXT-SYNC-01`. With the example VAT setup, the amounts should be -100, -20, and +120 respectively. The receivables account comes from the customer's posting group and may differ from seeded account `1200` when existing setup is reused.

### Process the queue

1. Search **Job Queue Entries** and create an entry with Object Type to Run = Codeunit, Object ID to Run = `50209`, and Recurring Job = No.
2. Choose **Run once (Foreground)**. This processes every Pending sync entry in the company, not only the invoice just created.
3. Refresh the queue view. Expect Processed, a processing timestamp, and a blank error. If Failed, read the saved Error Message first.
4. Run the batch again. Already Processed records should retain their status and timestamp because only Pending records are selected.

Foreground success does not prove unattended execution. Verify a separately scheduled run when testing background behavior. Further checks include credit memo signs, disabled customers, foreign-currency rejection, inventory costs, and a failed record followed by a valid record in the same batch.

## Automated tests

| Codeunit | Coverage | Requirements / limitations |
|---|---|---|
| `50203 WBC Sync Queue Data Tests` | Six tests for insertion defaults, preserved state, customer validation, and Pending counts | Uses Library - Sales and Assert; six passes reported |
| `50210 WBC Outbound Sync Tests` | Missing external reference, invoice queueing/G/L code, mixed batch outcomes | Uses existing customer and posting setup; not independent of company data; runtime results not yet recorded |

Build and publish, open **AL Test Tool**, add or refresh these test codeunits in a test suite, and run with test isolation enabled. Use a dedicated development/test company: posting and batch code can commit, and the integration helper can modify an existing G/L account's Direct Posting setting. The batch can also pick up pre-existing Pending entries. Do not run this suite against operational data.

The integration tests currently do not cover credit memos, inventory costs, preview persistence, or every G/L posting path. Their G/L assertion checks that at least one matching entry exists. The mixed-batch test creates the valid record before the invalid one; add failure-before-success coverage to verify continuation explicitly. These tests still need refinement to meet the roadmap's library-based, isolated-data requirements.

CodeCop is enabled for this local project; AppSourceCop is deferred because marketplace metadata and ID-range rules do not match this development app. Compilation does not execute tests. Dedicated permission-set coverage and the batch-completion integration event remain outstanding.

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
