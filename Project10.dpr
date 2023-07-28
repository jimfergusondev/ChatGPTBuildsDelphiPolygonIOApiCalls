program Project10;
{$APPTYPE CONSOLE}

{$R *.res}
uses
  REST.Client,
  REST.Types,
  System.JSON,
  System.JSON.Serializers,
  SysUtils;

const APIKey = 'your-api-key';

type
  TTimeSpan = (tsMinute, tsHour, tsDay, tsWeek, tsMonth, tsQuarter, tsYear);

  TStockData = record
  public
    v: Double;    // volume
    vw: Double;   // volume weighted average price
    o: Double;    // open price
    c: Double;    // close price
    h: Double;    // high price
    l: Double;    // low price
    t: Int64;     // timestamp (milliseconds since Unix epoch)
    n: Integer;   // number of transactions
  end;
  TStockDataArray = TArray<TStockData>;

  TStockDataResponse = record
  public
    Ticker: string;
    QueryCount: Integer;
    ResultsCount: Integer;
    Adjusted: Boolean;
    Results: TStockDataArray;
    Status: string;
    RequestId: string;
    Count: Integer;
  end;

const
  TimeSpanStr: array[TTimeSpan] of string = ('minute', 'hour', 'day', 'week', 'month', 'quarter', 'year');

function GetStockData(const Symbol: string; Multiplier: Integer; Timespan: TTimeSpan; FromDate, ToDate: TDateTime; const APIKey: string): TStockDataResponse;
begin
  var RESTClient  := TRESTClient.Create('https://api.polygon.io');
  var RESTRequest := TRESTRequest.Create(nil);
  var RESTResponse := TRESTResponse.Create(nil);
  var Serializer := TJsonSerializer.Create;

  try
    RESTRequest.Client := RESTClient;
    RESTRequest.Response := RESTResponse;
    RESTRequest.Resource := 'v2/aggs/ticker/{symbol}/range/{multiplier}/{timespan}/{from}/{to}';
    RESTRequest.Method := TRESTRequestMethod.rmGET;

    // Set parameters
    RESTRequest.AddParameter('symbol', Symbol, TRESTRequestParameterKind.pkURLSEGMENT);
    RESTRequest.AddParameter('multiplier', IntToStr(Multiplier), TRESTRequestParameterKind.pkURLSEGMENT);
    RESTRequest.AddParameter('timespan', TimeSpanStr[Timespan], TRESTRequestParameterKind.pkURLSEGMENT);
    RESTRequest.AddParameter('from', FormatDateTime('yyyy-mm-dd', FromDate), TRESTRequestParameterKind.pkURLSEGMENT);
    RESTRequest.AddParameter('to', FormatDateTime('yyyy-mm-dd', ToDate), TRESTRequestParameterKind.pkURLSEGMENT);
    RESTRequest.AddParameter('apiKey', APIKey, TRESTRequestParameterKind.pkGETorPOST);

    RESTRequest.Execute;

    if RESTRequest.Response.StatusCode = 200 then
    begin
      // Use TJsonSerializer to convert JSON to object
      Result := Serializer.Deserialize<TStockDataResponse>(RESTResponse.Content);
    end
    else
      raise Exception.CreateFmt('Request failed with status code %d: %s', [RESTRequest.Response.StatusCode, RESTResponse.Content]);
  finally
    RESTResponse.Free;
    RESTRequest.Free;
    RESTClient.Free;
    Serializer.Free;
  end;
end;

type
  TStockSplit = record
    ticker: string;
    exDate: TDateTime;
    paymentDate: TDateTime;
    recordDate: TDateTime;
    declaredDate: TDateTime;
    ratio: Double;
    tofactor: Integer;
    forfactor: Integer;
  end;

  TStockSplitArray = TArray<TStockSplit>;

  TStockSplitResponse = record
    Status: string;
    Count: Integer;
    Results: TStockSplitArray;
  end;


