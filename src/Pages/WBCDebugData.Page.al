page 50212 "WBC Debug Data"
{
    PageType = Card;
    Caption = 'WBC Debug Data';
    ApplicationArea = All;
    UsageCategory = Administration;

    actions
    {
        area(Processing)
        {
            action(SeedTestData)
            {
                Caption = 'Seed Test Data';
                ApplicationArea = All;
                Image = Create;
                ToolTip = 'Create the debug data and set sales number series in My Company.';

                trigger OnAction()
                begin
                    if CompanyName() <> 'My Company' then
                        Error(WrongCompanyErr);

                    Codeunit.Run(Codeunit::"WBC Debug Data");
                    if GuiAllowed() then
                        Message(SeedCompletedMsg);
                end;
            }
        }
    }

    var
        WrongCompanyErr: Label 'Run this action in My Company.';
        SeedCompletedMsg: Label 'Debug data was seeded successfully.';
}
