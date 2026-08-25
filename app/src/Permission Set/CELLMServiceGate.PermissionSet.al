namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// Grants access to the LLM service API key and setup fields.
/// Users with this permission set can view/edit the service key and default model
/// on the Cloud Events Setup page, and use the shared service key for chat.
/// </summary>
permissionset 10035488 "CE LLM Svc ori"
{
    Assignable = true;
    Caption = 'LLM Service Gate', MaxLength = 30, Comment = 'is-IS=LLM þjónustuhlið';

    Permissions =
        tabledata "CE LLM Service Gate ori" = RIMD;
}
