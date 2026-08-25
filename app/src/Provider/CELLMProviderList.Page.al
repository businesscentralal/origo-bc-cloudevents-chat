namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// List page for managing LLM provider configurations.
/// </summary>
page 10035486 "CE LLM Provider List ori"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "CE LLM Provider Setup ori";
    Caption = 'LLM Providers', Comment = 'is-IS=LLM veitur';
    CardPageId = "CE LLM Provider Card ori";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Providers)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the provider code.', Comment = 'is-IS=Tilgreinir kóða veitunnar.';
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the provider name.', Comment = 'is-IS=Tilgreinir heiti veitunnar.';
                }
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API base URL.', Comment = 'is-IS=Tilgreinir API grunnvefslóð.';
                }
                field("Auth Type"; Rec."Auth Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the authentication type.', Comment = 'is-IS=Tilgreinir auðkenningartegund.';
                }
                field("Default Model"; Rec."Default Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default model.', Comment = 'is-IS=Tilgreinir sjálfgefið líkan.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this provider is active.', Comment = 'is-IS=Tilgreinir hvort veitan sé virk.';
                }
            }
        }
    }
}
