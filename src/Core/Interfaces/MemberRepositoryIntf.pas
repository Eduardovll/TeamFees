unit MemberRepositoryIntf;

interface

uses
  System.Generics.Collections,
  Member;

type
  IMemberRepository = interface
    ['{9F6C9B5F-5B09-4C26-BF2A-3E0F0674B1A0}']
    function GetActive: TObjectList<TMember>;
    function GetById(const Id: Integer): TMember;
    function FindByEmail(const Email: string): TMember;
    function FindByPhone(const Phone: string): TMember;
    function FindByCPF(const CPF: string): TMember;
    procedure Add(const M: TMember);
    procedure Update(const M: TMember);
  end;

implementation

end.
