tableextension 50205 "WBC Gen. Journal Line Ext" extends "Gen. Journal Line"
{


    fields
    {
        field(50200; "WBC External Sync Code"; Code[20])
        {
            Caption = 'External Sync Code';
            DataClassification = CustomerContent;
        }
    }

}
