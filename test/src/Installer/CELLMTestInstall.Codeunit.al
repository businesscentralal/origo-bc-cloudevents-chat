namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;
using System.TestTools.TestRunner;

codeunit 95901 "CE LLM Test Install ori"
{
    Subtype = Install;
    Permissions = tabledata "CE LLM Provider Setup ori" = RIMD,
                  tabledata "Cloud Events Setup ori" = RIMD;

    trigger OnInstallAppPerCompany()
    begin
        SetupMockProvider();
        SetupTestSuite();
    end;

    local procedure SetupMockProvider()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        if not ProviderSetup.Get('MOCK') then begin
            ProviderSetup.Init();
            ProviderSetup.Code := 'MOCK';
            ProviderSetup.Name := 'Mock LLM Provider';
            ProviderSetup."Base URL" := 'https://mock.test.local';
            ProviderSetup."Auth Type" := ProviderSetup."Auth Type"::"x-api-key";
            ProviderSetup."Default Model" := 'mock-model-1';
            ProviderSetup."Timeout Seconds" := 60;
            ProviderSetup."Max Tokens" := 2048;
            ProviderSetup."Chat Path" := '/v1/chat/completions';
            ProviderSetup."Models Path" := '/v1/models';
            ProviderSetup.Enabled := true;
            ProviderSetup.Insert();
        end;
        ProviderSetup.SetServiceApiKey('test-key-install');

        if not CloudEventsSetup.Get() then begin
            CloudEventsSetup.Init();
            CloudEventsSetup.Insert();
        end;
        CloudEventsSetup."CE LLM Def. Provider Code ori" := 'MOCK';
        CloudEventsSetup.Modify();
    end;

    procedure SetupTestSuite()
    var
        ALTestSuite: Record "AL Test Suite";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        SuiteName: Code[10];
    begin
        SuiteName := 'DEFAULT';
        if ALTestSuite.Get(SuiteName) then
            ALTestSuite.DELETE(true);

        TestSuiteMgt.CreateTestSuite(SuiteName);
        Commit();
        ALTestSuite.Get(SuiteName);
        TestSuiteMgt.SelectTestMethodsByRange(ALTestSuite, '50000..99999');
    end;
}
