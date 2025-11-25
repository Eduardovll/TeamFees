unit Member;

interface

uses Enums;

type
  TMember = class
  private
    FId: Integer;
    FFullName: string;
    FPhoneWhatsApp: string;
    FEmail: string;
    FCPF: string;
    FIsActive: Boolean;
    FRole: TUserRole;
    FPasswordHash: string;
  public
    property Id: Integer read FId write FId;
    property FullName: string read FFullName write FFullName;
    property PhoneWhatsApp: string read FPhoneWhatsApp write FPhoneWhatsApp;
    property Email: string read FEmail write FEmail;
    property CPF: string read FCPF write FCPF;
    property IsActive: Boolean read FIsActive write FIsActive;
    property Role: TUserRole read FRole write FRole;
    property PasswordHash: string read FPasswordHash write FPasswordHash;
  end;

implementation

end.
