namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;
using System.Apps;
using System.Environment.Configuration;

/// <summary>
/// Shows an HTTP-client-disabled notification on the Cloud Events Setup page
/// when this extension has not been granted Allow HttpClient Requests.
/// </summary>
pageextension 10035509 "CE Chat Setup Ext ori" extends "Cloud Events Setup ori"
{
    trigger OnOpenPage()
    begin
        ShowHttpClientNotification();
    end;

    local procedure ShowHttpClientNotification()
    var
        NavAppSetting: Record "NAV App Setting";
        HttpNotification: Notification;
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if NavAppSetting.Get(AppInfo.Id()) then
            if NavAppSetting."Allow HttpClient Requests" then
                exit;

        HttpNotification.Id := 'e4a2c7d1-9f3b-4e8a-b5d6-1c7f2a8e3b09';
        HttpNotification.Scope := NotificationScope::LocalScope;
        HttpNotification.Message := HttpClientDisabledMsg;
        HttpNotification.AddAction(EnableHttpClientLbl, Codeunit::"CE Chat Http Notif. Action ori", 'OpenExtensionSettings');
        HttpNotification.Send();
    end;

    var
        HttpClientDisabledMsg: Label 'HTTP client requests are not enabled for the Cloud Events Chat extension. AI Chat providers will not work until an administrator enables Allow HttpClient Requests in Extension Settings.', Comment = 'is-IS=HTTP-biðlarabeiðnir eru ekki virkar fyrir Cloud Events Chat viðbótina. Gervigreindar spjallveitendur virka ekki fyrr en kerfisstjóri virkjar Leyfa HttpClient-beiðnir í stillingum viðbótar.';
        EnableHttpClientLbl: Label 'Open Extension Settings', Comment = 'is-IS=Opna stillingar viðbótar';
}
