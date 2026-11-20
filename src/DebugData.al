codeunit 50211 "WBC Debug Data"
{
    trigger OnRun()
    var
        SyncCustomer: Record Customer;
    begin
        SeedBlankCompanyTestData(SyncCustomer);
    end;

local procedure SeedBlankCompanyTestData(var SyncCustomer: Record Customer)
var
    AccountingPeriod: Record "Accounting Period";
    CustNoSeries: Record "No. Series";
    CustNoSeriesLine: Record "No. Series Line";
    InvNoSeries: Record "No. Series";
    InvNoSeriesLine: Record "No. Series Line";
    PostInvNoSeries: Record "No. Series";
    PostInvNoSeriesLine: Record "No. Series Line";
    GLReceivable: Record "G/L Account";
    GLSales: Record "G/L Account";
    GLVAT: Record "G/L Account";
    CustPostingGroup: Record "Customer Posting Group";
    GenBusPostingGroup: Record "Gen. Business Posting Group";
    GenProdPostingGroup: Record "Gen. Product Posting Group";
    GenPostingSetup: Record "General Posting Setup";
    VATBusPostingGroup: Record "VAT Business Posting Group";
    VATProdPostingGroup: Record "VAT Product Posting Group";
    VATPostingSetup: Record "VAT Posting Setup";
    SalesSetup: Record "Sales & Receivables Setup";
begin
    // 1. Accounting Period
    if AccountingPeriod.IsEmpty() then begin
        AccountingPeriod.Init();
        AccountingPeriod."Starting Date" := DMY2Date(1, 1, 2026);
        AccountingPeriod.Name := '2026';
        AccountingPeriod."New Fiscal Year" := true;
        AccountingPeriod.Insert();
    end;

    // 2. Number Series
    EnsureNoSeries('CUST', 'C0000', CustNoSeries, CustNoSeriesLine);
    EnsureNoSeries('S-INV', 'SI0000', InvNoSeries, InvNoSeriesLine);
    EnsureNoSeries('S-PINV', 'PSI0000', PostInvNoSeries, PostInvNoSeriesLine);

    // 3. G/L Accounts
    EnsureGLAccount('1200', 'Accounts Receivable', false, GLReceivable);
    EnsureGLAccount('4100', 'Sales Revenue', true, GLSales);
    EnsureGLAccount('2310', 'Sales VAT Payable', true, GLVAT);

    // 4. Posting Groups & Setups
    if not CustPostingGroup.Get('DOMESTIC') then begin
        CustPostingGroup.Init();
        CustPostingGroup.Code := 'DOMESTIC';
        CustPostingGroup."Receivables Account" := GLReceivable."No.";
        CustPostingGroup.Insert();
    end;

    if not GenBusPostingGroup.Get('DOMESTIC') then begin
        GenBusPostingGroup.Init();
        GenBusPostingGroup.Code := 'DOMESTIC';
        GenBusPostingGroup.Insert();
    end;

    if not GenProdPostingGroup.Get('RETAIL') then begin
        GenProdPostingGroup.Init();
        GenProdPostingGroup.Code := 'RETAIL';
        GenProdPostingGroup.Insert();
    end;

    if not GenPostingSetup.Get('DOMESTIC', 'RETAIL') then begin
        GenPostingSetup.Init();
        GenPostingSetup."Gen. Bus. Posting Group" := 'DOMESTIC';
        GenPostingSetup."Gen. Prod. Posting Group" := 'RETAIL';
        GenPostingSetup."Sales Account" := GLSales."No.";
        GenPostingSetup.Insert();
    end;

    if not VATBusPostingGroup.Get('DOMESTIC') then begin
        VATBusPostingGroup.Init();
        VATBusPostingGroup.Code := 'DOMESTIC';
        VATBusPostingGroup.Insert();
    end;

    if not VATProdPostingGroup.Get('VAT20') then begin
        VATProdPostingGroup.Init();
        VATProdPostingGroup.Code := 'VAT20';
        VATProdPostingGroup.Insert();
    end;

    if not VATPostingSetup.Get('DOMESTIC', 'VAT20') then begin
        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := 'DOMESTIC';
        VATPostingSetup."VAT Prod. Posting Group" := 'VAT20';
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup."Sales VAT Account" := GLVAT."No.";
        VATPostingSetup.Insert();
    end;

    // 5. Sales & Receivables Setup
    if not SalesSetup.Get() then begin
        SalesSetup.Init();
        SalesSetup.Insert();
    end;
    SalesSetup."Customer Nos." := 'CUST';
    SalesSetup."Invoice Nos." := 'S-INV';
    SalesSetup."Posted Invoice Nos." := 'S-PINV';
    SalesSetup.Modify();

    // 6. Sync-Enabled Customer
    if not SyncCustomer.Get('C0001') then begin
        SyncCustomer.Init();
        SyncCustomer."No." := 'C0001';
        SyncCustomer.Name := 'Sync Test Customer';
        SyncCustomer."Customer Posting Group" := 'DOMESTIC';
        SyncCustomer."Gen. Bus. Posting Group" := 'DOMESTIC';
        SyncCustomer."VAT Bus. Posting Group" := 'DOMESTIC';
        SyncCustomer."WBC External Sync Enabled" := true;
        SyncCustomer."WBC External Sync Code" := 'EXT-SYNC-01';
        SyncCustomer.Insert(true);
    end;
end;

local procedure EnsureNoSeries(SeriesCode: Code[20]; StartNo: Code[20]; var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line")
begin
    if not NoSeries.Get(SeriesCode) then begin
        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries."Default Nos." := true;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := StartNo;
        NoSeriesLine.Insert();
    end;
end;

local procedure EnsureGLAccount(AccNo: Code[20]; AccName: Text[100]; DirectPosting: Boolean; var GLAccount: Record "G/L Account")
begin
    if not GLAccount.Get(AccNo) then begin
        GLAccount.Init();
        GLAccount."No." := AccNo;
        GLAccount.Name := AccName;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Direct Posting" := DirectPosting;
        GLAccount.Insert();
    end;
end;
}
