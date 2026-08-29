namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;
using System.Apps;
using System.Environment.Configuration;

/// <summary>
/// Setup wizard for Cloud Events Chat. Guides the user through HTTP client
/// verification and directs them to configure MCP Chat Roles with LLM providers.
/// </summary>
page 10035507 "CE Chat Setup Wizard ori"
{
    PageType = NavigatePage;
    Caption = 'Cloud Events Chat Setup', Comment = 'is-IS=Uppsetning Cloud Events spjalls';
    ApplicationArea = All;
    Editable = true;
    ContextSensitiveHelpPage = 'ChatSetup.html';

    layout
    {
        area(Content)
        {
            group(Step1Welcome)
            {
                Visible = (CurrentStep = 1);
                group(WelcomeHeader)
                {
                    Caption = 'Welcome to Cloud Events Chat', Comment = 'is-IS=Velkomin í Cloud Events spjall';
                    ShowCaption = true;
                    InstructionalText = 'This wizard helps you set up AI Chat providers for Cloud Events. The extension adds OpenAI, Azure OpenAI, Custom LLM, and Anthropic Claude as MCP Chat providers, enabling AI-powered chat with tool execution against live Business Central data.', Comment = 'is-IS=Þessi leiðsögn hjálpar þér að setja upp gervigreindarveitendur fyrir Cloud Events spjall. Viðbótin bætir við OpenAI, Azure OpenAI, sérsniðnu LLM og Anthropic Claude sem MCP spjallveitendur, sem virkjar gervigreindarspjall með verkfærakeyrslu gegn lifandi Business Central gögnum.';
                }
                group(WelcomeNote)
                {
                    Caption = 'Note', Comment = 'is-IS=Athugasemd';
                    InstructionalText = 'You need an API key from at least one LLM provider (OpenAI, Azure OpenAI, Anthropic, or a self-hosted endpoint) to use the chat functionality.', Comment = 'is-IS=Þú þarft API-lykil frá að minnsta kosti einum LLM-veitanda (OpenAI, Azure OpenAI, Anthropic, eða eigin endapunkt) til að nota spjallaðgerðina.';
                }
            }
            group(Step2Http)
            {
                Visible = (CurrentStep = 2);
                group(HttpHeader)
                {
                    Caption = 'Enable HTTP Client Requests', Comment = 'is-IS=Virkja HTTP-biðlarabeiðnir';
                    InstructionalText = 'Cloud Events Chat requires outbound HTTP to communicate with LLM providers. Please enable Allow HttpClient Requests for this extension.', Comment = 'is-IS=Cloud Events spjall þarf útleið HTTP til að eiga samskipti við LLM-veitendur. Vinsamlegast virkjaðu Leyfa HttpClient-beiðnir fyrir þessa viðbót.';
                }
                group(HttpStatus)
                {
                    Caption = 'Status', Comment = 'is-IS=Staða';
                    field(HttpEnabledField; HttpStatusTxt)
                    {
                        Caption = 'HTTP Client Requests', Comment = 'is-IS=HTTP-biðlarabeiðnir';
                        ToolTip = 'Shows whether HTTP client requests are currently enabled for this extension.', Comment = 'is-IS=Sýnir hvort HTTP-biðlarabeiðnir séu virkar fyrir þessa viðbót.';
                        Editable = false;
                        StyleExpr = HttpStatusStyle;
                    }
                }
            }
            group(Step3Providers)
            {
                Visible = (CurrentStep = 3);
                group(ProvidersHeader)
                {
                    Caption = 'Configure a Chat Provider', Comment = 'is-IS=Stilla spjallveitanda';
                    InstructionalText = 'Chat providers are configured through MCP Chat Roles. Create a role, select a provider type, enter your API key, and set the model. Use the button below to open the MCP Chat Role List.', Comment = 'is-IS=Spjallveitendur eru stilltir í gegnum MCP spjallhlutverk. Búðu til hlutverk, veldu tegund veitanda, sláðu inn API-lykilinn þinn og stilltu líkanið. Notaðu hnappinn hér fyrir neðan til að opna MCP spjallhlutverkalista.';
                }
                group(ProviderList)
                {
                    Caption = 'Available Providers', Comment = 'is-IS=Tiltækir veitendur';
                    InstructionalText = 'OpenAI — for OpenAI, Grok, Groq, Together, Mistral, DeepSeek and other Bearer-auth endpoints. Azure OpenAI — for Azure OpenAI Service deployments. Custom LLM — for Ollama, vLLM, LM Studio, or any x-api-key endpoint. Anthropic — for Anthropic Claude models.', Comment = 'is-IS=OpenAI — fyrir OpenAI, Grok, Groq, Together, Mistral, DeepSeek og aðra Bearer-auth endapunkta. Azure OpenAI — fyrir Azure OpenAI Service dreifingar. Sérsniðið LLM — fyrir Ollama, vLLM, LM Studio eða hvaða x-api-key endapunkt sem er. Anthropic — fyrir Anthropic Claude líkön.';
                }
                group(ProviderStatusGroup)
                {
                    Caption = 'Status', Comment = 'is-IS=Staða';
                    field(ProviderStatusField; ProviderStatusTxt)
                    {
                        Caption = 'Chat Roles Configured', Comment = 'is-IS=Spjallhlutverk stillt';
                        ToolTip = 'Shows whether any MCP Chat Roles have been configured with an LLM provider.', Comment = 'is-IS=Sýnir hvort einhver MCP spjallhlutverk hafa verið stillt með LLM-veitanda.';
                        Editable = false;
                        StyleExpr = ProviderStatusStyle;
                    }
                }
            }
            group(Step4Finish)
            {
                Visible = (CurrentStep = 4);
                group(FinishHeader)
                {
                    Caption = 'Setup Complete', Comment = 'is-IS=Uppsetningu lokið';
                    InstructionalText = 'The Cloud Events Chat setup is complete. You can always change these settings later from the MCP Chat Role List or Extension Management pages.', Comment = 'is-IS=Uppsetning Cloud Events spjalls er lokið. Þú getur alltaf breytt þessum stillingum síðar á MCP spjallhlutverkalista eða Stjórnun viðbóta síðum.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                Caption = 'Back', Comment = 'is-IS=Til baka';
                Image = PreviousRecord;
                InFooterBar = true;
                Enabled = BackEnabled;

                trigger OnAction()
                begin
                    CurrentStep -= 1;
                    UpdateControls();
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next', Comment = 'is-IS=Áfram';
                Image = NextRecord;
                InFooterBar = true;
                Enabled = NextEnabled;
                Visible = (CurrentStep < 4);

                trigger OnAction()
                begin
                    CurrentStep += 1;
                    OnStepEnter();
                    UpdateControls();
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish', Comment = 'is-IS=Ljúka';
                Image = Approve;
                InFooterBar = true;
                Visible = (CurrentStep = 4);

                trigger OnAction()
                begin
                    FinishWizard();
                    CurrPage.Close();
                end;
            }
            action(ActionEnableHttp)
            {
                Caption = 'Enable HTTP Client Requests', Comment = 'is-IS=Virkja HTTP-biðlarabeiðnir';
                Image = Setup;
                InFooterBar = true;
                Visible = (CurrentStep = 2) and (not HttpEnabled) and CanWriteAppSetting;

                trigger OnAction()
                begin
                    EnableHttpClientRequests();
                    CheckHttpEnabled();
                    UpdateControls();
                end;
            }
            action(ActionOpenExtSettings)
            {
                Caption = 'Open Extension Settings', Comment = 'is-IS=Opna stillingar viðbótar';
                Image = Setup;
                InFooterBar = true;
                Visible = (CurrentStep = 2) and (not HttpEnabled) and (not CanWriteAppSetting);

                trigger OnAction()
                begin
                    Hyperlink(GetUrl(ClientType::Web, CompanyName, ObjectType::Page, 2500));
                end;
            }
            action(ActionRefreshHttp)
            {
                Caption = 'Verify', Comment = 'is-IS=Staðfesta';
                Image = Refresh;
                InFooterBar = true;
                Visible = (CurrentStep = 2);

                trigger OnAction()
                begin
                    CheckHttpEnabled();
                    UpdateControls();
                end;
            }
            action(ActionOpenChatRoles)
            {
                Caption = 'Open MCP Chat Role List', Comment = 'is-IS=Opna MCP spjallhlutverkalista';
                Image = Setup;
                InFooterBar = true;
                Visible = (CurrentStep = 3);

                trigger OnAction()
                begin
                    OpenChatRoleList();
                end;
            }
        }
    }

    var
        HttpStatusTxt: Text;
        HttpStatusStyle: Text;
        ProviderStatusTxt: Text;
        ProviderStatusStyle: Text;
        HttpEnabled: Boolean;
        CanWriteAppSetting: Boolean;
        NextEnabled: Boolean;
        BackEnabled: Boolean;
        CurrentStep: Integer;
        HttpEnabledTok: Label 'Enabled', Comment = 'is-IS=Virkt';
        HttpDisabledTok: Label 'Not Enabled - Please enable Allow HttpClient Requests', Comment = 'is-IS=Ekki virkt - Vinsamlegast virkjaðu Leyfa HttpClient-beiðnir';
        ProvidersConfiguredTok: Label '%1 role(s) configured', Comment = 'is-IS=%1 hlutverk stillt, %1 = number of configured roles';
        NoProvidersConfiguredTok: Label 'No chat roles configured yet', Comment = 'is-IS=Engin spjallhlutverk stillt enn';

    trigger OnOpenPage()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        CurrentStep := 1;
        InitializeData();
        if GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"CE Chat Setup Wizard ori") then
            CurrentStep := 4;
        UpdateControls();
    end;

    local procedure InitializeData()
    var
        NavAppSetting: Record "NAV App Setting";
    begin
        CanWriteAppSetting := NavAppSetting.WritePermission();
        CheckHttpEnabled();
    end;

    local procedure OnStepEnter()
    begin
        case CurrentStep of
            2:
                CheckHttpEnabled();
            3:
                CheckProviderStatus();
        end;
    end;

    local procedure UpdateControls()
    begin
        BackEnabled := CurrentStep > 1;
        case CurrentStep of
            2:
                NextEnabled := HttpEnabled;
            else
                NextEnabled := true;
        end;
    end;

    local procedure CheckHttpEnabled()
    var
        NavAppSetting: Record "NAV App Setting";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        HttpEnabled := NavAppSetting.Get(AppInfo.Id()) and NavAppSetting."Allow HttpClient Requests";
        if HttpEnabled then begin
            HttpStatusTxt := HttpEnabledTok;
            HttpStatusStyle := 'Favorable';
        end else begin
            HttpStatusTxt := HttpDisabledTok;
            HttpStatusStyle := 'Unfavorable';
        end;
    end;

    local procedure EnableHttpClientRequests()
    var
        NavAppSetting: Record "NAV App Setting";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if not NavAppSetting.Get(AppInfo.Id()) then begin
            NavAppSetting.Init();
            NavAppSetting."App ID" := AppInfo.Id();
            NavAppSetting.Insert();
        end;
        NavAppSetting."Allow HttpClient Requests" := true;
        NavAppSetting.Modify();
    end;

    local procedure CheckProviderStatus()
    var
        ConfiguredCount: Integer;
    begin
        ConfiguredCount := GetConfiguredRoleCount();
        if ConfiguredCount > 0 then begin
            ProviderStatusTxt := StrSubstNo(ProvidersConfiguredTok, ConfiguredCount);
            ProviderStatusStyle := 'Favorable';
        end else begin
            ProviderStatusTxt := NoProvidersConfiguredTok;
            ProviderStatusStyle := 'Ambiguous';
        end;
    end;

    local procedure GetConfiguredRoleCount(): Integer
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
    begin
        // HasServiceGate checks if any MCP Chat Role has a provider set
        if ProviderBase.HasServiceGate() then
            exit(1);
        exit(0);
    end;

    local procedure OpenChatRoleList()
    begin
        Page.Run(Page::"MCP Chat Role List ori");
    end;

    local procedure FinishWizard()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"CE Chat Setup Wizard ori");
    end;
}
