codeunit 50210 "WBC Outbound Sync Tests"
{
    Subtype = Test;

    var
        AssertErr: Label 'Expected %1 to equal %2, but got %3.', Comment = '%1 = Field, %2 = Expected, %3 = Actual';

    [Test]
    procedure TestPostingBlockedWhenExternalDocNoMissing()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSyncCustomer(Customer, true, 'SYNC-01');
        CreateSalesInvoice(SalesHeader, SalesLine, Customer."No.", '');

        asserterror Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        if StrPos(GetLastErrorText(), SalesHeader.FieldCaption("External Document No.")) = 0 then
            Error('Unexpected error: %1', GetLastErrorText());
    end;

    [Test]
    procedure TestPostingQueuesInvoiceAndPropagatesSyncCodeToGL()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SyncQueueEntry: Record "WBC Sync Queue Entry";
        GLEntry: Record "G/L Entry";
        PostedInvNo: Code[20];
    begin
        CreateSyncCustomer(Customer, true, 'SYNC-99');
        CreateSalesInvoice(SalesHeader, SalesLine, Customer."No.", 'EXT-INV-100');

        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        SyncQueueEntry.SetRange("Customer No.", Customer."No.");
        SyncQueueEntry.FindLast();
        PostedInvNo := SyncQueueEntry."Document No.";

        if SyncQueueEntry."Document Type" <> SyncQueueEntry."Document Type"::Invoice then
            Error(AssertErr, 'Document Type', SyncQueueEntry."Document Type"::Invoice, SyncQueueEntry."Document Type");
        if SyncQueueEntry.Status <> SyncQueueEntry.Status::Pending then
            Error(AssertErr, 'Status', SyncQueueEntry.Status::Pending, SyncQueueEntry.Status);
        if SyncQueueEntry.Amount <= 0 then
            Error('Expected positive Amount, got %1', SyncQueueEntry.Amount);

        GLEntry.SetRange("Document No.", PostedInvNo);
        GLEntry.SetRange("WBC External Sync Code", 'SYNC-99');
        if GLEntry.IsEmpty() then
            Error('Expected G/L Entries for invoice %1 to have External Sync Code SYNC-99.', PostedInvNo);
    end;

    [Test]
    procedure TestPreviewPostingDoesNotQueueDocument()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        SyncQueueEntry: Record "WBC Sync Queue Entry";
        EntriesBeforePreview: Integer;
    begin
        CreateSyncCustomer(Customer, true, 'SYNC-PREVIEW');
        CreateSalesInvoice(SalesHeader, SalesLine, Customer."No.", 'EXT-PREVIEW-1');
        SyncQueueEntry.SetRange("Customer No.", Customer."No.");
        EntriesBeforePreview := SyncQueueEntry.Count();

        SalesPost.SetPreviewMode(true);
        asserterror SalesPost.Run(SalesHeader);
        if StrPos(GetLastErrorText(), 'Preview mode.') = 0 then
            Error('Unexpected preview error: %1', GetLastErrorText());

        if SyncQueueEntry.Count() <> EntriesBeforePreview then
            Error('Preview posting must not create a sync queue entry.');
    end;

    [Test]
    procedure TestPostingQueuesCreditMemoWithNegativeAmount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SyncQueueEntry: Record "WBC Sync Queue Entry";
    begin
        CreateSyncCustomer(Customer, true, 'SYNC-CM');
        CreateSalesDocument(SalesHeader, SalesLine, Customer."No.", 'EXT-CM-100', SalesHeader."Document Type"::"Credit Memo");

        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        SyncQueueEntry.SetRange("Customer No.", Customer."No.");
        SyncQueueEntry.FindLast();
        if SyncQueueEntry."Document Type" <> SyncQueueEntry."Document Type"::"Credit Memo" then
            Error(AssertErr, 'Document Type', SyncQueueEntry."Document Type"::"Credit Memo", SyncQueueEntry."Document Type");
        if SyncQueueEntry.Amount >= 0 then
            Error('Expected negative credit memo Amount, got %1', SyncQueueEntry.Amount);
    end;

    [Test]
    procedure TestBatchRunnerIsolatesFailures()
    var
        ValidCust: Record Customer;
        DisabledCust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValidQueueEntry: Record "WBC Sync Queue Entry";
        FailedQueueEntry: Record "WBC Sync Queue Entry";
        JobQueueEntry: Record "Job Queue Entry";
        BatchRunner: Codeunit "WBC Sync Queue Batch Runner";
    begin
        CreateSyncCustomer(DisabledCust, false, '');
        FailedQueueEntry.Init();
        FailedQueueEntry."Document Type" := FailedQueueEntry."Document Type"::Invoice;
        FailedQueueEntry."Document No." := 'BAD-DOC-001';
        FailedQueueEntry."Customer No." := DisabledCust."No.";
        FailedQueueEntry.Amount := 100;
        FailedQueueEntry.Insert(true);

        CreateSyncCustomer(ValidCust, true, 'SYNC-OK');
        CreateSalesInvoice(SalesHeader, SalesLine, ValidCust."No.", 'EXT-OK-1');
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        ValidQueueEntry.SetRange("Customer No.", ValidCust."No.");
        ValidQueueEntry.FindLast();

        BatchRunner.Run(JobQueueEntry);

        ValidQueueEntry.Find();
        if ValidQueueEntry.Status <> ValidQueueEntry.Status::Processed then
            Error(AssertErr, 'ValidQueueEntry.Status', ValidQueueEntry.Status::Processed, ValidQueueEntry.Status);

        FailedQueueEntry.Find();
        if FailedQueueEntry.Status <> FailedQueueEntry.Status::Failed then
            Error(AssertErr, 'FailedQueueEntry.Status', FailedQueueEntry.Status::Failed, FailedQueueEntry.Status);
        if FailedQueueEntry."Error Message" = '' then
            Error('Expected FailedQueueEntry."Error Message" to be populated.');
    end;

    local procedure CreateSyncCustomer(var Customer: Record Customer; SyncEnabled: Boolean; SyncCode: Code[20])
    var
        ExistingCust: Record Customer;
    begin
        ExistingCust.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        ExistingCust.SetFilter("Customer Posting Group", '<>%1', '');
        ExistingCust.SetRange(Blocked, ExistingCust.Blocked::" ");
        ExistingCust.FindFirst();

        Customer := ExistingCust;
        Customer."No." := '';
        Customer."WBC External Sync Enabled" := SyncEnabled;
        Customer."WBC External Sync Code" := SyncCode;
        Customer.Insert(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustNo: Code[20]; ExtDocNo: Code[35])
    begin
        CreateSalesDocument(SalesHeader, SalesLine, CustNo, ExtDocNo, SalesHeader."Document Type"::Invoice);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustNo: Code[20]; ExtDocNo: Code[35]; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        Customer.Get(CustNo);

        GenPostingSetup.SetRange("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
        GenPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GenPostingSetup.SetFilter("Sales Account", '<>%1', '');
        GenPostingSetup.FindFirst();

        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        VATPostingSetup.SetRange(Blocked, false);
        VATPostingSetup.FindFirst();

        GLAccount.Get(GenPostingSetup."Sales Account");
        if not GLAccount."Direct Posting" then begin
            GLAccount."Direct Posting" := true;
            GLAccount.Modify();
        end;

        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader."External Document No." := ExtDocNo;
        SalesHeader.Modify(true);

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine.Validate("No.", GLAccount."No.");
        SalesLine.Validate("Gen. Prod. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
        if VATPostingSetup."VAT Prod. Posting Group" <> '' then
            SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 250);
        SalesLine.Insert(true);
    end;
}