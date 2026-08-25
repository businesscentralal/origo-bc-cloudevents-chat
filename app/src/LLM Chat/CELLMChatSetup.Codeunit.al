namespace Origo.APP.CloudEvents.LLM;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;
using System.Azure.Identity;
using System.Environment;
using System.Environment.Configuration;
using System.Utilities;

/// <summary>
/// Manages the LLM API key in IsolatedStorage (per-user) and builds
/// the configuration JSON needed by the LLM Chat control add-in.
/// </summary>
codeunit 10035488 "CE LLM Chat Setup ori"
{
    SingleInstance = true;
    Access = Internal;

    var
        ApiKeyStorageKeyTok: Label 'CE_LLM_Chat_ApiKey', Locked = true;
        DefaultSkillInstructionTok: Label 'On startup, call the who_am_i tool to learn about the current user and company.', Locked = true;
        ThinkingLbl: Label 'Thinking...', Comment = 'is-IS=Hugsar...';
        LoadingSkillLbl: Label 'Loading skill reference...', Comment = 'is-IS=Hleð færniviðmiðum...';
        FailedToParseResponseLbl: Label 'Failed to parse response.', Comment = 'is-IS=Gat ekki lesið svar.';
        InvalidResponseFormatLbl: Label 'Invalid response format.', Comment = 'is-IS=Ógilt svarsnið.';
        ApiKeyRequiredLbl: Label 'LLM API Key Required', Comment = 'is-IS=LLM API-lykils krafist';
        ApiKeyInstructionLbl: Label 'Enter your LLM API key to enable chat.', Comment = 'is-IS=Sláðu inn LLM API-lykilinn þinn til að virkja spjall.';
        ApiKeyDocsLinkTextLbl: Label 'LLM Console', Comment = 'is-IS=LLM-stjórnborð';
        ApiKeyPlaceholderLbl: Label 'sk-llm-...', Locked = true;
        ApiKeyDocsUrlTok: Label 'https://llm.kappi.is', Locked = true;
        SaveKeyLbl: Label 'Save Key', Comment = 'is-IS=Vista lykil';
        ApiKeySavedLbl: Label 'API key saved. You can now chat.', Comment = 'is-IS=API-lykill vistaður. Þú getur nú spjallað.';
        InputPlaceholderLbl: Label 'Ask about your Business Central data...', Comment = 'is-IS=Spurðu um Business Central gögnin þín...';
        SendBtnLbl: Label 'Send', Comment = 'is-IS=Senda';
        ReadyToChatLbl: Label 'Ready to chat.', Comment = 'is-IS=Tilbúið til spjalls.';
        McpAuthRequiredLbl: Label 'MCP Connection Required', Comment = 'is-IS=MCP-tenging nauðsynleg';
        McpAuthInstructionLbl: Label 'Click the Connect action above to sign in to the MCP server.', Comment = 'is-IS=Smelltu á Tengjast aðgerðina hér að ofan til að skrá þig inn á MCP-þjóninn.';
        McpConnectLbl: Label 'Connect', Comment = 'is-IS=Tengjast';
        McpConnectingLbl: Label 'Connecting...', Comment = 'is-IS=Tengist...';
        McpConnectFailedLbl: Label 'Connection failed.', Comment = 'is-IS=Tenging mistókst.';

    [NonDebuggable]
    internal procedure SetApiKey(ApiKey: Text)
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        if ResolveProvider(ProviderSetup) then
            ProviderSetup.SetUserApiKey(ApiKey)
        else
            if ApiKey = '' then
                IsolatedStorage.Delete(ApiKeyStorageKeyTok, DataScope::User)
            else
                IsolatedStorage.Set(ApiKeyStorageKeyTok, ApiKey, DataScope::User);
    end;

    [NonDebuggable]
    internal procedure GetApiKey(): Text
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
        ApiKeyValue: Text;
    begin
        if IsolatedStorage.Get(ApiKeyStorageKeyTok, DataScope::User, ApiKeyValue) then
            exit(ApiKeyValue);
        if HasServiceGate() then
            if CloudEventsSetup.HasLLMServiceApiKey() then
                exit(CloudEventsSetup.GetLLMServiceApiKey());
    end;

    internal procedure HasApiKey(): Boolean
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        if ResolveProvider(ProviderSetup) then
            exit(ProviderSetup.HasApiKey());
    end;

    internal procedure HasServiceGate(): Boolean
    var
        ServiceGate: Record "CE LLM Service Gate ori";
    begin
        exit(ServiceGate.WritePermission());
    end;

    internal procedure AssertServiceGate(var Argument: Record "CE Message Argument ori"): Boolean
    var
        DeniedErr: Label 'Access denied: missing ''CE LLM Svc'' permission set.', Comment = 'is-IS=Aðgangur hafnaður: vantar ''CE LLM Svc'' heimildasett.';
    begin
        if HasServiceGate() then
            exit(true);
        Argument.RespondWithError(DeniedErr);
        exit(false);
    end;

    /// <summary>
    /// Resolves the provider using the fallback chain:
    /// 1. User Setup provider (if set)
    /// 2. Global default provider (Cloud Events Setup)
    /// </summary>
    internal procedure ResolveProvider(var ProviderSetup: Record "CE LLM Provider Setup ori"): Boolean
    var
        CEUserSetup: Record "CE User Setup ori";
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        if CEUserSetup.Get(UserSecurityId()) then
            if CEUserSetup."CE LLM Provider Code ori" <> '' then
                exit(ProviderSetup.Get(CEUserSetup."CE LLM Provider Code ori"));
        exit(CloudEventsSetup.GetDefaultProvider(ProviderSetup));
    end;

    [NonDebuggable]
    internal procedure BuildConfigJson(): Text
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
        CEUserSetup: Record "CE User Setup ori";
        LLMChatRole: Record "MCP Chat Role ori";
        CompanyRec: Record Company;
        ConfigObject: JsonObject;
        ApiKey: Text;
        SystemPrompt: Text;
        SkillText: Text;
        ConfigText: Text;
    begin
        CompanyRec.Get(CompanyName());

        if ResolveProvider(ProviderSetup) then
            ApiKey := ProviderSetup.GetApiKey()
        else
            ApiKey := GetApiKey();

        ConfigObject.Add('apiKey', ApiKey);
        ConfigObject.Add('mode', 'local');
        ConfigObject.Add('tenantId', GetTenantId());
        ConfigObject.Add('environment', GetEnvironmentName());
        ConfigObject.Add('companyId', Format(CompanyRec.Id, 0, 4));
        ConfigObject.Add('companyName', CompanyRec."Display Name");
        ConfigObject.Add('lcid', GlobalLanguage());
        ConfigObject.Add('requiresMcpAuth', false);
        ConfigObject.Add('mcpConnected', true);

        if CEUserSetup.Get(UserSecurityId()) then begin
            SystemPrompt := CEUserSetup.GetSystemPrompt();
            if SystemPrompt <> '' then
                ConfigObject.Add('systemPrompt', SystemPrompt);

            if CEUserSetup."MCP Chat Role Code" <> '' then
                if LLMChatRole.Get(CEUserSetup."MCP Chat Role Code") then
                    SkillText := LLMChatRole.GetSkill();
        end;

        if ResolveProvider(ProviderSetup) then
            ConfigObject.Add('model', ProviderSetup."Default Model");

        if SkillText <> '' then
            ConfigObject.Add('skill', DefaultSkillInstructionTok + '\n\n' + SkillText)
        else
            ConfigObject.Add('skill', DefaultSkillInstructionTok);

        ConfigObject.Add('apiKeyDocsUrl', ApiKeyDocsUrlTok);
        ConfigObject.Add('apiKeyPlaceholder', ApiKeyPlaceholderLbl);
        ConfigObject.Add('labels', BuildLabelsJson());

        ConfigObject.WriteTo(ConfigText);
        exit(ConfigText);
    end;

    local procedure BuildLabelsJson(): JsonObject
    var
        Labels: JsonObject;
    begin
        Labels.Add('thinking', ThinkingLbl);
        Labels.Add('loadingSkill', LoadingSkillLbl);
        Labels.Add('failedToParseResponse', FailedToParseResponseLbl);
        Labels.Add('invalidResponseFormat', InvalidResponseFormatLbl);
        Labels.Add('apiKeyRequired', ApiKeyRequiredLbl);
        Labels.Add('apiKeyInstruction', ApiKeyInstructionLbl);
        Labels.Add('apiKeyDocsLinkText', ApiKeyDocsLinkTextLbl);
        Labels.Add('saveKey', SaveKeyLbl);
        Labels.Add('apiKeySaved', ApiKeySavedLbl);
        Labels.Add('inputPlaceholder', InputPlaceholderLbl);
        Labels.Add('sendBtn', SendBtnLbl);
        Labels.Add('readyToChat', ReadyToChatLbl);
        Labels.Add('mcpAuthRequired', McpAuthRequiredLbl);
        Labels.Add('mcpAuthInstruction', McpAuthInstructionLbl);
        Labels.Add('mcpConnect', McpConnectLbl);
        Labels.Add('mcpConnecting', McpConnectingLbl);
        Labels.Add('mcpConnectFailed', McpConnectFailedLbl);
        exit(Labels);
    end;

    local procedure GetTenantId(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetAadTenantId());
    end;

    local procedure GetEnvironmentName(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetEnvironmentName());
    end;

    internal procedure EnsureHttpClientAllowed()
    var
        NavAppSetting: Record "NAV App Setting";
        ConfirmManagement: Codeunit "Confirm Management";
        ModuleInfo: ModuleInfo;
    begin
        if HttpClientChecked then
            exit;
        HttpClientChecked := true;

        NavApp.GetCurrentModuleInfo(ModuleInfo);
        NavAppSetting.SetLoadFields("Allow HttpClient Requests");
        if not NavAppSetting.Get(ModuleInfo.Id()) then
            exit;

        if NavAppSetting."Allow HttpClient Requests" then
            exit;

        if NavAppSetting.WritePermission() then
            if ConfirmManagement.GetResponseOrDefault(EnableHttpClientQst, true) then begin
                NavAppSetting."Allow HttpClient Requests" := true;
                NavAppSetting.Modify(true);
                exit;
            end;

        Error(HttpClientBlockedErr);
    end;

    internal procedure GetAvailableModels(var TempNameValueBuffer: Record "Name/Value Buffer" temporary): Boolean
    var
        ApiClient: Codeunit "CE LLM API Client ori";
        ModelsJson: JsonArray;
        ModelToken: JsonToken;
        ModelObj: JsonObject;
        IdTok: JsonToken;
        EntryNo: Integer;
        ModelId: Text;
    begin
        TempNameValueBuffer.Reset();
        TempNameValueBuffer.DeleteAll();

        if not TryListModels(ApiClient, ModelsJson) then
            exit(false);

        foreach ModelToken in ModelsJson do begin
            ModelObj := ModelToken.AsObject();
            if ModelObj.Get('id', IdTok) then begin
                ModelId := IdTok.AsValue().AsText();
                EntryNo += 1;
                TempNameValueBuffer.Init();
                TempNameValueBuffer.ID := EntryNo;
                TempNameValueBuffer.Name := CopyStr(ModelId, 1, MaxStrLen(TempNameValueBuffer.Name));
                TempNameValueBuffer.Value := CopyStr(ModelId, 1, MaxStrLen(TempNameValueBuffer.Value));
                TempNameValueBuffer.Insert();
            end;
        end;

        exit(TempNameValueBuffer.Count() > 0);
    end;

    [TryFunction]
    local procedure TryListModels(var ApiClient: Codeunit "CE LLM API Client ori"; var ModelsJson: JsonArray)
    begin
        ModelsJson := ApiClient.ListModels();
    end;

    internal procedure ClearApiKey()
    begin
        SetApiKey('');
    end;

    internal procedure ClearCredentials()
    begin
        ClearApiKey();
    end;

    var
        HttpClientChecked: Boolean;
        EnableHttpClientQst: Label 'LLM Chat requires HTTP access. Enable "Allow HttpClient Requests" for this extension?', Comment = 'is-IS=LLM-spjall þarf HTTP-aðgang. Virkja "Allow HttpClient Requests" fyrir þessa viðbót?';
        HttpClientBlockedErr: Label 'LLM Chat requires "Allow HttpClient Requests" to be enabled for this extension. Contact your administrator.', Comment = 'is-IS=LLM-spjall krefst þess að "Allow HttpClient Requests" sé virkt fyrir þessa viðbót. Hafðu samband við kerfisstjóra.';
}
