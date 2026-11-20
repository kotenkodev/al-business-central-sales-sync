tableextension 50205 "WBC Gen. Journal Line Ext" extends "Gen. Journal Line"
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
