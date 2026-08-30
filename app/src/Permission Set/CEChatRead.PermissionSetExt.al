namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends the Cloud Events Read permission set with LLM Chat objects (read-only).
/// </summary>
permissionsetextension 10035487 "CE Chat Read ori" extends "CE Read All ori"
{
    Permissions =
        codeunit "CE Chat Proxy ori" = X,
        codeunit "CE Chat Provider Base ori" = X;
}
