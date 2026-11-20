tableextension 50202 "WBC Customer Sync" extends Customer
{
    fields
    {
        field(50200; "WBC External Sync Enabled"; Boolean)
        {
            Caption = 'External Sync Enabled';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            begin
                if (not Rec."WBC External Sync Enabled") and (Rec."WBC External Sync Code" <> '') then
                    Error(CannotDisableSyncWithCodeErr);
            end;
        }
        field(50201; "WBC External Sync Code"; Code[20])
        {
            Caption = 'External Sync Code';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                ValidateSyncCodeRule();
            end;
        }
        field(50202; "WBC Pending Sync Count"; Integer)
        {
            Caption = 'Pending Sync Count';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = count("WBC Sync Queue Entry" where("Customer No." = field("No."),
                                                       Status = const(Pending)));
        }
    }

    var
        SyncCodeRequiresEnabledErr: Label 'External Sync Enabled must be true when External Sync Code is populated.';
        CannotDisableSyncWithCodeErr: Label 'External Sync Enabled cannot be turned off while External Sync Code is populated. Clear the code first.';

    local procedure ValidateSyncCodeRule()
    begin
        if (Rec."WBC External Sync Code" <> '') and (not Rec."WBC External Sync Enabled") then
            Error(SyncCodeRequiresEnabledErr);
    end;
}