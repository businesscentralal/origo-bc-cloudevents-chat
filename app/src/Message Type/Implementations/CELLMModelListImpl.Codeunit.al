namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the LLM.Model.List message type.
/// Returns the models available on the configured LLM endpoint, so callers can
/// pick a valid model id for LLM.Model.Call.
/// </summary>
codeunit 10035493 "CE LLM Model List Impl ori" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    /// <summary>
    /// Determines whether this message type is enabled.
    /// </summary>
    internal procedure IsEnabled(): Boolean
    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        exit(LLMChatSetup.HasServiceGate());
    end;

    /// <summary>
    /// Returns the table ID used to filter records for this message type.
    /// </summary>
    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Returns a human-readable description of this message type.
    /// </summary>
    internal procedure GetDescription() Description: Text[250]
    var
        DescriptionLbl: Label 'List the LLM models available on the configured endpoint.', Comment = 'is-IS=Telja upp LLM líkön sem eru tiltæk á uppsettu endapunkti.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Returns the message direction for this message type.
    /// </summary>
    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    /// <summary>
    /// Returns Markdown help documentation for this message type.
    /// </summary>
    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpCodeunit: Codeunit "CE LLM Model List Help ori";
    begin
        Argument.SetResponseMarkdown(HelpCodeunit.GetHelpText());
    end;

    /// <summary>
    /// Retrieves the available models from the LLM endpoint and returns them as JSON.
    /// </summary>
    [NonDebuggable]
    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
        ApiClient: Codeunit "CE LLM API Client ori";
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
        ResponseJson: JsonObject;
        ModelsJson: JsonArray;
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if not LLMChatSetup.AssertServiceGate(Argument) then
            exit;

        ModelsJson := ApiClient.ListModels();

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('noOfRecords', ModelsJson.Count());
        ResponseJson.Add('defaultModel', CloudEventsSetup.GetLLMDefaultModel());
        ResponseJson.Add('result', ModelsJson);
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;
}
