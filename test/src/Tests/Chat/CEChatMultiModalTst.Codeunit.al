namespace Origo.APP.CloudEvents.Chat;

using System.TestLibraries.Utilities;

/// <summary>
/// Tests for multi-modal content building, error detail parsing,
/// and response text extraction across provider formats.
/// </summary>
codeunit 95907 "CE Chat Multi Modal Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure AttachFiles_AddsImageUrlBlock()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        PayloadObject: JsonObject;
        Messages: JsonArray;
        UserMsg: JsonObject;
        FilesArray: JsonArray;
        FileObj: JsonObject;
        LastMsg: JsonToken;
        ContentToken: JsonToken;
        ContentArray: JsonArray;
        FirstBlock: JsonToken;
    begin
        // [GIVEN] A user message and a PNG file in the payload
        UserMsg.Add('role', 'user');
        UserMsg.Add('content', 'Describe this image');
        Messages.Add(UserMsg);

        FileObj.Add('data', 'iVBORw0KGgo=');
        FileObj.Add('mimeType', 'image/png');
        FileObj.Add('fileName', 'test.png');
        FilesArray.Add(FileObj);
        PayloadObject.Add('files', FilesArray);

        // [WHEN] AttachFilesToMessages is called
        ProviderBase.AttachFilesToMessages(PayloadObject, Messages);

        // [THEN] The last message has a content array with text + image_url blocks
        Assert.AreEqual(1, Messages.Count(), 'Should still have 1 message.');
        Messages.Get(0, LastMsg);
        LastMsg.AsObject().Get('content', ContentToken);
        Assert.IsTrue(ContentToken.IsArray(), 'Content should be an array.');
        ContentArray := ContentToken.AsArray();
        Assert.AreEqual(2, ContentArray.Count(), 'Should have text + image blocks.');

        ContentArray.Get(0, FirstBlock);
        Assert.AreEqual('text', GetJsonText(FirstBlock.AsObject(), 'type'), 'First block should be text.');
        Assert.AreEqual('Describe this image', GetJsonText(FirstBlock.AsObject(), 'text'), 'Text should match prompt.');
    end;

    [Test]
    procedure AttachFiles_PdfUsesFileBlock()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        PayloadObject: JsonObject;
        Messages: JsonArray;
        UserMsg: JsonObject;
        FilesArray: JsonArray;
        FileObj: JsonObject;
        LastMsg: JsonToken;
        ContentToken: JsonToken;
        ContentArray: JsonArray;
        SecondBlock: JsonToken;
    begin
        // [GIVEN] A user message and a PDF file
        UserMsg.Add('role', 'user');
        UserMsg.Add('content', 'Extract data');
        Messages.Add(UserMsg);

        FileObj.Add('data', 'JVBERi0=');
        FileObj.Add('mimeType', 'application/pdf');
        FileObj.Add('fileName', 'invoice.pdf');
        FilesArray.Add(FileObj);
        PayloadObject.Add('files', FilesArray);

        // [WHEN]
        ProviderBase.AttachFilesToMessages(PayloadObject, Messages);

        // [THEN] The file block uses type=file (not image_url)
        Messages.Get(0, LastMsg);
        LastMsg.AsObject().Get('content', ContentToken);
        ContentArray := ContentToken.AsArray();
        ContentArray.Get(1, SecondBlock);
        Assert.AreEqual('file', GetJsonText(SecondBlock.AsObject(), 'type'), 'PDF should use file block type.');
    end;

    [Test]
    procedure AttachFiles_NoFiles_LeavesMessageUnchanged()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        PayloadObject: JsonObject;
        Messages: JsonArray;
        UserMsg: JsonObject;
        LastMsg: JsonToken;
        ContentToken: JsonToken;
    begin
        // [GIVEN] A user message with no files in payload
        UserMsg.Add('role', 'user');
        UserMsg.Add('content', 'Hello');
        Messages.Add(UserMsg);

        // [WHEN]
        ProviderBase.AttachFilesToMessages(PayloadObject, Messages);

        // [THEN] Message content remains a text string
        Messages.Get(0, LastMsg);
        LastMsg.AsObject().Get('content', ContentToken);
        Assert.IsTrue(ContentToken.IsValue(), 'Content should remain a text value when no files.');
        Assert.AreEqual('Hello', ContentToken.AsValue().AsText(), 'Text should be unchanged.');
    end;

    [Test]
    procedure AttachFiles_PreservesSystemMessage()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        PayloadObject: JsonObject;
        Messages: JsonArray;
        SystemMsg: JsonObject;
        UserMsg: JsonObject;
        FilesArray: JsonArray;
        FileObj: JsonObject;
        FirstMsg: JsonToken;
    begin
        // [GIVEN] A system message followed by a user message with a file
        SystemMsg.Add('role', 'system');
        SystemMsg.Add('content', 'You are a helper.');
        Messages.Add(SystemMsg);

        UserMsg.Add('role', 'user');
        UserMsg.Add('content', 'Process this');
        Messages.Add(UserMsg);

        FileObj.Add('data', 'abc=');
        FileObj.Add('mimeType', 'image/jpeg');
        FileObj.Add('fileName', 'photo.jpg');
        FilesArray.Add(FileObj);
        PayloadObject.Add('files', FilesArray);

        // [WHEN]
        ProviderBase.AttachFilesToMessages(PayloadObject, Messages);

        // [THEN] System message is preserved at index 0
        Assert.AreEqual(2, Messages.Count(), 'Should still have 2 messages.');
        Messages.Get(0, FirstMsg);
        Assert.AreEqual('system', GetJsonText(FirstMsg.AsObject(), 'role'), 'First message should be system.');
    end;

    [Test]
    procedure ExtractText_StandardResponse()
    var
        ApiClient: Codeunit "CE Chat API Client ori";
        Response: JsonObject;
    begin
        // [GIVEN] A standard OpenAI response
        Response.ReadFrom('{"choices":[{"message":{"content":"Hello world"},"finish_reason":"stop"}]}');

        // [WHEN/THEN]
        Assert.AreEqual('Hello world', ApiClient.ExtractText(Response), 'Should extract content from choices.');
    end;

    [Test]
    procedure ExtractText_EmptyChoices_ReturnsEmpty()
    var
        ApiClient: Codeunit "CE Chat API Client ori";
        Response: JsonObject;
    begin
        Response.ReadFrom('{"choices":[]}');
        Assert.AreEqual('', ApiClient.ExtractText(Response), 'Empty choices should return empty.');
    end;

    [Test]
    procedure ExtractText_NoChoices_ReturnsEmpty()
    var
        ApiClient: Codeunit "CE Chat API Client ori";
        Response: JsonObject;
    begin
        Response.ReadFrom('{"id":"test"}');
        Assert.AreEqual('', ApiClient.ExtractText(Response), 'Missing choices should return empty.');
    end;

    local procedure GetJsonText(JObject: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.Get(PropertyName, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsText());
    end;
}
