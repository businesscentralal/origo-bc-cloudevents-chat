namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;

codeunit 10035510 "CE Chat Overview Sub ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cloud Event Message Events ori", 'OnAfterCreatingOverview', '', false, false)]
    local procedure OnAfterCreatingOverview(Overview: TextBuilder)
    begin
        Overview.AppendLine('| `Help.CloudEvents.Chat.Get` | AI Chat providers — OpenAI, Azure OpenAI, Anthropic Claude, Google Gemini, xAI Grok, and custom LLM endpoints for MCP Chat with tool execution. |');
    end;
}
