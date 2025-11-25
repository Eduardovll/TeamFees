unit JsonHelper;

interface

uses
  System.JSON, Data.DB, System.SysUtils, System.DateUtils;

type
  /// <summary>
  ///  Classe utilitária para criação segura de TJSONValue a partir de campos de banco (TField)
  ///  Evita problemas com valores nulos e formata corretamente strings, números e datas.
  /// </summary>
  TJsonHelper = class
  public
    /// <summary>Converte campo string em TJSONValue, retornando null se o campo estiver nulo.</summary>
    class function SafeString(F: TField): TJSONValue; static;

    /// <summary>Converte campo numérico em TJSONValue, retornando null se o campo estiver nulo.</summary>
    class function SafeNumber(F: TField): TJSONValue; static;

    /// <summary>Converte campo data/hora em ISO8601 (ex: 2025-11-05T10:15:30Z), retornando null se nulo.</summary>
    class function SafeDate(F: TField): TJSONValue; static;

    /// <summary>
    /// Converte campo lógico (como 'S'/'N' ou '1'/'0') em TJSONBool,
    /// retornando null se o campo estiver nulo.
    /// </summary>
    class function SafeBool(F: TField; const TrueChar: string = 'S'): TJSONValue; static;
  end;

implementation

{ TJsonHelper }

class function TJsonHelper.SafeString(F: TField): TJSONValue;
begin
  if (F = nil) or F.IsNull then
    Result := TJSONNull.Create
  else
    Result := TJSONString.Create(F.AsString);
end;

class function TJsonHelper.SafeNumber(F: TField): TJSONValue;
begin
  if (F = nil) or F.IsNull then
    Result := TJSONNull.Create
  else
    Result := TJSONNumber.Create(F.AsFloat);
end;

class function TJsonHelper.SafeDate(F: TField): TJSONValue;
begin
  if (F = nil) or F.IsNull then
    Result := TJSONNull.Create
  else
    Result := TJSONString.Create(DateToISO8601(F.AsDateTime, False));
end;

class function TJsonHelper.SafeBool(F: TField; const TrueChar: string): TJSONValue;
begin
  if (F = nil) or F.IsNull then
    Result := TJSONNull.Create
  else
    Result := TJSONBool.Create(F.AsString = TrueChar);
end;

end.
