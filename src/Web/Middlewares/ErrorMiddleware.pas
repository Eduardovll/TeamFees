unit ErrorMiddleware;

interface

uses
  Horse;

procedure UseErrorMiddleware;

implementation

uses
  System.SysUtils, System.JSON, Horse.Exception;

procedure UseErrorMiddleware;
begin
  THorse.Use(
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      StatusCode: Integer;
      ErrObj: TJSONObject;
    begin
      try
        Next;
      except
        on E: EHorseCallbackInterrupted do
        begin
          // Resposta já foi enviada pelo middleware anterior (ex: RoleGuard)
          // Apenas propaga a exceção para interromper a cadeia
          raise;
        end;
        on E: EHorseException do
        begin
          ErrObj := TJSONObject.Create
            .AddPair('error', E.Error)
            .AddPair('message', E.Error)
            .AddPair('path', Req.RawWebRequest.PathInfo);
          Res.Status(E.Status).Send(ErrObj);
          raise EHorseCallbackInterrupted.Create;
        end;
        on E: Exception do
        begin
          if E.Message.Contains('no encontrado') or E.Message.Contains('not found') then
            StatusCode := 404
          else if E.Message.Contains('inválido') or E.Message.Contains('diferente do valor') then
            StatusCode := 400
          else if E.Message.Contains('quitada') or E.Message.Contains('já foi paga') then
            StatusCode := 409
          else
            StatusCode := 500;

          ErrObj := TJSONObject.Create
            .AddPair('error', E.ClassName)
            .AddPair('message', E.Message)
            .AddPair('path', Req.RawWebRequest.PathInfo)
            .AddPair('status', TJSONNumber.Create(StatusCode));

          Res.Status(StatusCode).Send(ErrObj);
          raise EHorseCallbackInterrupted.Create;
        end;
      end;
    end);
end;

end.
