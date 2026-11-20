codeunit 50203 "WBC Sync Queue Data Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    procedure NewEntryReceivesDefaults()
    var
        QueueEntry: Record "WBC Sync Queue Entry";
        BeforeInsert: DateTime;
    begin
        QueueEntry.Init();
        BeforeInsert := CurrentDateTime();
        QueueEntry.Insert(true);
        QueueEntry.Get(QueueEntry."Entry No.");

        Assert.IsTrue(QueueEntry."Entry No." > 0, 'An entry number must be generated.');
        Assert.AreEqual(QueueEntry.Status::Pending, QueueEntry.Status, 'New entries must default to Pending.');
        Assert.IsTrue(QueueEntry."Created Date Time" >= BeforeInsert, 'Creation time must be assigned during insertion.');
        Assert.IsTrue(QueueEntry."Created Date Time" <= CurrentDateTime(), 'Creation time must not be in the future.');
        Assert.AreEqual(0DT, QueueEntry."Processed Date Time", 'New entries must have no processing timestamp.');
        Assert.AreEqual('', QueueEntry."Error Message", 'New entries must have no error.');
    end;

    [Test]
    procedure InsertPreservesExplicitState()
    var
        QueueEntry: Record "WBC Sync Queue Entry";
        SuppliedTime: DateTime;
    begin
        SuppliedTime := CreateDateTime(DMY2Date(1, 1, 2020), 120000T);
        QueueEntry.Init();
        QueueEntry.Status := QueueEntry.Status::Failed;
        QueueEntry."Created Date Time" := SuppliedTime;
        QueueEntry."Processed Date Time" := SuppliedTime;
        QueueEntry."Error Message" := 'Supplied failure detail';
        QueueEntry.Insert(true);
        QueueEntry.Get(QueueEntry."Entry No.");

        Assert.AreEqual(QueueEntry.Status::Failed, QueueEntry.Status, 'Explicit status must be preserved.');
        Assert.AreEqual(SuppliedTime, QueueEntry."Created Date Time", 'Explicit creation time must be preserved.');
        Assert.AreEqual(SuppliedTime, QueueEntry."Processed Date Time", 'Explicit processing time must be preserved.');
        Assert.AreEqual('Supplied failure detail', QueueEntry."Error Message", 'Explicit error details must be preserved.');
    end;

    [Test]
    procedure SyncCodeRequiresEnabledCustomer()
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("WBC External Sync Enabled", false);

        asserterror Customer.Validate("WBC External Sync Code", 'EXTERNAL');
        Assert.ExpectedError('External Sync Enabled must be true when External Sync Code is populated.');
    end;

    [Test]
    procedure DisablingSyncRequiresClearingCode()
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("WBC External Sync Enabled", true);
        Customer.Validate("WBC External Sync Code", 'EXTERNAL');
        Customer.Modify(true);

        asserterror Customer.Validate("WBC External Sync Enabled", false);
        Assert.ExpectedError('External Sync Enabled cannot be turned off while External Sync Code is populated. Clear the code first.');
    end;

    [Test]
    procedure ClearingCodeAllowsDisablingSync()
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("WBC External Sync Enabled", true);
        Customer.Validate("WBC External Sync Code", 'EXTERNAL');
        Customer.Modify(true);

        Customer.Validate("WBC External Sync Code", '');
        Customer.Validate("WBC External Sync Enabled", false);
        Customer.Modify(true);
        Customer.Get(Customer."No.");
        Assert.IsFalse(Customer."WBC External Sync Enabled", 'Sync can be disabled after clearing its code.');
        Assert.AreEqual('', Customer."WBC External Sync Code", 'The cleared code must be persisted.');
    end;

    [Test]
    procedure PendingCountFiltersCustomerAndStatus()
    var
        CustomerA: Record Customer;
        CustomerB: Record Customer;
        QueueEntry: Record "WBC Sync Queue Entry";
        EntryNo: Integer;
    begin
        LibrarySales.CreateCustomer(CustomerA);
        LibrarySales.CreateCustomer(CustomerB);
        EntryNo := InsertQueueEntry(CustomerA."No.", QueueEntry.Status::Pending);
        InsertQueueEntry(CustomerA."No.", QueueEntry.Status::Pending);
        InsertQueueEntry(CustomerA."No.", QueueEntry.Status::Processed);
        InsertQueueEntry(CustomerB."No.", QueueEntry.Status::Pending);

        CustomerA.CalcFields("WBC Pending Sync Count");
        Assert.AreEqual(2, CustomerA."WBC Pending Sync Count", 'Count must exclude other customers and non-Pending entries.');

        QueueEntry.Get(EntryNo);
        QueueEntry.Status := QueueEntry.Status::Failed;
        QueueEntry.Modify(true);
        CustomerA.CalcFields("WBC Pending Sync Count");
        Assert.AreEqual(1, CustomerA."WBC Pending Sync Count", 'Recalculation must reflect the status change.');
    end;

    local procedure InsertQueueEntry(CustomerNo: Code[20]; Status: Enum "WBC Sync Queue Status"): Integer
    var
        QueueEntry: Record "WBC Sync Queue Entry";
    begin
        QueueEntry.Init();
        QueueEntry.Validate("Customer No.", CustomerNo);
        QueueEntry.Status := Status;
        QueueEntry.Insert(true);
        exit(QueueEntry."Entry No.");
    end;
}
