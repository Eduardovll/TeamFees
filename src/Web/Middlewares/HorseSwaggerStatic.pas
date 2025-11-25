unit HorseSwaggerStatic;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Horse, IdGlobal;

procedure UseSwaggerDocs(const ARoute, AFolder: string);

implementation

procedure UseSwaggerDocs(const ARoute, AFolder: string);
begin
  // Rota para abrir o index
  THorse.Get(ARoute,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      IndexPath: string;
    begin
      IndexPath := TPath.Combine(TPath.GetFullPath(AFolder), 'index.html');

      if not FileExists(IndexPath) then
      begin
        Res.Status(404).Send('index.html não encontrado em: ' + IndexPath);
        Exit;
      end;

      Res.ContentType('text/html');
      Res.SendFile(IndexPath);
    end
  );

  THorse.Get(ARoute + '/:file',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      FileName, FullPath, Ext, MimeType: string;
      BaseDir: string;
    begin
      BaseDir := TPath.GetFullPath(AFolder);
      FileName := Req.Params.Items['file'];
      FullPath := TPath.Combine(BaseDir, FileName);

      if not FileExists(FullPath) then
      begin
        Res.Status(404).Send('Arquivo não encontrado: ' + FullPath);
        Exit;
      end;

      Ext := LowerCase(ExtractFileExt(FullPath));

      if Ext = '.html' then MimeType := 'text/html'
      else if Ext = '.js' then MimeType := 'application/javascript'
      else if Ext = '.css' then MimeType := 'text/css'
      else if Ext = '.yaml' then MimeType := 'application/x-yaml'
      else if Ext = '.yml' then MimeType := 'application/x-yaml'
      else if Ext = '.json' then MimeType := 'application/json'
      else if Ext = '.png' then MimeType := 'image/png'
      else if Ext = '.jpg' then MimeType := 'image/jpeg'
      else if Ext = '.svg' then MimeType := 'image/svg+xml'
      else MimeType := 'application/octet-stream';

      Res.ContentType(MimeType);
      Res.SendFile(FullPath);
    end
  );
end;

end.

