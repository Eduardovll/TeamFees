unit MercadoPagoPixProvider;

interface

uses
  PixProviderIntf,
  System.SysUtils,
  System.Classes,
  System.Net.HttpClient,
  System.JSON;

type
  TMercadoPagoPixProvider = class(TInterfacedObject, IPixProvider)
  private
    FAccessToken: string;
  public
    constructor Create(const AccessToken: string);
    function CreateCharge(const UniqueKey: string; const AmountCents: Integer; const Description: string): TPixCharge;
    function GetPaymentDetails(const PaymentId: string; out ExternalReference: string; out AmountCents: Integer; out Status: string): Boolean;
  end;

implementation

constructor TMercadoPagoPixProvider.Create(const AccessToken: string);
begin
  FAccessToken := AccessToken;
end;

function TMercadoPagoPixProvider.CreateCharge(const UniqueKey: string; const AmountCents: Integer; const Description: string): TPixCharge;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  RequestBody, ResponseBody: TJSONObject;
  Amount: Double;
  Url: string;
begin
  Amount := AmountCents / 100.0;
  
  // Monta o JSON da requisição
  RequestBody := TJSONObject.Create;
  try
    RequestBody.AddPair('transaction_amount', TJSONNumber.Create(Amount));
    RequestBody.AddPair('description', Description);
    RequestBody.AddPair('payment_method_id', 'pix');
    RequestBody.AddPair('external_reference', UniqueKey);
    
    // Payer
    RequestBody.AddPair('payer', TJSONObject.Create
      .AddPair('email', 'test@test.com'));
    
    HttpClient := THTTPClient.Create;
    try
      HttpClient.ContentType := 'application/json';
      HttpClient.CustomHeaders['Authorization'] := 'Bearer ' + FAccessToken;
      HttpClient.CustomHeaders['X-Idempotency-Key'] := UniqueKey;
      
      Url := 'https://api.mercadopago.com/v1/payments';
      
      var RequestStream := TStringStream.Create(RequestBody.ToJSON, TEncoding.UTF8);
      try
        Response := HttpClient.Post(Url, RequestStream);
      finally
        RequestStream.Free;
      end;
      
      if (Response.StatusCode = 200) or (Response.StatusCode = 201) then
      begin
        ResponseBody := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
        try
          Result.ProviderId := ResponseBody.GetValue<string>('id');
          Result.TxId := UniqueKey;
          
          // QR Code está em point_of_interaction.transaction_data
          var PointOfInteraction: TJSONValue;
          if ResponseBody.TryGetValue('point_of_interaction', PointOfInteraction) and Assigned(PointOfInteraction) then
          begin
            var TransactionData := (PointOfInteraction as TJSONObject).GetValue<TJSONObject>('transaction_data');
            if Assigned(TransactionData) then
              Result.QrCode := TransactionData.GetValue<string>('qr_code')
            else
              Result.QrCode := '';
          end
          else
            Result.QrCode := '';
        finally
          ResponseBody.Free;
        end;
      end
      else
        raise Exception.CreateFmt('Erro ao criar cobrança PIX: %d - %s', 
          [Response.StatusCode, Response.ContentAsString]);
    finally
      HttpClient.Free;
    end;
  finally
    RequestBody.Free;
  end;
end;

function TMercadoPagoPixProvider.GetPaymentDetails(const PaymentId: string; out ExternalReference: string; out AmountCents: Integer; out Status: string): Boolean;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  ResponseBody: TJSONObject;
  Url: string;
  Amount: Double;
begin
  Result := False;
  HttpClient := THTTPClient.Create;
  try
    HttpClient.CustomHeaders['Authorization'] := 'Bearer ' + FAccessToken;
    
    Url := 'https://api.mercadopago.com/v1/payments/' + PaymentId;
    
    Response := HttpClient.Get(Url);
    
    if Response.StatusCode = 200 then
    begin
      ResponseBody := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      try
        ExternalReference := ResponseBody.GetValue<string>('external_reference', '');
        Amount := ResponseBody.GetValue<Double>('transaction_amount', 0);
        AmountCents := Round(Amount * 100);
        Status := ResponseBody.GetValue<string>('status', '');
        Result := True;
      finally
        ResponseBody.Free;
      end;
    end;
  finally
    HttpClient.Free;
  end;
end;

end.
