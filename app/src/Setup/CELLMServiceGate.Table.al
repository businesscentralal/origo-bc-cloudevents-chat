namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// Permission gate table for LLM service key access.
/// No records are stored — used solely as a WritePermission() check target.
/// </summary>
table 10035495 "CE LLM Service Gate ori"
{
    Access = Internal;
    Caption = 'LLM Service Gate', Comment = 'is-IS=LLM þjónustuhlið';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key', Comment = 'is-IS=Aðallykill';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
