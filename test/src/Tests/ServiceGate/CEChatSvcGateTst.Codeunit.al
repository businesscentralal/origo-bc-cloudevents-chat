namespace Origo.APP.CloudEvents.Chat;

using System.TestLibraries.Utilities;

/// <summary>
/// Diagnostic tests for service gate permission verification.
/// </summary>
codeunit 95906 "CE Chat Svc Gate Tst ori"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    procedure ServiceGate_WritePermission_WithPermissionsDisabled()
    var
        ServiceGate: Record "CE Chat Service Gate ori";
    begin
        // With TestPermissions=Disabled, WritePermission always returns true
        Assert.IsTrue(ServiceGate.WritePermission(), 'WritePermission should be true when permissions are disabled');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    procedure ProviderBase_HasServiceKeyPermission_WithPermissionsDisabled()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
    begin
        Assert.IsTrue(ProviderBase.HasServiceKeyPermission(), 'HasServiceKeyPermission should be true when permissions are disabled');
    end;

    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure ServiceGate_WritePermission_WithRestrictivePermissions()
    var
        ServiceGate: Record "CE Chat Service Gate ori";
    begin
        // With Restrictive, this tests whether the test runner's effective permissions include the service gate.
        // If this fails, the CE Chat Svc permission set is not in the test runner's effective permissions.
        Assert.IsTrue(ServiceGate.WritePermission(),
            'WritePermission should be true. Assign CE Chat Svc (Chat Service Gate) permission set to the test user.');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    procedure ServiceGate_Table_IsAccessible()
    var
        ServiceGate: Record "CE Chat Service Gate ori";
    begin
        // Verifies the table is accessible and can be queried
        ServiceGate.SetRange("Primary Key", 'DIAG');
        Assert.IsFalse(ServiceGate.FindFirst(), 'Diagnostic key should not exist');
    end;
}
