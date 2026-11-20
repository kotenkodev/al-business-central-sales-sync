tableextension 50206 "WBC G/L Entry Ext" extends "G/L Entry"
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
