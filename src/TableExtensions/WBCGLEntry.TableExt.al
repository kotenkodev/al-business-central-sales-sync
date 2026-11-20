tableextension 50206 "WBC G/L Entry Ext" extends "G/L Entry"
{
    // TODO: Add field 50200 "WBC External Sync Code" (Code[20]).
    // Set its caption and data classification.

    fields
    {
        field(50200; "WBC External Sync Code"; Code[20])
        {
            Caption = 'External Sync Code';
            DataClassification = CustomerContent;
        }
    }


}
