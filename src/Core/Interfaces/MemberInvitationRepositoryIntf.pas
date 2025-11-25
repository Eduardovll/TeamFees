unit MemberInvitationRepositoryIntf;

interface

uses
  System.SysUtils;

type
  TMemberInvitation = class
  public
    Id: Integer;
    MemberId: Integer;
    Token: string;
    ExpiresAt: TDateTime;
    ActivatedAt: TDateTime;
    CreatedAt: TDateTime;
  end;

  IMemberInvitationRepository = interface
    ['{B7C8D9E0-2F3A-4B5C-9D0E-1F2A3B4C5D6E}']
    procedure Add(const Invitation: TMemberInvitation);
    function GetByToken(const Token: string): TMemberInvitation;
    procedure MarkAsActivated(const Token: string);
  end;

implementation

end.
