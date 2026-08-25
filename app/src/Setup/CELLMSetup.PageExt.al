namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;
using System.Apps;
using System.Environment.Configuration;

/// <summary>
/// Extends the Cloud Events Setup page with the default LLM provider and navigation.
/// </summary>
pageextension 10035485 "CE LLM Setup ori" extends "Cloud Events Setup ori"
{
    layout
    {
        addafter(EnvironmentGrp)
        {
            group(ori_LLMChat)
            {
                Caption = 'LLM Chat', Comment = 'is-IS=LLM-spjall';
                Visible = HasServiceGateAccess;

                field(ori_LLMDefProvider; Rec."CE LLM Def. Provider Code ori")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default LLM provider for server-side calls and as fallback when no provider is set on the Chat Role.', Comment = 'is-IS=Tilgreinir sjálfgefna LLM veitu fyrir þjónustuköll og sem varakost þegar engin veita er stillt á spjallhlutverkinu.';
                    Editable = PageIsEditable;
                }
            }
        }
    }

    actions
    {
        addlast(Navigation)
        {
            action(ori_LLMProviders)
            {
                ApplicationArea = All;
                Caption = 'LLM Providers', Comment = 'is-IS=LLM veitur';
                ToolTip = 'Open the LLM Provider Setup to configure endpoints, authentication, and models.', Comment = 'is-IS=Opna uppsetningu LLM veitu til að stilla endapunkta, auðkenningu og líkön.';
                Image = Setup;
                RunObject = page "CE LLM Provider List ori";
                Visible = HasServiceGateAccess;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowHttpClientNotification();
    end;

    local procedure ShowHttpClientNotification()
    var
        NavAppSetting: Record "NAV App Setting";
        HttpNotification: Notification;
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if NavAppSetting.Get(AppInfo.Id()) then
            if NavAppSetting."Allow HttpClient Requests" then
                exit;

        HttpNotification.Id := 'e7b4a2c1-3f8d-4e5a-9c6b-2d1f0e8a7b3c';
        HttpNotification.Scope := NotificationScope::LocalScope;
        HttpNotification.Message := HttpClientDisabledMsg;
        HttpNotification.AddAction(EnableHttpClientLbl, Codeunit::"CE LLM Http Notif. Action ori", 'OpenExtensionSettings');
        HttpNotification.Send();
    end;

    var
        PageIsEditable: Boolean;
        HasServiceGateAccess: Boolean;
        HttpClientDisabledMsg: Label 'HTTP client requests are not enabled for the Cloud Events LLM extension. The LLM chat and model lookup will not work until an administrator enables Allow HttpClient Requests in Extension Settings.', Comment = 'is-IS=HTTP-biðlarabeiðnir eru ekki virkar fyrir Cloud Events LLM viðbótina. LLM spjall og líkanauppfletting virka ekki fyrr en kerfisstjóri virkjar Leyfa HttpClient-beiðnir í stillingum viðbótar.';
        EnableHttpClientLbl: Label 'Open Extension Settings', Comment = 'is-IS=Opna stillingar viðbótar';

    trigger OnAfterGetCurrRecord()
    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        HasServiceGateAccess := LLMChatSetup.HasServiceGate();
        PageIsEditable := CurrPage.Editable;
    end;
}
