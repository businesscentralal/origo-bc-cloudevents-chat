namespace Origo.APP.CloudEvents.Chat;

using System.Environment.Configuration;
using System.Media;

/// <summary>
/// Registers the Cloud Events Chat setup wizard with Assisted Setup.
/// </summary>
codeunit 10035508 "CE Chat Wizard Reg. ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", OnRegisterAssistedSetup, '', false, false)]
    local procedure RegisterChatSetupWizard()
    var
        GuidedExperience: Codeunit "Guided Experience";
        SetupTitleTok: Label 'Set up Cloud Events Chat', Comment = 'is-IS=Setja upp Cloud Events spjall';
        SetupShortTitleTok: Label 'Cloud Events Chat', Comment = 'is-IS=Cloud Events spjall';
        SetupDescriptionTok: Label 'Configure AI Chat providers: enable HTTP client requests and set up MCP Chat Roles with LLM provider API keys.', Comment = 'is-IS=Stilla gervigreindar spjallveitendur: virkja HTTP-biðlarabeiðnir og setja upp MCP spjallhlutverk með LLM-veitanda API-lyklum.';
    begin
        GuidedExperience.InsertAssistedSetup(
            SetupTitleTok,
            SetupShortTitleTok,
            SetupDescriptionTok,
            10,
            ObjectType::Page,
            Page::"CE Chat Setup Wizard ori",
            Enum::"Assisted Setup Group"::Extensions,
            '',
            Enum::"Video Category"::Uncategorized,
            '');
    end;
}
