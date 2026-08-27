namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// Grants permissions to all objects in the Cloud Events LLM extension.
/// </summary>
permissionset 10035486 "CE LLM Obj ori"
{
    Caption = 'Cloud Events LLM', Comment = 'is-IS=Atburðir í skýinu - LLM';
    Assignable = true;
    Access = Public;

    Permissions =
        table "CE LLM Service Gate ori" = X,
        codeunit "CE LLM Chat Proxy ori" = X,
        codeunit "CE LLM Provider Base ori" = X,
        codeunit "CE LLM Http Notif. Action ori" = X,
        codeunit "CE LLM Req Log Masker ori" = X,
        codeunit "CE LLM OpenAI Impl ori" = X,
        codeunit "CE LLM Azure OAI Impl ori" = X,
        codeunit "CE LLM Custom Impl ori" = X,
        codeunit "CE LLM API Client ori" = X,
        codeunit "CE LLM Model Call Impl ori" = X,
        codeunit "CE LLM Model Call Help ori" = X,
        codeunit "CE LLM Model List Impl ori" = X,
        codeunit "CE LLM Model List Help ori" = X,
        codeunit "CE LLM Provider List Impl ori" = X,
        codeunit "CE LLM Tool Runner ori" = X;
}
