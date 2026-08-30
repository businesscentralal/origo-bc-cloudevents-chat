namespace Origo.APP.CloudEvents.Chat;

/// <summary>
/// Grants permissions to all objects in the Cloud Events Chat extension.
/// </summary>
permissionset 10035486 "CE Chat Obj ori"
{
    Caption = 'Cloud Events Chat', Comment = 'is-IS=Atburðir í skýinu - LLM';
    Assignable = true;
    Access = Public;

    Permissions =
        table "CE Chat Service Gate ori" = X,
        codeunit "CE Chat Proxy ori" = X,
        codeunit "CE Chat Provider Base ori" = X,
        codeunit "CE Chat Http Notif. Action ori" = X,
        codeunit "CE Chat Req Log Masker ori" = X,
        codeunit "CE Chat OpenAI Impl ori" = X,
        codeunit "CE Chat Azure OAI Impl ori" = X,
        codeunit "CE Chat Custom Impl ori" = X,
        codeunit "CE Chat Anthropic Impl ori" = X,
        codeunit "CE Chat Anthropic Proxy ori" = X,
        codeunit "CE Chat API Client ori" = X,
        codeunit "CE Chat Tool Runner ori" = X,
        codeunit "CE Chat Wizard Reg. ori" = X,
        codeunit "CE Chat Overview Sub ori" = X,
        page "CE Chat Setup Wizard ori" = X;
}
