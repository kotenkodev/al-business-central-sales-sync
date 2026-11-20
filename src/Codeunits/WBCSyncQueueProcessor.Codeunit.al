codeunit 50208 "WBC Sync Queue Processor"
{
    TableNo = "WBC Sync Queue Entry";
    Permissions = TableData "WBC Sync Queue Entry" = rm,
                    TableData Customer = r,
                    TableData "G/L Entry" = r;

    var
        SyncNotEnabledErr: Label 'External sync is disabled for Customer %1 on Document %2.', Comment = '%1 = Customer No., %2 = Document No.';
        MissingGLEntryErr: Label 'No G/L Entry with External Sync Code %1 was found for Document %2.', Comment = '%1 = External Sync Code, %2 = Document No.';

    trigger OnRun()
    var
        Customer: Record Customer;
        GLEntry: Record "G/L Entry";
    begin
        Rec.TestField(Status, Rec.Status::Pending);
        Rec.TestField("Document No.");
        Rec.TestField("Customer No.");
        Rec.TestField(Amount);

        Customer.SetLoadFields("WBC External Sync Enabled", "WBC External Sync Code");
        Customer.Get(Rec."Customer No.");

        if not Customer."WBC External Sync Enabled" then
            Error(SyncNotEnabledErr, Rec."Customer No.", Rec."Document No.");

        Customer.TestField("WBC External Sync Code");

        GLEntry.SetRange("Document No.", Rec."Document No.");
        GLEntry.SetRange("WBC External Sync Code", Customer."WBC External Sync Code");
        if GLEntry.IsEmpty() then
            Error(MissingGLEntryErr, Customer."WBC External Sync Code", Rec."Document No.");

        Rec.Status := Rec.Status::Processed;
        Rec."Processed Date Time" := CurrentDateTime();
        Rec."Error Message" := '';
        Rec.Modify(true);
    end;


}