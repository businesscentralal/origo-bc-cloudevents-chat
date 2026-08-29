namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;

/// <summary>
/// Creates and manages a mock MCP Chat Role for testing.
/// </summary>
codeunit 95902 "CE Chat Mock Provider ori"
{
    Access = Internal;
    Permissions = tabledata "MCP Chat Role ori" = RIMD,
                  tabledata "CE Chat Service Gate ori" = RIMD;

    var
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

    procedure BuildArgument(var TempArg: Record "MCP Chat Argument ori" temporary)
    var
        MCPChatRole: Record "MCP Chat Role ori";
    begin
        MCPChatRole.Get(MockRoleCode);
        TempArg.Init();
        TempArg."Role SystemId" := MCPChatRole.SystemId;
        TempArg."Base URL" := MCPChatRole."Base URL";
        TempArg.Model := MCPChatRole.Model;
        TempArg."Timeout Ms" := MCPChatRole."Timeout Seconds" * 1000;
        TempArg."Max Tokens" := MCPChatRole."Max Tokens";
    end;

    [NonDebuggable]
    procedure BuildArgumentWithKey(var TempArg: Record "MCP Chat Argument ori" temporary; ApiKey: Text)
    begin
        BuildArgument(TempArg);
        TempArg.SetApiKey(ApiKey);
    end;

    procedure Cleanup()
    var
        MCPChatRole: Record "MCP Chat Role ori";
    begin
        if MCPChatRole.Get(MockRoleCode) then
            MCPChatRole.Delete();
    end;
}
