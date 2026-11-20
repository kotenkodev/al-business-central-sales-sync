codeunit 50204 "WBC Sales Post Subscribers"
{
    Permissions = TableData "WBC Sync Queue Entry" = ri;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure HandleBeforePostSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    var
        Customer: Record Customer;
    begin
        if PreviewMode then
            exit;

        if SalesHeader."Sell-to Customer No." = '' then
            exit;

        Customer.SetLoadFields("WBC External Sync Enabled");

        if not Customer.Get(SalesHeader."Sell-to Customer No.") then
            exit;

        if Customer."WBC External Sync Enabled" then begin
            SalesHeader.TestField("Currency Code", '');
            SalesHeader.TestField("External Document No.");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure HandleAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; PreviewMode: Boolean)
    var
        Customer: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ValueEntry: Record "Value Entry";
        SyncQueueEntry: Record "WBC Sync Queue Entry";
        DocType: Enum "Gen. Journal Document Type";
        ValueEntryDocType: Enum "Item Ledger Document Type";
        PostedDocNo: Code[20];
        DocAmount: Decimal;
    begin
        if PreviewMode then
            exit;

        if (SalesInvHdrNo = '') and (SalesCrMemoHdrNo = '') then
            exit;

        if SalesHeader."Sell-to Customer No." = '' then
            exit;

        Customer.SetLoadFields("WBC External Sync Enabled");

        if not Customer.Get(SalesHeader."Sell-to Customer No.") then
            exit;

        if not Customer."WBC External Sync Enabled" then
            exit;

        if SalesInvHdrNo <> '' then begin
            SalesInvHeader.Get(SalesInvHdrNo);
            SalesInvHeader.CalcFields("Amount Including VAT");
            DocType := DocType::Invoice;
            ValueEntryDocType := ValueEntryDocType::"Sales Invoice";
            PostedDocNo := SalesInvHdrNo;
            DocAmount := SalesInvHeader."Amount Including VAT";
        end else if SalesCrMemoHdrNo <> '' then begin
            SalesCrMemoHeader.Get(SalesCrMemoHdrNo);
            SalesCrMemoHeader.CalcFields("Amount Including VAT");
            DocType := DocType::"Credit Memo";
            ValueEntryDocType := ValueEntryDocType::"Sales Credit Memo";
            PostedDocNo := SalesCrMemoHdrNo;
            DocAmount := -SalesCrMemoHeader."Amount Including VAT";
        end;

        ValueEntry.SetRange("Document Type", ValueEntryDocType);
        ValueEntry.SetRange("Document No.", PostedDocNo);
        ValueEntry.CalcSums("Cost Amount (Actual)");

        SyncQueueEntry.Init();
        SyncQueueEntry."Document Type" := DocType;
        SyncQueueEntry."Document No." := PostedDocNo;
        SyncQueueEntry."Customer No." := SalesHeader."Sell-to Customer No.";
        SyncQueueEntry.Amount := DocAmount;
        SyncQueueEntry."Cost Amount" := -ValueEntry."Cost Amount (Actual)";
        SyncQueueEntry.Insert(true);
    end;
}