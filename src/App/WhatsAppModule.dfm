object WhatsAppDM: TWhatsAppDM
  Height = 150
  Width = 215
  object WPPConnect: TWPPConnect
    OnGetQrCode = WPPConnectGetQrCode
    OnConnected = WPPConnectConnected
    OnDisconnected = WPPConnectDisconnected
    Left = 80
    Top = 56
  end
end
