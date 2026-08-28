namespace Origo.APP.CloudEvents.Chat;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;

/// <summary>
/// Custom/self-hosted LLM provider implementation using x-api-key header authentication.
/// Suitable for Ollama, vLLM, and other OpenAI-compatible endpoints.
/// </summary>
codeunit 10035504 "CE Chat Custom Impl ori" implements "MCP Chat Role Provider ori"
{
    Access = Internal;

    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        AuthHeaderNameTok: Label 'x-api-key', Locked = true;
        ProviderNameTok: Label 'Custom LLM', Locked = true;
        ApiKeyLabelLbl: Label 'API Key', Comment = 'is-IS=API-lykill';
        ApiKeyInstructionLbl: Label 'Enter the API key for your LLM endpoint.', Comment = 'is-IS=Sláðu inn API-lykilinn fyrir LLM endapunktinn þinn.';
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
                Argument.SetResultText('');
            ProcType::GetApiKeyDocsLinkText:
                Argument.SetResultText('');
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
            ProcType::GetDefaultBaseUrl:
                Argument.SetResultText('');
            ProcType::GetDefaultModel:
                Argument.SetResultText('');
            ProcType::GetDefaultTimeoutSeconds:
                Argument."Result Integer" := 300;
            ProcType::GetDefaultMaxTokens:
                Argument."Result Integer" := 8192;
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
        ConfigJson.Add('timeoutMs', ProviderBase.GetTimeoutMs(Argument, 300000));
        ConfigJson.Add('maxTokens', ProviderBase.GetMaxTokens(Argument, 8192));
        ConfigJson.WriteTo(ConfigText);
        exit(ConfigText);
    end;

    local procedure DoSendChatMessage(var Argument: Record "MCP Chat Argument ori" temporary): Text
    var
        LLMChatProxy: Codeunit "CE Chat Proxy ori";
    begin
        exit(LLMChatProxy.SendChatMessage(Argument, Argument.GetPayload(), AuthHeaderNameTok));
    end;

    local procedure DoContinueWithToolResults(var Argument: Record "MCP Chat Argument ori" temporary): Text
    var
        LLMChatProxy: Codeunit "CE Chat Proxy ori";
    begin
        exit(LLMChatProxy.ContinueWithToolResults(Argument, Argument.GetConversationState(), Argument.GetToolResults(), AuthHeaderNameTok));
    end;

    local procedure DoGetAvailableModels(var Argument: Record "MCP Chat Argument ori" temporary): Boolean
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ApiClient: Codeunit "CE Chat API Client ori";
        ModelsArray: JsonArray;
        ModelToken: JsonToken;
        ModelObject: JsonObject;
        BaseUrl: Text;
        IdValue: Text;
        EntryNo: Integer;
    begin
        BaseUrl := ProviderBase.GetBaseUrl(Argument, '');
        if BaseUrl = '' then
            exit(false);

        ModelsArray := ApiClient.ListModelsFromEndpoint(BaseUrl + '/v1/models', AuthHeaderNameTok, Argument.GetApiKey());

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

    local procedure DoTestConnection(var Argument: Record "MCP Chat Argument ori" temporary): Boolean
    var
        ApiClient: Codeunit "CE Chat API Client ori";
        BaseUrl: Text;
        NoBaseUrlErr: Label 'No Base URL configured for this role.', Comment = 'is-IS=Engin grunnslóð stillt fyrir þetta hlutverk.';
    begin
        BaseUrl := ProviderBase.GetBaseUrl(Argument, '');
        if BaseUrl = '' then begin
            Argument.SetErrorMessage(NoBaseUrlErr);
            exit(false);
        end;
        ApiClient.ListModelsFromEndpoint(BaseUrl + '/v1/models', AuthHeaderNameTok, Argument.GetApiKey());
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

    local procedure GetJsonText(JObject: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.Get(PropertyName, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsText());
    end;
}
