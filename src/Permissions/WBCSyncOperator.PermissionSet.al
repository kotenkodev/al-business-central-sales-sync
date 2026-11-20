permissionset 50213 "WBC SYNC OPERATOR"
{
    Assignable = true;
    Caption = 'Outbound Sales Sync Operator';
    Permissions =
        table "WBC Sync Queue Entry" = X,
        tabledata "WBC Sync Queue Entry" = Rim,
        codeunit "WBC Sales Post Subscribers" = X,
        codeunit "WBC GL Propagation Subscribers" = X,
        codeunit "WBC Sync Queue Processor" = X,
        codeunit "WBC Sync Queue Batch Runner" = X;
}
