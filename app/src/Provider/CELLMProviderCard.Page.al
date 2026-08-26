namespace Origo.APP.CloudEvents.LLM;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;

/// <summary>
/// Card page for editing a single LLM provider configuration.
/// </summary>
page 10035485 "CE LLM Provider Card ori"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "CE LLM Provider Setup ori";
    Caption = 'LLM Provider', Comment = 'is-IS=LLM veita';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';

                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for this provider (e.g. OLLAMA, OPENAI, GROK).', Comment = 'is-IS=Tilgreinir einkvæman kóða fyrir þessa veitu.';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display name for this provider.', Comment = 'is-IS=Tilgreinir birtingarheiti veitunnar.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this provider is available for selection.', Comment = 'is-IS=Tilgreinir hvort þessi veita sé tiltæk til vals.';
                }
            }
            group(Connection)
            {
                Caption = 'Connection', Comment = 'is-IS=Tenging';

                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL for the LLM API (e.g. https://api.openai.com). The chat path is appended automatically.', Comment = 'is-IS=Tilgreinir grunnvefslóð LLM API. Spjallslóðin er bætt við sjálfkrafa.';
                }
                field("Auth Type"; Rec."Auth Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how the API key is sent: x-api-key header (reverse proxy), Bearer token (OpenAI-compatible), or api-key header (Azure).', Comment = 'is-IS=Tilgreinir hvernig API-lykillinn er sendur.';

                    trigger OnValidate()
                    begin
                        UpdateVisibility();
                        CurrPage.Update(false);
                    end;
                }
                field("Chat Path"; Rec."Chat Path")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ShowMandatory = ChatPathRequired;
                    ToolTip = 'Specifies the path appended to the base URL for chat completions. Default: /v1/chat/completions.', Comment = 'is-IS=Tilgreinir slóðina sem bætt er við grunnvefslóð fyrir spjallsvörun.';
                }
                field("Models Path"; Rec."Models Path")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ShowMandatory = ModelsPathRequired;
                    ToolTip = 'Specifies the path for listing available models. Default: /v1/models.', Comment = 'is-IS=Tilgreinir slóðina til að birta tiltæk líkön.';
                }
            }
            group(Model)
            {
                Caption = 'Model', Comment = 'is-IS=Líkan';

                field("Default Model"; Rec."Default Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default model for this provider. Used when no model is specified on the Chat Role.', Comment = 'is-IS=Tilgreinir sjálfgefið líkan þessarar veitu.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
                        ApiClient: Codeunit "CE LLM API Client ori";
                        ModelList: Page "MCP Chat Model List ori";
                        Models: JsonArray;
                        ModelToken: JsonToken;
                        ModelObj: JsonObject;
                        IdToken: JsonToken;
                        EntryNo: Integer;
                    begin
                        if not Rec.HasApiKey() then
                            exit(false);
                        Commit();
                        Models := ApiClient.ListModelsForProvider(Rec);
                        foreach ModelToken in Models do begin
                            EntryNo += 1;
                            ModelObj := ModelToken.AsObject();
                            if ModelObj.Get('id', IdToken) then begin
                                TempNameValueBuffer.Init();
                                TempNameValueBuffer.ID := EntryNo;
                                TempNameValueBuffer.Name := CopyStr(IdToken.AsValue().AsText(), 1, MaxStrLen(TempNameValueBuffer.Name));
                                TempNameValueBuffer.Insert();
                            end;
                        end;

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
                field("Timeout Seconds"; Rec."Timeout Seconds")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the HTTP timeout in seconds. Default: 300 (5 minutes).', Comment = 'is-IS=Tilgreinir HTTP tímamörk í sekúndum.';
                }
                field("Max Tokens"; Rec."Max Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum output tokens per API call. Default: 4096.', Comment = 'is-IS=Tilgreinir hámarksfjölda úttaksmerkja.';
                }
            }
            group(Authentication)
            {
                Caption = 'Authentication', Comment = 'is-IS=Auðkenning';

                field(ServiceApiKey; ServiceKeyInput)
                {
                    ApplicationArea = All;
                    Caption = 'Service API Key', Comment = 'is-IS=Þjónustulykill';
                    ToolTip = 'Specifies the shared API key for this provider. Gated by the CE LLM Svc permission set.', Comment = 'is-IS=Tilgreinir sameiginlegan API-lykil fyrir þessa veitu.';
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        Rec.SetServiceApiKey(ServiceKeyInput);
                        Clear(ServiceKeyInput);
                        HasServiceKey := Rec.HasServiceApiKey();
                        CurrPage.Update(false);
                    end;
                }
                field(HasServiceKeyField; HasServiceKey)
                {
                    ApplicationArea = All;
                    Caption = 'Service Key Stored', Comment = 'is-IS=Þjónustulykill geymdur';
                    ToolTip = 'Indicates whether a shared service API key is stored for this provider.', Comment = 'is-IS=Gefur til kynna hvort sameiginlegur þjónustulykill sé geymdur.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(TestConnectionRef; TestConnection) { }
        }
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection', Comment = 'is-IS=Prófa tengingu';
                ToolTip = 'Tests connectivity by calling the models endpoint using your credentials.', Comment = 'is-IS=Prófar tengingu með því að kalla á líkanaendapunkt með þínum aðgangsupplýsingum.';
                Image = TestFile;
                Visible = ShowTestConnection;

                trigger OnAction()
                var
                    ApiClient: Codeunit "CE LLM API Client ori";
                    Models: JsonArray;
                begin
                    if not Rec.HasApiKey() then
                        Error(NoApiKeyErr);
                    Models := ApiClient.ListModelsForProvider(Rec);
                    Message(ConnectionOkMsg, Models.Count());
                end;
            }
        }
    }

    var
        [NonDebuggable]
        ServiceKeyInput: Text;
        HasServiceKey: Boolean;
        ShowChatPath: Boolean;
        ShowModelsPath: Boolean;
        ChatPathRequired: Boolean;
        ModelsPathRequired: Boolean;
        ShowTestConnection: Boolean;
        ConnectionOkMsg: Label 'Connection successful. %1 model(s) available.', Comment = '%1 = count, is-IS=Tenging tókst. %1 líkan/líkön tiltæk.';
        NoApiKeyErr: Label 'No API key available for this provider. Set a personal key or a service key before testing.', Comment = 'is-IS=Enginn API-lykill tiltækur fyrir þessa veitu. Stilltu persónulegan lykil eða þjónustulykil áður en þú prófar.';

    trigger OnAfterGetCurrRecord()
    begin
        HasServiceKey := Rec.HasServiceApiKey();
        if HasServiceKey then
            ServiceKeyInput := '********'
        else
            ServiceKeyInput := '';
        UpdateVisibility();
    end;

    local procedure UpdateVisibility()
    var
        AuthConfig: Interface "CE LLM Auth Config ori";
    begin
        AuthConfig := Rec."Auth Type";
        ShowChatPath := AuthConfig.ShowChatPath();
        ShowModelsPath := AuthConfig.ShowModelsPath();
        ChatPathRequired := ShowChatPath;
        ModelsPathRequired := ShowModelsPath;
        ShowTestConnection := AuthConfig.SupportsModelLookup();
    end;
}
