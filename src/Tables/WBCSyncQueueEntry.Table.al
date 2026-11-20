table 50201 "WBC Sync Queue Entry"
{
    Caption = 'Sync Queue Entry';
    DataPerCompany = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(2; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
        }
        field(6; "Cost Amount"; Decimal)
        {
            Caption = 'Cost Amount';
            AutoFormatType = 1;
        }
        field(7; Status; Enum "WBC Sync Queue Status")
        {
            Caption = 'Status';
            InitValue = Pending;
        }
        field(8; "Created Date Time"; DateTime)
        {
            Caption = 'Created Date Time';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(9; "Processed Date Time"; DateTime)
        {
            Caption = 'Processed Date Time';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(10; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Status, "Entry No.")
        {
        }
        key(Key3; "Customer No.", Status)
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created Date Time" = 0DT then
            "Created Date Time" := CurrentDateTime();
    end;
}