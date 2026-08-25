namespace Origo.APP.CloudEvents.LLM;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;
using System.Apps;
using System.Environment.Configuration;

/// <summary>
/// Extends the Cloud Events Setup page with LLM configuration fields.
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

                field(ori_LLMBaseUrl; Rec."CE LLM Base URL ori")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL for the LLM endpoint (e.g. https://llm.kappi.is). The /v1/chat/completions path is appended automatically.', Comment = 'is-IS=Tilgreinir grunnvefslóð LLM endapunktsins. /v1/chat/completions slóðin er bætt við sjálfkrafa.';
                    Editable = PageIsEditable;
                }
                field(ori_LLMServiceApiKey; LLMServiceKeyInput)
                {
                    ApplicationArea = All;
                    Caption = 'Service API Key', Comment = 'is-IS=Þjónustulykill';
                    ToolTip = 'Specifies the API key used to authenticate with the LLM endpoint. The value is stored encrypted in IsolatedStorage and is not displayed again after saving.', Comment = 'is-IS=Tilgreinir API-lykilinn sem notaður er til auðkenningar við LLM endapunktinn. Gildið er geymt dulkóðað í IsolatedStorage og er ekki sýnt aftur eftir vistun.';
                    Editable = PageIsEditable;
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        Rec.SetLLMServiceApiKey(LLMServiceKeyInput);
                        Clear(LLMServiceKeyInput);
                        LLMServiceKeySet := Rec.HasLLMServiceApiKey();
                        CurrPage.Update(false);
                    end;
                }
                field(ori_LLMDefaultModel; Rec."CE LLM Default Model ori")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default LLM model used for server-side calls (e.g. qwen3:8b). Leave blank to use the built-in default.', Comment = 'is-IS=Tilgreinir sjálfgefið LLM líkan fyrir þjónustuköll. Skildu eftir autt til að nota innbyggð sjálfgefið gildi.';
                    Editable = PageIsEditable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
                        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
                        ModelList: Page "MCP Chat Model List ori";
                    begin
                        if not HttpClientAllowed then
                            exit(false);
                        Commit();
                        if not LLMChatSetup.GetAvailableModels(TempNameValueBuffer) then
                            exit(false);

                        if Text <> '' then begin
                            TempNameValueBuffer.SetRange(Name, Text);
                            if TempNameValueBuffer.FindFirst() then;
                            TempNameValueBuffer.SetRange(Name);
                        end;

                        ModelList.Set(TempNameValueBuffer);
                        ModelList.LookupMode := true;
                        if ModelList.RunModal() = Action::LookupOK then begin
                            ModelList.GetRecord(TempNameValueBuffer);
                            Text := TempNameValueBuffer.Name;
                            exit(true);
                        end;
                    end;
                }
                field(ori_LLMTimeout; Rec."CE LLM Timeout ori")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the HTTP timeout in seconds for LLM API calls. Default is 300 (5 minutes). Increase if complex tool chains time out.', Comment = 'is-IS=Tilgreinir HTTP tímamörk í sekúndum fyrir LLM API köll. Sjálfgefið er 300 (5 mínútur). Hækkaðu ef flókin tólakeðjur renna út á tíma.';
                    Editable = PageIsEditable;
                }
                field(ori_LLMMaxTokens; Rec."CE LLM Max Tokens ori")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum output tokens per API call. Default is 4096.', Comment = 'is-IS=Tilgreinir hámarksfjölda úttaksmerkja á hvert API kall. Sjálfgefið er 4096.';
                    Editable = PageIsEditable;
                }
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
            if NavAppSetting."Allow HttpClient Requests" then begin
                HttpClientAllowed := true;
                exit;
            end;

        HttpClientAllowed := false;
        HttpNotification.Id := 'e7b4a2c1-3f8d-4e5a-9c6b-2d1f0e8a7b3c';
        HttpNotification.Scope := NotificationScope::LocalScope;
        HttpNotification.Message := HttpClientDisabledMsg;
        HttpNotification.AddAction(EnableHttpClientLbl, Codeunit::"CE LLM Http Notif. Action ori", 'OpenExtensionSettings');
        HttpNotification.Send();
    end;

    var
        [NonDebuggable]
        LLMServiceKeyInput: Text;
        LLMServiceKeySet: Boolean;
        PageIsEditable: Boolean;
        HasServiceGateAccess: Boolean;
        HttpClientAllowed: Boolean;
        HttpClientDisabledMsg: Label 'HTTP client requests are not enabled for the Cloud Events LLM extension. The LLM chat and model lookup will not work until an administrator enables Allow HttpClient Requests in Extension Settings.', Comment = 'is-IS=HTTP-biðlarabeiðnir eru ekki virkar fyrir Cloud Events LLM viðbótina. LLM spjall og líkanauppfletting virka ekki fyrr en kerfisstjóri virkjar Leyfa HttpClient-beiðnir í stillingum viðbótar.';
        EnableHttpClientLbl: Label 'Open Extension Settings', Comment = 'is-IS=Opna stillingar viðbótar';

    trigger OnAfterGetCurrRecord()
    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        HasServiceGateAccess := LLMChatSetup.HasServiceGate();
        if HasServiceGateAccess then begin
            LLMServiceKeySet := Rec.HasLLMServiceApiKey();
            if LLMServiceKeySet then
                LLMServiceKeyInput := '********';
        end;
        PageIsEditable := CurrPage.Editable;
    end;
}
