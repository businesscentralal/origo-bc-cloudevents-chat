namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Creates and manages a mock MCP Chat Role for testing.
/// Inserts a test role with Custom LLM provider and provides
/// helpers to set up per-user and service keys.
/// </summary>
codeunit 95902 "CE LLM Mock Provider ori"
{
    Access = Internal;
    Permissions = tabledata "MCP Chat Role ori" = RIMD,
                  tabledata "CE LLM Service Gate ori" = RIMD;

    var
        ProviderBase: Codeunit "CE LLM Provider Base ori";
        MockRoleCode: Code[20];

    procedure Create(): Code[20]
    begin
        exit(CreateWithCode('MOCK'));
    end;

    procedure CreateWithCode(RoleCode: Code[20]): Code[20]
    var
        MCPChatRole: Record "MCP Chat Role ori";
    begin
        MockRoleCode := RoleCode;
        if MCPChatRole.Get(MockRoleCode) then
            MCPChatRole.Delete();

        MCPChatRole.Init();
        MCPChatRole.Code := MockRoleCode;
        MCPChatRole.Description := 'Mock LLM Provider';
        MCPChatRole."Chat Provider" := MCPChatRole."Chat Provider"::"Custom LLM";
        MCPChatRole."Base URL" := 'https://mock.test.local';
        MCPChatRole.Model := 'mock-model-1';
        MCPChatRole."Timeout Seconds" := 60;
        MCPChatRole."Max Tokens" := 2048;
        MCPChatRole.Insert();

        exit(MockRoleCode);
    end;

    [NonDebuggable]
    procedure SetUserKey(ApiKey: Text)
    begin
        if ApiKey = '' then
            ProviderBase.ClearUserKey()
        else
            ProviderBase.SaveUserApiKey(ApiKey);
    end;

    [NonDebuggable]
    procedure SetServiceKey(ApiKey: Text)
    begin
        if ApiKey = '' then begin
            if IsolatedStorage.Contains('CE_LLM_Svc', DataScope::Company) then
                IsolatedStorage.Delete('CE_LLM_Svc', DataScope::Company);
        end else
            ProviderBase.SaveServiceKey(ApiKey);
    end;

    procedure SetAsDefault()
    var
        MCPChatRole: Record "MCP Chat Role ori";
        OtherRole: Record "MCP Chat Role ori";
    begin
        OtherRole.SetRange(Default, true);
        if OtherRole.FindSet() then
            repeat
                OtherRole.Default := false;
                OtherRole.Modify();
            until OtherRole.Next() = 0;

        MCPChatRole.Get(MockRoleCode);
        MCPChatRole.Default := true;
        MCPChatRole.Modify();
    end;

    procedure GetCode(): Code[20]
    begin
        exit(MockRoleCode);
    end;

    procedure GetRecord(var MCPChatRole: Record "MCP Chat Role ori")
    begin
        MCPChatRole.Get(MockRoleCode);
    end;

    procedure Cleanup()
    var
        MCPChatRole: Record "MCP Chat Role ori";
    begin
        ProviderBase.ClearUserKey();
        if IsolatedStorage.Contains('CE_LLM_Svc', DataScope::Company) then
            IsolatedStorage.Delete('CE_LLM_Svc', DataScope::Company);
        if MCPChatRole.Get(MockRoleCode) then
            MCPChatRole.Delete();
    end;
}
