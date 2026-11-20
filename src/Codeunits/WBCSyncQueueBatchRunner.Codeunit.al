codeunit 50209 "WBC Sync Queue Batch Runner"
{
    TableNo = "Job Queue Entry";
    Permissions = TableData "WBC Sync Queue Entry" = rm;

    trigger OnRun()
    var
        SyncQueueEntry: Record "WBC Sync Queue Entry";
        EntryToProcess: Record "WBC Sync Queue Entry";
        Processor: Codeunit "WBC Sync Queue Processor";
    begin
        SyncQueueEntry.SetRange(Status, SyncQueueEntry.Status::Pending);
        SyncQueueEntry.SetLoadFields("Entry No.", "Document Type", "Document No.", "Customer No.", Amount, "Cost Amount", Status);
        if not SyncQueueEntry.FindSet() then
            exit;

        repeat
            EntryToProcess := SyncQueueEntry;
            Commit();

            if not Processor.Run(EntryToProcess) then begin
                EntryToProcess.Get(SyncQueueEntry."Entry No.");
                EntryToProcess.Status := EntryToProcess.Status::Failed;
                EntryToProcess."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(EntryToProcess."Error Message"));
                EntryToProcess.Modify(true);
                Commit();
            end;
        until SyncQueueEntry.Next() = 0;
    end;
}