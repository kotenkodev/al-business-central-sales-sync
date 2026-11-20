codeunit 50207 "WBC GL Propagation Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeader', '', false, false)]
    local procedure HandleAfterCopyGenJnlLineFromSalesHeader(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
    begin
        if SalesHeader."Sell-to Customer No." = '' then
            exit;

        Customer.SetLoadFields("WBC External Sync Enabled", "WBC External Sync Code");
        if not Customer.Get(SalesHeader."Sell-to Customer No.") then
            exit;

        if Customer."WBC External Sync Enabled" then
            GenJournalLine."WBC External Sync Code" := Customer."WBC External Sync Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitGLEntry', '', false, false)]
    local procedure HandleAfterInitGLEntry(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."WBC External Sync Code" <> '' then
            GLEntry."WBC External Sync Code" := GenJournalLine."WBC External Sync Code";
    end;
}