function GetStockSplits(const Ticker: string; const APIKey: string): TStockSplitResponse;
begin
  var RESTClient := TRESTClient.Create('https://api.polygon.io');
  var RESTRequest := TRESTRequest.Create(nil);
  var RESTResponse := TRESTResponse.Create(nil);
  var Serializer := TJsonSerializer.Create;

  try
    RESTRequest.Client := RESTClient;
    RESTRequest.Response := RESTResponse;
    RESTRequest.Resource := 'v2/reference/splits/{ticker}';
    RESTRequest.Method := TRESTRequestMethod.rmGET;

    // Set parameters
    RESTRequest.AddParameter('ticker', Ticker, TRESTRequestParameterKind.pkURLSEGMENT);
    RESTRequest.AddParameter('apiKey', APIKey, TRESTRequestParameterKind.pkGETorPOST);

    RESTRequest.Execute;

    if RESTRequest.Response.StatusCode = 200 then
    begin
      // Use TJsonSerializer to convert JSON to object
      Result := Serializer.Deserialize<TStockSplitResponse>(RESTResponse.Content);
    end
    else
      raise Exception.CreateFmt('Request failed with status code %d: %s', [RESTRequest.Response.StatusCode, RESTResponse.Content]);
  finally
    RESTResponse.Free;
    RESTRequest.Free;
    RESTClient.Free;
    Serializer.Free;
  end;
end;
type
  [JSONName('results')]
  TStockTypeDetail = record
    [JsonName('type')]
    type_: string;
    path: string;
  end;

  [JSONName('results')]
  TStockTickerDetail = record
    ticker: string;
    name: string;
    market: string;
    locale: string;
    currency: string;
    active: Boolean;
    primaryExch: string;
    [JsonName('type')]
    type_: string;
    codes: TStockTypeDetail;
    updated: TDateTime;
    url: string;
  end;

  TStockTickerDetailResponse = record
    status: string;
    results: TStockTickerDetail;
  end;

function GetStockTickerDetails(const Ticker: string; const APIKey: string): TStockTickerDetailResponse;
begin
  var RESTClient := TRESTClient.Create('https://api.polygon.io');
  var RESTRequest := TRESTRequest.Create(nil);
  var RESTResponse := TRESTResponse.Create(nil);
  var Serializer := TJsonSerializer.Create;

  try
    RESTRequest.Client := RESTClient;
    RESTRequest.Response := RESTResponse;
    RESTRequest.Resource := 'v3/reference/tickers/{ticker}';
    RESTRequest.Method := TRESTRequestMethod.rmGET;

    // Set parameters
    RESTRequest.AddParameter('ticker', Ticker, TRESTRequestParameterKind.pkURLSEGMENT);
    RESTRequest.AddParameter('apiKey', APIKey, TRESTRequestParameterKind.pkGETorPOST);

    RESTRequest.Execute;

    if RESTRequest.Response.StatusCode = 200 then
    begin
      // Use TJsonSerializer to convert JSON to object
      Result := Serializer.Deserialize<TStockTickerDetailResponse>(RESTResponse.Content);
    end
    else
      raise Exception.CreateFmt('Request failed with status code %d: %s', [RESTRequest.Response.StatusCode, RESTResponse.Content]);
  finally
    RESTResponse.Free;
    RESTRequest.Free;
    RESTClient.Free;
    Serializer.Free;
  end;
end;


procedure Main;
begin
  var lResult :=  GetStockData('AAPL', 1, tsDay, EncodeDate(2023, 1, 3), EncodeDate(2023, 1, 10), APIKey);
  writeln(lResult.Ticker);
  var lResult1 := GetStockSplits('TSLA',APIKey);
  writeln(lResult1.Count);
  var lResult3 := GetStockTickerDetails('TSLA',APIKey);
  writeln(lResult3.status);
end;
begin
  Main;
end.

