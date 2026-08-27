namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends the Cloud Events Read permission set with LLM Chat objects (read-only).
/// </summary>
permissionsetextension 10035487 "CE LLM Read ori" extends "CE Read All ori"
{
    Permissions =
        codeunit "CE LLM Chat Proxy ori" = X,
        codeunit "CE LLM Provider Base ori" = X;
}
