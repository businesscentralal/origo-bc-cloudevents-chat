namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends the Cloud Events Full permission set with LLM Chat objects.
/// </summary>
permissionsetextension 10035485 "CE Chat Full ori" extends "CE Full Access ori"
{
    Permissions =
        codeunit "CE Chat Proxy ori" = X,
        codeunit "CE Chat Provider Base ori" = X;
}
