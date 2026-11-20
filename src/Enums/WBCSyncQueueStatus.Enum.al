enum 50200 "WBC Sync Queue Status"
{
    Extensible = false;

    value(0; Pending)
    {
        Caption = 'Pending';
    }

    value(1; Processed)
    {
        Caption = 'Processed';
    }

    value(2; Failed)
    {
        Caption = 'Failed';
    }
}

