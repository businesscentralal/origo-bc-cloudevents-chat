namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends the Cloud Events Full permission set with LLM Chat objects.
/// </summary>
permissionsetextension 10035485 "CE LLM Full ori" extends "CE Full Access ori"
{
    Permissions =
        codeunit "CE LLM Chat Setup ori" = X,
        codeunit "CE LLM Chat Proxy ori" = X,
        codeunit "CE LLM Chat Prov Impl ori" = X;
}
