namespace Origo.APP.CloudEvents.Chat;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;

/// <summary>
/// Azure OpenAI provider implementation using api-key header authentication.
/// </summary>
codeunit 10035503 "CE Chat Azure OAI Impl ori" implements "MCP Chat Role Provider ori"
{
    Access = Internal;

    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        AuthHeaderNameTok: Label 'api-key', Locked = true;
        ProviderNameTok: Label 'Azure OpenAI', Locked = true;
        ApiKeyLabelLbl: Label 'API Key', Comment = 'is-IS=API-lykill';
        ApiKeyInstructionLbl: Label 'Enter your Azure OpenAI deployment API key.', Comment = 'is-IS=Sláðu inn Azure OpenAI API-lykilinn þinn.';
        ApiKeyDocsUrlTok: Label 'https://portal.azure.com', Locked = true;
        ApiKeyDocsLinkTextLbl: Label 'Azure Portal', Comment = 'is-IS=Azure Portal';
        ServiceKeyDescLbl: Label 'Shared keys are used by all users in this company who do not have a personal key.', Comment = 'is-IS=Sameiginlegir lyklar eru notaðir af öllum notendum í þessu fyrirtæki sem hafa ekki persónulegan lykil.';

    procedure Execute(var Argument: Record "MCP Chat Argument ori" temporary)
    var
        ProcType: Enum "MCP Chat Proc. Type ori";
    begin
        ProcType := Argument."Procedure Type";
        case ProcType of
            ProcType::IsConfigured:
                Argument."Result Boolean" := CheckIsConfigured(Argument);
            ProcType::BuildConfigJson:
                Argument.SetResultText(DoBuildConfigJson(Argument));
            ProcType::SendChatMessage:
                Argument.SetResultText(DoSendChatMessage(Argument));
            ProcType::ContinueWithToolResults:
                Argument.SetResultText(DoContinueWithToolResults(Argument));
            ProcType::GetAvailableModels:
                Argument."Result Boolean" := DoGetAvailableModels(Argument);
            ProcType::TestConnection:
                Argument."Result Boolean" := DoTestConnection(Argument);
            ProcType::GetTokenUsage:
                DoGetTokenUsage(Argument);
            ProcType::GetProviderName:
                Argument.SetResultText(ProviderNameTok);
            ProcType::RequiresApiKey:
                Argument."Result Boolean" := true;
            ProcType::GetApiKeyLabel:
                Argument.SetResultText(ApiKeyLabelLbl);
            ProcType::GetApiKeyInstruction:
                Argument.SetResultText(ApiKeyInstructionLbl);
            ProcType::GetApiKeyPlaceholder:
                Argument.SetResultText('');
            ProcType::GetApiKeyDocsUrl:
                Argument.SetResultText(ApiKeyDocsUrlTok);
            ProcType::GetApiKeyDocsLinkText:
                Argument.SetResultText(ApiKeyDocsLinkTextLbl);
            ProcType::GetServiceKeyDescription:
                Argument.SetResultText(ServiceKeyDescLbl);
            ProcType::HasServiceKeyPermission:
                Argument."Result Boolean" := ProviderBase.HasServiceKeyPermission();
            ProcType::GetMaxToolCount:
                Argument."Result Integer" := 0;
            ProcType::SupportsSplitToolExecution:
                Argument."Result Boolean" := true;
            ProcType::SupportsModelSelection:
                Argument."Result Boolean" := true;
            ProcType::SupportsToolCalling:
                Argument."Result Boolean" := true;
            ProcType::HasExternalEndpoint:
                Argument."Result Boolean" := true;
            ProcType::RequiresChatPath,
            ProcType::RequiresModelsPath:
                Argument."Result Boolean" := true;
            ProcType::GetDefaultBaseUrl:
                Argument.SetResultText('');
            ProcType::GetDefaultModel:
                Argument.SetResultText('');
            ProcType::GetDefaultTimeoutSeconds:
                Argument."Result Integer" := 120;
            ProcType::GetDefaultMaxTokens:
                Argument."Result Integer" := 16384;
            ProcType::GetContextWindowChars:
                Argument."Result Integer" := 80000;
            ProcType::GetDefaultSkillUrl:
                Argument.SetResultText('');
            ProcType::GetDefaultSkillText:
                Argument.SetResultText('');
        end;
    end;

    local procedure CheckIsConfigured(var Argument: Record "MCP Chat Argument ori" temporary): Boolean
    begin
        exit(ProviderBase.IsConfigured(Argument, ''));
    end;

    [NonDebuggable]
    local procedure DoBuildConfigJson(var Argument: Record "MCP Chat Argument ori" temporary): Text
    var
        ConfigJson: JsonObject;
        ConfigText: Text;
    begin
        ProviderBase.EnsureHttpClientAllowed();
        ConfigJson.Add('provider', ProviderNameTok);
        ConfigJson.Add('apiKey', Argument.GetApiKey());
        ConfigJson.Add('model', ProviderBase.GetModel(Argument, ''));
        ConfigJson.Add('baseUrl', ProviderBase.GetBaseUrl(Argument, ''));
        ConfigJson.Add('timeoutMs', ProviderBase.GetTimeoutMs(Argument, 120000));
        ConfigJson.Add('maxTokens', ProviderBase.GetMaxTokens(Argument, 16384));
        ConfigJson.WriteTo(ConfigText);
        exit(ConfigText);
    end;

    local procedure DoSendChatMessage(var Argument: Record "MCP Chat Argument ori" temporary): Text
    var
        LLMChatProxy: Codeunit "CE Chat Proxy ori";
    begin
        SetAzureChatPath(Argument);
        exit(LLMChatProxy.SendChatMessage(Argument, Argument.GetPayload(), AuthHeaderNameTok));
    end;

    local procedure DoContinueWithToolResults(var Argument: Record "MCP Chat Argument ori" temporary): Text
    var
        LLMChatProxy: Codeunit "CE Chat Proxy ori";
    begin
        SetAzureChatPath(Argument);
        exit(LLMChatProxy.ContinueWithToolResults(Argument, Argument.GetConversationState(), Argument.GetToolResults(), AuthHeaderNameTok));
    end;

    local procedure DoTestConnection(var Argument: Record "MCP Chat Argument ori" temporary): Boolean
    var
        NoKeyErr: Label 'No API key configured. Enter a personal or shared API key.', Comment = 'is-IS=Enginn API-lykill stilltur. Sláðu inn persónulegan eða sameiginlegan API-lykil.';
        NoBaseUrlErr: Label 'No Base URL configured for this role. Set the Azure OpenAI endpoint URL.', Comment = 'is-IS=Engin grunnslóð stillt fyrir þetta hlutverk. Stilltu Azure OpenAI endapunktsslóðina.';
    begin
        if Argument.GetApiKey() = '' then begin
            Argument.SetErrorMessage(NoKeyErr);
            exit(false);
        end;
        if not ProviderBase.IsConfigured(Argument, '') then begin
            Argument.SetErrorMessage(NoBaseUrlErr);
            exit(false);
        end;
        exit(true);
    end;

    local procedure DoGetTokenUsage(var Argument: Record "MCP Chat Argument ori" temporary)
    var
        InTokens: Integer;
        OutTokens: Integer;
    begin
        ProviderBase.ParseTokenUsage(Argument.GetPayload(), InTokens, OutTokens);
        Argument."Input Tokens" := InTokens;
        Argument."Output Tokens" := OutTokens;
    end;

    local procedure SetAzureChatPath(var Argument: Record "MCP Chat Argument ori" temporary)
    var
        ApiVersionTok: Label '2024-12-01-preview', Locked = true;
        ChatPathTok: Label '/openai/deployments/%1/chat/completions?api-version=%2', Locked = true;
    begin
        if Argument."Chat Path" = '' then
            Argument."Chat Path" := StrSubstNo(ChatPathTok, ProviderBase.GetModel(Argument, ''), ApiVersionTok)
        else
            Argument."Chat Path" := StrSubstNo(Argument."Chat Path", ProviderBase.GetModel(Argument, ''), ApiVersionTok);
    end;

    local procedure DoGetAvailableModels(var Argument: Record "MCP Chat Argument ori" temporary): Boolean
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ApiClient: Codeunit "CE Chat API Client ori";
        ModelsArray: JsonArray;
        ModelToken: JsonToken;
        ModelObject: JsonObject;
        ModelsUrl: Text;
        IdValue: Text;
        EntryNo: Integer;
    begin
        if Argument."Models Path" = '' then
            exit(false);

        ModelsUrl := ProviderBase.GetBaseUrl(Argument, '') + Argument."Models Path";
        ModelsArray := ApiClient.ListModelsFromEndpoint(ModelsUrl, AuthHeaderNameTok, Argument.GetApiKey());

        foreach ModelToken in ModelsArray do begin
            ModelObject := ModelToken.AsObject();
            IdValue := GetJsonText(ModelObject, 'id');
            if IdValue <> '' then begin
                EntryNo += 1;
                TempNameValueBuffer.Init();
                TempNameValueBuffer.ID := EntryNo;
                TempNameValueBuffer.Name := CopyStr(IdValue, 1, MaxStrLen(TempNameValueBuffer.Name));
                TempNameValueBuffer.Value := CopyStr(IdValue, 1, MaxStrLen(TempNameValueBuffer.Value));
                TempNameValueBuffer.Insert();
            end;
        end;
        Argument.SetModels(TempNameValueBuffer);
        exit(EntryNo > 0);
    end;

    local procedure GetJsonText(JObject: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.Get(PropertyName, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsText());
    end;
}
